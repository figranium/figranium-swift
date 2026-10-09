import Foundation

/// An error returned by the Figranium server or SDK transport layer.
public struct FigraniumError: Error, Sendable, LocalizedError {
    /// The message value.
    public var message: String; public var status: Int; public var code: String?; public var details: JSONValue?; public var requestID: String?
    /// The error description value.
    public var errorDescription: String? { message }
    init(message: String, status: Int = 0, code: String? = nil, details: JSONValue? = nil, requestID: String? = nil) { self.message = message; self.status = status; self.code = code; self.details = details; self.requestID = requestID }
}

/// Authentication methods supported by the Figranium client.
public enum FigraniumAuthentication: Sendable { case apiKey(String, header: String = "authorization"), session, none }

/// Client for connecting to a self-hosted Figranium instance.
public final class Figranium: @unchecked Sendable {
    let baseURL: URL; let authentication: FigraniumAuthentication; let defaultHeaders: [String: String]; let timeout: TimeInterval; let session: URLSession
    /// The auth value.
    public lazy var tasks = TasksResource(client: self); public lazy var executions = ExecutionsResource(client: self)
    /// The schedules value.
    public lazy var schedules = SchedulesResource(client: self); public lazy var captures = CapturesResource(client: self); public lazy var cabinets = CabinetsResource(client: self)
    /// The credentials value.
    
    /// The execution value.
    public lazy var execution = ExecutionResource(client: self); public lazy var health = HealthResource(client: self)

    /// Creates a new Figranium.
    public init(baseURL: URL = URL(string: "http://localhost:11345")!, authentication: FigraniumAuthentication = .none, headers: [String: String] = [:], timeout: TimeInterval = 30, session: URLSession = .shared) {
        precondition(["http", "https"].contains(baseURL.scheme?.lowercased()), "baseURL must use http or https")
        self.baseURL = baseURL; self.authentication = authentication; self.defaultHeaders = headers; self.timeout = timeout; self.session = session
    }
    /// Creates a new Figranium.
    public convenience init(baseURL: String = "http://localhost:11345", apiKey: String? = nil, apiKeyHeader: String = "authorization", timeout: TimeInterval = 30) {
        guard let url = URL(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else { preconditionFailure("baseURL must be a valid URL") }
        self.init(baseURL: url, authentication: apiKey.map { .apiKey($0, header: apiKeyHeader) } ?? .none, timeout: timeout)
    }
    /// Executes a saved Figranium task and decodes its structured result.
    public func runTask<Value: Codable & Sendable>(_ id: String, input: ExecuteTaskOptions = .init(), options: RequestOptions = .init()) async throws -> ExecutionResult<Value> { try await tasks.run(id, input: input, options: options) }
    /// Performs the scrape operation.
    public func scrape<Value: Codable & Sendable>(_ input: JSONObject, options: RequestOptions = .init()) async throws -> ExecutionResult<Value> { try await execution.scrape(input, options: options) }
    /// Performs the agent operation.
    public func agent<Value: Codable & Sendable>(_ input: JSONObject, options: RequestOptions = .init()) async throws -> ExecutionResult<Value> { try await execution.agent(input, options: options) }
    /// Performs the headful operation.
    public func headful<Value: Codable & Sendable>(_ input: JSONObject, options: RequestOptions = .init()) async throws -> ExecutionResult<Value> { try await execution.headful(input, options: options) }

    func request<Value: Decodable & Sendable>(_ method: String, _ path: String, query: [String: String] = [:], options: RequestOptions = .init()) async throws -> Value {
        try await requestInternal(method, path, body: nil, query: query, options: options)
    }
    func request<Value: Decodable & Sendable, Body: Encodable>(_ method: String, _ path: String, body: Body, query: [String: String] = [:], options: RequestOptions = .init()) async throws -> Value {
        try await requestInternal(method, path, body: try JSONEncoder().encode(body), query: query, options: options)
    }
    private func requestInternal<Value: Decodable & Sendable>(_ method: String, _ path: String, body: Data?, query: [String: String], options: RequestOptions) async throws -> Value {
        var components = URLComponents(url: baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query.compactMap { $0.value.isEmpty ? nil : URLQueryItem(name: $0.key, value: $0.value) } }
        guard let url = components.url else { throw FigraniumError(message: "Unable to construct Figranium request URL") }
        var request = URLRequest(url: url); request.httpMethod = method; request.timeoutInterval = options.timeout ?? timeout
        var headers = defaultHeaders; headers["accept"] = "application/json"; options.headers.forEach { headers[$0.key] = $0.value }
        if case let .apiKey(key, header) = authentication { headers[header] = header.lowercased() == "authorization" ? "Bearer \(key)" : key }
        if let body { headers["content-type"] = headers["content-type"] ?? "application/json"; request.httpBody = body }
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw FigraniumError(message: "Figranium returned an invalid response", code: "NETWORK_ERROR") }
            guard 200..<300 ~= http.statusCode else { throw error(from: data, response: http) }
            if data.isEmpty || http.statusCode == 204 { throw FigraniumError(message: "Figranium returned an empty response", status: http.statusCode, code: "EMPTY_RESPONSE") }
            return try JSONDecoder().decode(Value.self, from: data)
        } catch let error as FigraniumError { throw error }
        catch is CancellationError { throw FigraniumError(message: "Figranium request was cancelled", code: "REQUEST_ABORTED") }
        catch { throw FigraniumError(message: "Unable to reach the Figranium server", code: "NETWORK_ERROR") }
    }
    func stream(_ path: String, options: RequestOptions = .init()) -> AsyncThrowingStream<StreamEvent<JSONValue>, Error> {
        AsyncThrowingStream { continuation in
            let task = Swift.Task { do {
                var request = URLRequest(url: baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))); request.timeoutInterval = options.timeout ?? 0; request.setValue("text/event-stream", forHTTPHeaderField: "accept")
                if case let .apiKey(key, header) = authentication { request.setValue(header.lowercased() == "authorization" ? "Bearer \(key)" : key, forHTTPHeaderField: header) }
                let (bytes, response) = try await session.bytes(for: request); guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw FigraniumError(message: "Unable to open Figranium stream", code: "NETWORK_ERROR") }
                var lines: [String] = []; for try await line in bytes.lines { if line.isEmpty { if let event = Self.sse(lines) { continuation.yield(event) }; lines = [] } else { lines.append(line) } }; if let event = Self.sse(lines) { continuation.yield(event) }; continuation.finish()
            } catch { continuation.finish(throwing: error) } }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    private static func sse(_ lines: [String]) -> StreamEvent<JSONValue>? { let data = lines.compactMap { $0.hasPrefix("data:") ? String($0.dropFirst(5)).trimmingCharacters(in: .whitespaces) : nil }.joined(separator: "\n"); guard !data.isEmpty else { return nil }; let value = (try? JSONDecoder().decode(JSONValue.self, from: Data(data.utf8))) ?? .string(data); return .init(data: value, event: lines.first(where: { $0.hasPrefix("event:") }).map { String($0.dropFirst(6)).trimmingCharacters(in: .whitespaces) }, id: lines.first(where: { $0.hasPrefix("id:") }).map { String($0.dropFirst(3)).trimmingCharacters(in: .whitespaces) }, retry: lines.first(where: { $0.hasPrefix("retry:") }).flatMap { Int($0.dropFirst(6).trimmingCharacters(in: .whitespaces)) }, raw: data) }
    private func error(from data: Data, response: HTTPURLResponse) -> FigraniumError { let object = try? JSONDecoder().decode(JSONObject.self, from: data); let message = object?["message"].flatMap { if case .string(let value) = $0 { value } else { nil } } ?? object?["error"].flatMap { if case .string(let value) = $0 { value } else { nil } } ?? String(data: data, encoding: .utf8) ?? "Figranium request failed"; let code = object?["error"].flatMap { if case .string(let value) = $0 { value } else { nil } }; return .init(message: message, status: response.statusCode, code: code, details: object?["details"] ?? object?["detail"], requestID: response.value(forHTTPHeaderField: "x-request-id")) }
}
func pathID(_ value: String) -> String { value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value }
