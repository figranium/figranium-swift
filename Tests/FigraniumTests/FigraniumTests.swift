import Testing
import Foundation
@testable import Figranium

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

    @Test func jsonValueRoundTrip() throws {
        let original: JSONValue = .object(["items": .array([.number(1), .bool(true)])])
        #expect(try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(original)) == original)
    }
}
