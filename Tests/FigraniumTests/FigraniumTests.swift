import Testing
import Foundation
@testable import Figranium


private final class RecordingURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["content-type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        let path = request.url?.path ?? ""
        let body: String
        if path == "/api/tasks" {
            body = #"[{"id":"task-1","name":"Session task","description":"A task"}]"#
        } else if path == "/api/tasks/list" {
            body = #"{"tasks":[{"id":"task-2","name":"API task"}]}"#
        } else if path == "/api/executions" || path == "/api/executions/list" {
            body = #"{"executions":[{"id":"run-1","timestamp":1,"status":200}]}"#
        } else if path == "/api/cabinets" {
            body = #"{"defaultCabinetId":"cab_basic","cabinets":[{"id":"cab_basic","name":"Basic Cabinet","isDefault":true,"itemCount":2,"unuploadedCount":1,"createdAt":123}]}"#
        } else if path.hasSuffix("/unzip") {
            body = #"{"id":"item-2","name":"extracted","kind":"folder","status":"unuploaded","size":42,"createdAt":456}"#
        } else if path.hasSuffix("/result") {
            body = #"{"result":{"rows":[1]}}"#
        } else {
            body = #"{"ok":true}"#
        }
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite("Figranium SDK", .serialized) struct FigraniumTests {
    @Test func variableTemplateAndActionIDs() {
        #expect(variable("query") == "{$query}")
        let action = Actions.type("#search", value: variable("query"))
        #expect(action.type == "type")
        #expect(action.selector == "#search")
        #expect(action.id != nil)
    }

    @Test func taskEncodingUsesAPIFieldNames() throws {
        let task = Task(name: "Search", url: "https://example.com", mode: "agent", actions: [Actions.waitFor("#search")])
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(task)) as? [String: Any]
        #expect(json?["name"] as? String == "Search")
        #expect((json?["actions"] as? [[String: Any]])?.first?["type"] as? String == "wait_selector")
    }

    @Test func taskCookieStateAndBaserowOutputEncoding() throws {
        var task = Task(name: "Search", url: "https://example.com", mode: "agent")
        task.output = TaskOutput(credentialId: "credential-1", tableId: "table-1", databaseId: "database-1", dedicated: true)

        let inherited = try JSONSerialization.jsonObject(with: JSONEncoder().encode(task)) as? [String: Any]
        #expect(inherited?["cookieStateId"] == nil)
        #expect((inherited?["output"] as? [String: Any])?["databaseId"] as? String == "database-1")
        #expect((inherited?["output"] as? [String: Any])?["dedicated"] as? Bool == true)

        task.cookieStateId = .fresh
        let fresh = try JSONSerialization.jsonObject(with: JSONEncoder().encode(task)) as? [String: Any]
        #expect(fresh?["cookieStateId"] is NSNull)

        task.cookieStateId = .named("cookie-1")
        let named = try JSONSerialization.jsonObject(with: JSONEncoder().encode(task)) as? [String: Any]
        #expect(named?["cookieStateId"] as? String == "cookie-1")
        #expect(try JSONDecoder().decode(CookieStateSelection.self, from: Data("null".utf8)) == .fresh)
    }

    @Test func sessionCookieStatesPreserveEncodedIDsAndCSRFHint() async throws {
        #expect(pathID("state/1") == "state%2F1")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RecordingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        RecordingURLProtocol.requests = []

        let client = Figranium(
            baseURL: URL(string: "http://localhost:11345")!,
            authentication: .session,
            session: session
        )
        let state: JSONObject = ["cookies": .array([]), "origins": .array([])]
        let _: JSONObject = try await client.cookieStates.create(name: "login", state: state)
        let _: JSONObject = try await client.cookieStates.delete("state/1")

        #expect(RecordingURLProtocol.requests.count == 2)
        #expect(RecordingURLProtocol.requests[0].value(forHTTPHeaderField: "X-Requested-With") == "XMLHttpRequest")
        #expect(RecordingURLProtocol.requests[1].value(forHTTPHeaderField: "X-Requested-With") == "XMLHttpRequest")
        #expect(RecordingURLProtocol.requests[1].url?.absoluteString == "http://localhost:11345/api/cookie-states/state%2F1")
    }

    @Test func cabinetListAndUnzipDecodeCoreV021Responses() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RecordingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        RecordingURLProtocol.requests = []

        let client = Figranium(baseURL: URL(string: "http://localhost:11345")!, authentication: .session, session: session)
        let cabinets = try await client.cabinets.list()
        #expect(cabinets.count == 1)
        #expect(cabinets.first?.id == "cab_basic")
        #expect(cabinets.first?.unuploadedCount == 1)

        let extracted = try await client.cabinets.unzipItem("cab_basic", itemID: "item-1")
        #expect(extracted.id == "item-2")
        #expect(extracted.kind == "folder")
        #expect(extracted.size == 42)
        #expect(RecordingURLProtocol.requests.compactMap { $0.url?.path } == [
            "/api/cabinets", "/api/cabinets/cab_basic/items/item-1/unzip"
        ])
    }

    @Test func executionStreamURLPreservesRunIDQuery() throws {
        let client = Figranium(baseURL: URL(string: "http://localhost:11345")!, authentication: .session)
        let url = try client.makeURL("/api/executions/stream", query: ["runId": "run/1? & x"])
        #expect(url.path == "/api/executions/stream")
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        #expect(query?.first(where: { $0.name == "runId" })?.value == "run/1? & x")
        #expect(url.absoluteString.contains("runId=run"))
        _ = client.executions.stream(runID: "run/1? & x")
    }

    @Test func taskSummariesSelectSessionOrAPIKeyRoute() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RecordingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        RecordingURLProtocol.requests = []

        let url = URL(string: "http://localhost:11345")!
        let workspace = Figranium(baseURL: url, authentication: .session, session: session)
        let apiKey = Figranium(baseURL: url, authentication: .apiKey("secret"), session: session)
        let sessionTasks = try await workspace.tasks.listSummaries()
        let apiTasks = try await apiKey.tasks.listSummaries()

        #expect(sessionTasks.first?.id == "task-1")
        #expect(sessionTasks.first?.description == "A task")
        #expect(apiTasks.first?.name == "API task")
        #expect(RecordingURLProtocol.requests.compactMap { $0.url?.path } == ["/api/tasks", "/api/tasks/list"])
    }

    @Test func executionListAuthModeNumericStatusAndFullResult() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RecordingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        RecordingURLProtocol.requests = []

        let url = URL(string: "http://localhost:11345")!
        let workspace = Figranium(baseURL: url, authentication: .session, session: session)
        let apiKey = Figranium(baseURL: url, authentication: .apiKey("secret"), session: session)
        let sessionList = try await workspace.executions.list()
        let keyList = try await apiKey.executions.list()
        _ = try await workspace.executions.list(apiKeyRoute: true)
        let full = try await apiKey.executions.getFullResult("run/1")

        #expect(sessionList.first?.status == "200")
        #expect(keyList.first?.status == "200")
        #expect(full == .object(["rows": .array([.number(1)])]))
        let paths = RecordingURLProtocol.requests.compactMap { $0.url?.path }
        #expect(Array(paths.prefix(3)) == [
            "/api/executions", "/api/executions/list", "/api/executions/list"
        ])
        #expect(RecordingURLProtocol.requests.last?.url?.absoluteString.contains("run%2F1/result") == true)
    }

    @Test func jsonValueRoundTrip() throws {
        let original: JSONValue = .object(["items": .array([.number(1), .bool(true)])])
        #expect(try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(original)) == original)
    }
}
