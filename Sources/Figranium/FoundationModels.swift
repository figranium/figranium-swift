#if canImport(FoundationModels) && canImport(FoundationModelsMacros)
import FoundationModels
import Foundation

/// A constrained Foundation Models tool: the model can invoke one known Figranium task,
/// but cannot construct arbitrary browser actions or access credentials.
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
public struct RunFigraniumTaskTool: Tool {
    @Generable public struct Arguments {
        @Guide(description: "The identifier of the pre-approved Figranium task to run.") public var taskID: String
    }
    public let client: Figranium
    public let allowedTaskIDs: Set<String>
    public init(client: Figranium, allowedTaskIDs: Set<String>) { self.client = client; self.allowedTaskIDs = allowedTaskIDs }
    public var name: String { "run_figranium_task" }
    public var description: String { "Runs an approved deterministic Figranium browser automation task and returns its JSON result." }
    public var parameters: GenerationSchema { Arguments.generationSchema }
    public func call(arguments: Arguments) async throws -> String {
        guard allowedTaskIDs.contains(arguments.taskID) else { throw FigraniumError(message: "This task is not approved for model execution", code: "TASK_NOT_ALLOWED") }
        let result: ExecutionResult<JSONValue> = try await client.runTask(arguments.taskID)
        return String(data: try JSONEncoder().encode(result), encoding: .utf8) ?? "{}"
    }
}
#endif
