#if canImport(AppIntents)
import AppIntents
import Foundation

/// Supplies an app-owned client to system integrations. Keep secrets in your app's secure storage.
public protocol FigraniumIntentClientProvider: Sendable {
    func client() throws -> Figranium
}

/// The app sets this once at launch before presenting Figranium intents to the system.
public enum FigraniumIntentConfiguration {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var provider: (any FigraniumIntentClientProvider)?
    public static func configure(_ provider: any FigraniumIntentClientProvider) { lock.lock(); self.provider = provider; lock.unlock() }
    static func client() throws -> Figranium { lock.lock(); defer { lock.unlock() }; guard let provider else { throw FigraniumError(message: "Configure FigraniumIntentConfiguration before invoking Figranium intents", code: "INTENT_NOT_CONFIGURED") }; return try provider.client() }
}

public struct FigraniumTask: AppEntity, Identifiable, Sendable {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Figranium Task")
    public static let defaultQuery = FigraniumTaskQuery()
    public var id: String
    public var name: String
    public var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
    public init(id: String, name: String) { self.id = id; self.name = name }
}

public struct FigraniumTaskQuery: EntityQuery {
    public init() {}
    public func entities(for identifiers: [String]) async throws -> [FigraniumTask] { let tasks = try await FigraniumIntentConfiguration.client().tasks.list(); return tasks.filter { identifiers.contains($0.id ?? "") }.compactMap { guard let id = $0.id else { return nil }; return FigraniumTask(id: id, name: $0.name) } }
    public func suggestedEntities() async throws -> [FigraniumTask] { try await FigraniumIntentConfiguration.client().tasks.listSummaries().map { FigraniumTask(id: $0.id, name: $0.name) } }
}

public struct RunFigraniumTaskIntent: AppIntent {
    public static let title: LocalizedStringResource = "Run Figranium Task"
    @Parameter(title: "Task") public var task: FigraniumTask
    public init() { task = FigraniumTask(id: "", name: "") }
    public init(task: FigraniumTask) { self.task = task }
    public func perform() async throws -> some IntentResult & ProvidesDialog { let result: ExecutionResult<JSONValue> = try await FigraniumIntentConfiguration.client().runTask(task.id); return .result(dialog: "\(task.name) finished with \(result.outcome ?? "an unknown outcome").") }
}

public struct StopFigraniumExecutionIntent: AppIntent {
    public static let title: LocalizedStringResource = "Stop Figranium Execution"
    @Parameter(title: "Run ID") public var runID: String
    public init() { runID = "" }; public init(runID: String) { self.runID = runID }
    public func perform() async throws -> some IntentResult & ProvidesDialog { _ = try await FigraniumIntentConfiguration.client().executions.stop(runID: runID); return .result(dialog: "Stopped Figranium execution.") }
}

public struct GetFigraniumExecutionStatusIntent: AppIntent {
    public static let title: LocalizedStringResource = "Get Figranium Execution Status"
    @Parameter(title: "Execution ID") public var executionID: String
    public init() { executionID = "" }; public init(executionID: String) { self.executionID = executionID }
    public func perform() async throws -> some IntentResult & ProvidesDialog { let execution = try await FigraniumIntentConfiguration.client().executions.get(executionID); return .result(dialog: "Execution status: \(execution.status ?? execution.outcome ?? "unknown").") }
}
#endif
