import Foundation
import Testing
@testable import Figranium

@Suite("authenticated redirect safety", .serialized)
struct RedirectSecurityTests {
    @Test func rejectsRedirectsAndPreservesInjectedSessionConfiguration() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = ["X-Test-Header": "preserved"]
        let injectedSession = URLSession(configuration: configuration)
        defer { injectedSession.invalidateAndCancel() }

        let client = Figranium(baseURL: URL(string: "https://api.example")!,
                               authentication: .apiKey("test-secret", header: "x-api-key"),
                               session: injectedSession)
        let delegate = try #require(client.session.delegate as? RejectRedirectsDelegate)
        #expect(client.session.configuration.httpAdditionalHeaders?["X-Test-Header"] as? String == "preserved")

        let request = URLRequest(url: URL(string: "https://api.example/api/health")!)
        let task = client.session.dataTask(with: request)
        defer { task.cancel() }
        let redirect = URLRequest(url: URL(string: "https://attacker.example/stolen")!)
        let response = HTTPURLResponse(url: request.url!, statusCode: 302, httpVersion: nil,
                                       headerFields: ["Location": redirect.url!.absoluteString])!
        var rejected = false
        delegate.urlSession(client.session, task: task, willPerformHTTPRedirection: response,
                            newRequest: redirect) { forwarded in
            rejected = forwarded == nil
        }
        #expect(rejected)
    }
}
