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
        if path == "/api/executions" || path == "/api/executions/list" {
            body = "{\\"executions\\":[{\\"id\\":\\"run-1\\",\\"timestamp\\":1,\\"status\\":200}]}"
        } else if path.hasSuffix("/result") {
            body = "{\\"result\\":{\\"rows\\":[1]}}"
        } else {
            body = "{\\"ok\\":true}"
        }
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite("Figranium SDK") struct FigraniumTests {
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

    @Test func executionStreamURLPreservesRunIDQuery() throws {
        let client = Figranium(baseURL: URL(string: "http://localhost:11345")!, authentication: .session)
        let url = try client.makeURL("/api/executions/stream", query: ["runId": "run/1? & x"])
        #expect(url.path == "/api/executions/stream")
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        #expect(query?.first(where: { $0.name == "runId" })?.value == "run/1? & x")
        #expect(url.absoluteString.contains("runId=run"))
        _ = client.executions.stream(runID: "run/1? & x")
    }

    @Test func jsonValueRoundTrip() throws {
        let original: JSONValue = .object(["items": .array([.number(1), .bool(true)])])
        #expect(try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(original)) == original)
    }
}
