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
    /// Performs the configure operation.
    public static func configure(_ provider: any FigraniumIntentClientProvider) { lock.lock(); self.provider = provider; lock.unlock() }
    static func client() throws -> Figranium { lock.lock(); defer { lock.unlock() }; guard let provider else { throw FigraniumError(message: "Configure FigraniumIntentConfiguration before invoking Figranium intents", code: "INTENT_NOT_CONFIGURED") }; return try provider.client() }
}

/// Represents figranium task data used by the Figranium SDK.
public struct FigraniumTask: AppEntity, Identifiable, Sendable {
    /// The type display representation value.
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Figranium Task")
    /// The default query value.
    public static let defaultQuery = FigraniumTaskQuery()
    /// The id value.
    public var id: String
    /// The name value.
    public var name: String
    /// The display representation value.
    public var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
    /// Creates a new FigraniumTask.
    public init(id: String, name: String) { self.id = id; self.name = name }
}

/// Represents figranium task query data used by the Figranium SDK.
public struct FigraniumTaskQuery: EntityQuery {
    /// Creates a new FigraniumTaskQuery.
    public init() {}
    /// Performs the entities operation.
    public func entities(for identifiers: [String]) async throws -> [FigraniumTask] { let tasks = try await FigraniumIntentConfiguration.client().tasks.list(); return tasks.filter { identifiers.contains($0.id ?? "") }.compactMap { guard let id = $0.id else { return nil }; return FigraniumTask(id: id, name: $0.name) } }
    /// Performs the suggested entities operation.
    public func suggestedEntities() async throws -> [FigraniumTask] { try await FigraniumIntentConfiguration.client().tasks.listSummaries().map { FigraniumTask(id: $0.id, name: $0.name) } }
}

/// Represents run figranium task intent data used by the Figranium SDK.
public struct RunFigraniumTaskIntent: AppIntent {
    /// The title value.
    public static let title: LocalizedStringResource = "Run Figranium Task"
    @Parameter(title: "Task") public var task: FigraniumTask
    /// Creates a new RunFigraniumTaskIntent.
    public init() { task = FigraniumTask(id: "", name: "") }
    /// Creates a new RunFigraniumTaskIntent.
    public init(task: FigraniumTask) { self.task = task }
    /// Performs the App Intent using the configured Figranium client.
    public func perform() async throws -> some IntentResult & ProvidesDialog { let result: ExecutionResult<JSONValue> = try await FigraniumIntentConfiguration.client().runTask(task.id); return .result(dialog: "\(task.name) finished with \(result.outcome ?? "an unknown outcome").") }
}

/// Represents stop figranium execution intent data used by the Figranium SDK.
public struct StopFigraniumExecutionIntent: AppIntent {
    /// The title value.
    public static let title: LocalizedStringResource = "Stop Figranium Execution"
    @Parameter(title: "Run ID") public var runID: String
    /// Creates a new StopFigraniumExecutionIntent.
    public init() { runID = "" }; public init(runID: String) { self.runID = runID }
    /// Performs the App Intent using the configured Figranium client.
    public func perform() async throws -> some IntentResult & ProvidesDialog { _ = try await FigraniumIntentConfiguration.client().executions.stop(runID: runID); return .result(dialog: "Stopped Figranium execution.") }
}

/// Represents get figranium execution status intent data used by the Figranium SDK.
public struct GetFigraniumExecutionStatusIntent: AppIntent {
    /// The title value.
    public static let title: LocalizedStringResource = "Get Figranium Execution Status"
    @Parameter(title: "Execution ID") public var executionID: String
    /// Creates a new GetFigraniumExecutionStatusIntent.
    public init() { executionID = "" }; public init(executionID: String) { self.executionID = executionID }
    /// Performs the App Intent using the configured Figranium client.
    public func perform() async throws -> some IntentResult & ProvidesDialog { let execution = try await FigraniumIntentConfiguration.client().executions.get(executionID); return .result(dialog: "Execution status: \(execution.status ?? execution.outcome ?? "unknown").") }
}
#endif
