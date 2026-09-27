import Testing
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

    @Test func jsonValueRoundTrip() throws {
        let original: JSONValue = .object(["items": .array([.number(1), .bool(true)])])
        #expect(try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(original)) == original)
    }
}
