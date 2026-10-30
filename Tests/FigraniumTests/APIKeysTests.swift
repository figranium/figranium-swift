import Foundation
import Testing
@testable import Figranium

private final class APIKeyURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requests.append(request)
        let body: String
        switch request.httpMethod {
        case "GET":
            body = #"{\"keys\":[],\"legacySecret\":null,\"permissions\":[\"tasks:read\",\"tasks:run\",\"tasks:manage\"]}"#
        case "POST":
            body = #"{\"key\":{\"id\":\"key/1\",\"name\":\"Runner\",\"permissions\":[\"tasks:run\"],\"taskIds\":[\"task-1\"],\"createdAt\":\"2026-10-30T00:00:00Z\"},\"secret\":\"once\"}"#
        case "PATCH":
            body = #"{\"key\":{\"id\":\"key/1\",\"name\":\"Production\",\"permissions\":[\"tasks:run\"],\"taskIds\":[\"task-1\"],\"createdAt\":\"2026-10-30T00:00:00Z\"}}"#
        default:
            body = #"{\"ok\":true}"#
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["content-type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@Suite("v0.21 scoped API keys", .serialized)
struct APIKeysTests {
    @Test func sessionAdministrationAndTaskAllowlist() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [APIKeyURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        APIKeyURLProtocol.requests = []

        let url = URL(string: "http://localhost:11345")!
        let workspace = Figranium(baseURL: url, authentication: .session, session: session)
        let keys = try await workspace.apiKeys.list()
        #expect(keys.keys.isEmpty)
        #expect(keys.permissions == ApiKeyPermission.allCases)

        let input = ApiKeyCreateInput(permissions: [.tasksRun], name: "Runner", taskIds: ["task-1"])
        let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(input)) as? [String: Any]
        #expect(encoded?["taskIds"] as? [String] == ["task-1"])
        #expect(encoded?["permissions"] as? [String] == ["tasks:run"])
        let created = try await workspace.apiKeys.create(input)
        #expect(created.secret == "once")
        #expect(created.key.taskIds == ["task-1"])
        #expect(try await workspace.apiKeys.rename("key/1", name: "Production").key.name == "Production")
        #expect(try await workspace.apiKeys.revoke("key/1").ok)

        #expect(APIKeyURLProtocol.requests.map { $0.httpMethod ?? "" } == ["GET", "POST", "PATCH", "DELETE"])
        #expect(APIKeyURLProtocol.requests.compactMap { $0.url?.absoluteString } == [
            "http://localhost:11345/api/api-keys",
            "http://localhost:11345/api/api-keys",
            "http://localhost:11345/api/api-keys/key%2F1",
            "http://localhost:11345/api/api-keys/key%2F1"
        ])
        #expect(APIKeyURLProtocol.requests.dropFirst().allSatisfy {
            $0.value(forHTTPHeaderField: "X-Requested-With") == "XMLHttpRequest"
        })

        let scoped = Figranium(baseURL: url, authentication: .apiKey("scoped"), session: session)
        let anonymous = Figranium(baseURL: url, authentication: .none, session: session)
        var rejected = 0
        do { _ = try await scoped.apiKeys.list() }
        catch let error as FigraniumError { if error.code == "SESSION_REQUIRED" { rejected += 1 } }
        do { _ = try await scoped.apiKeys.create(input) }
        catch let error as FigraniumError { if error.code == "SESSION_REQUIRED" { rejected += 1 } }
        do { _ = try await scoped.apiKeys.rename("key", name: "Blocked") }
        catch let error as FigraniumError { if error.code == "SESSION_REQUIRED" { rejected += 1 } }
        do { _ = try await scoped.apiKeys.revoke("key") }
        catch let error as FigraniumError { if error.code == "SESSION_REQUIRED" { rejected += 1 } }
        do { _ = try await anonymous.apiKeys.list() }
        catch let error as FigraniumError { if error.code == "SESSION_REQUIRED" { rejected += 1 } }
        #expect(rejected == 5)
        #expect(APIKeyURLProtocol.requests.count == 4)
    }
}
