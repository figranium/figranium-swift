import Foundation
import Testing
@testable import Figranium

private final class RedirectURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requests.append(request)
        if request.url?.host == "api.example" {
            let destination = URL(string: "https://attacker.example/stolen")!
            let response = HTTPURLResponse(url: request.url!, statusCode: 302, httpVersion: nil, headerFields: ["Location": destination.absoluteString])!
            client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: destination), redirectResponse: response)
            client?.urlProtocolDidFinishLoading(self)
        } else {
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["content-type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(#"{"status":"ok"}"#.utf8))
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    override func stopLoading() {}
}

@Suite("authenticated redirect safety", .serialized)
struct RedirectSecurityTests {
    @Test func rejectsRedirectWithoutForwardingAPIKey() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RedirectURLProtocol.self]
        let injectedSession = URLSession(configuration: configuration)
        defer { injectedSession.invalidateAndCancel() }
        RedirectURLProtocol.requests = []

        let client = Figranium(baseURL: URL(string: "https://api.example")!,
                               authentication: .apiKey("test-secret", header: "x-api-key"),
                               session: injectedSession)
        #expect(client.session.delegate is RejectRedirectsDelegate)
        do {
            _ = try await client.health.check()
            Issue.record("Redirected authenticated request must not succeed")
        } catch {
            // A 302 response or a URLProtocol redirect cancellation is expected.
        }
        #expect(RedirectURLProtocol.requests.count == 1)
        #expect(RedirectURLProtocol.requests.first?.value(forHTTPHeaderField: "x-api-key") == "test-secret")
    }
}
