import Foundation

/// API resource for auth operations.

/// Session-only named browser storage states introduced in Figranium v0.21.
public struct CookieStatesResource: Sendable {
    let client: Figranium

    public func list(options: RequestOptions = .init()) async throws -> JSONObject {
        try await client.request("GET", "/api/cookie-states", options: options)
    }

    public func get(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject {
        try await client.request("GET", "/api/cookie-states/\(pathID(id))", options: options)
    }

    public func create(name: String, state: JSONObject, options: RequestOptions = .init()) async throws -> JSONObject {
        let input: JSONObject = ["name": .string(name), "state": .object(state)]
        return try await client.request("POST", "/api/cookie-states", body: input, options: options)
    }

    public func rename(_ id: String, name: String, options: RequestOptions = .init()) async throws -> JSONObject {
        let input: JSONObject = ["name": .string(name)]
        return try await client.request("PATCH", "/api/cookie-states/\(pathID(id))", body: input, options: options)
    }

    public func update(_ id: String, state: JSONObject, options: RequestOptions = .init()) async throws -> JSONObject {
        let input: JSONObject = ["state": .object(state)]
        return try await client.request("PATCH", "/api/cookie-states/\(pathID(id))", body: input, options: options)
    }

    public func delete(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject {
        try await client.request("DELETE", "/api/cookie-states/\(pathID(id))", options: options)
    }
}

public struct TasksResource: Sendable { let client: Figranium
    /// Performs the list operation.
    public func list(options: RequestOptions = .init()) async throws -> [Task] { try await client.request("GET", "/api/tasks", options: options) }
    /// Lists Task summaries through the endpoint supported by the authentication mode.
    public func listSummaries(options: RequestOptions = .init()) async throws -> [TaskSummary] {
        if case .session = client.authentication {
            return try await client.request("GET", "/api/tasks", options: options)
        }
        struct Response: Codable, Sendable { let tasks: [TaskSummary] }
        let response: Response = try await client.request("GET", "/api/tasks/list", options: options)
        return response.tasks
    }
    /// Performs the save operation.
    public func save(_ task: Task, createVersion: Bool = false, options: RequestOptions = .init()) async throws -> Task { try await client.request("POST", "/api/tasks", body: task, query: ["version": createVersion ? "true" : ""], options: options) }
    /// Performs the touch operation.
    public func touch(_ id: String, options: RequestOptions = .init()) async throws -> Task { try await client.request("POST", "/api/tasks/\(pathID(id))/touch", options: options) }
    /// Performs the update operation.
    public func update(_ id: String, patch: JSONObject, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("PATCH", "/api/tasks/\(pathID(id))", body: patch, options: options) }
    /// Performs the delete operation.
    public func delete(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/tasks/\(pathID(id))", options: options) }
    /// Performs the versions operation.
    public func versions(_ id: String, options: RequestOptions = .init()) async throws -> [TaskVersion] { struct Response: Codable, Sendable { let versions: [TaskVersion] }; let response: Response = try await client.request("GET", "/api/tasks/\(pathID(id))/versions", options: options); return response.versions }
    /// Performs the version operation.
    public func version(_ id: String, versionID: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/tasks/\(pathID(id))/versions/\(pathID(versionID))", options: options) }
    /// Deletes a saved Task version. Requires a workspace session.
    public func deleteVersion(_ id: String, versionID: String, options: RequestOptions = .init()) async throws -> JSONObject {
        try await client.request("DELETE", "/api/tasks/\(pathID(id))/versions/\(pathID(versionID))", options: options)
    }
    /// Performs the clear versions operation.
    public func clearVersions(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/tasks/\(pathID(id))/versions/clear", options: options) }
    /// Performs the rollback operation.
    public func rollback(_ id: String, versionID: String, options: RequestOptions = .init()) async throws -> Task { try await client.request("POST", "/api/tasks/\(pathID(id))/rollback", body: ["versionId": versionID], options: options) }
    /// Executes a saved Figranium task and decodes its structured result.
    public func run<Value: Codable & Sendable>(_ id: String, input: ExecuteTaskOptions = .init(), options: RequestOptions = .init()) async throws -> ExecutionResult<Value> { try await client.request("POST", "/tasks/\(pathID(id))/api", body: input, options: options) }
}
/// API resource for executions operations.
public struct ExecutionsResource: Sendable { let client: Figranium
    /// Performs the list operation.
    public func list(apiKeyRoute: Bool? = nil, options: RequestOptions = .init()) async throws -> [Execution] {
        struct Response: Codable, Sendable { let executions: [Execution] }
        let useAPIKeyRoute: Bool
        if let apiKeyRoute { useAPIKeyRoute = apiKeyRoute }
        else if case .session = client.authentication { useAPIKeyRoute = false }
        else { useAPIKeyRoute = true }
        let response: Response = try await client.request("GET", useAPIKeyRoute ? "/api/executions/list" : "/api/executions", options: options)
        return response.executions
    }
    /// Performs the get operation.
    public func get(_ id: String, options: RequestOptions = .init()) async throws -> Execution { struct Response: Codable, Sendable { let execution: Execution }; let response: Response = try await client.request("GET", "/api/executions/\(pathID(id))", options: options); return response.execution }
    /// Fetches a retained complete result. API keys require results:read and access to the Task.
    public func getFullResult(_ id: String, options: RequestOptions = .init()) async throws -> JSONValue {
        let response: JSONObject = try await client.request("GET", "/api/executions/\(pathID(id))/result", options: options)
        return response["result"] ?? .null
    }
    /// Performs the delete operation.
    public func delete(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/executions/\(pathID(id))", options: options) }
    /// Performs the clear operation.
    public func clear(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/executions/clear", options: options) }
    /// Performs the stop operation.
    public func stop(runID: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/executions/stop", body: ["runId": runID], options: options) }
    /// Streams events for a run. Requires a workspace session (not an API key).
    public func stream(runID: String, options: RequestOptions = .init()) -> AsyncThrowingStream<StreamEvent<JSONValue>, Error> { client.stream("/api/executions/stream", query: ["runId": runID], options: options) }
    /// Polls an execution and emits updates until it reaches a terminal outcome.
    public func watch(_ executionID: String, interval: Duration = .seconds(1), options: RequestOptions = .init()) -> AsyncThrowingStream<Execution, Error> { AsyncThrowingStream { continuation in let task = Swift.Task { do { var lastStatus: String?; while !Swift.Task.isCancelled { let value = try await get(executionID, options: options); if value.status != lastStatus { continuation.yield(value); lastStatus = value.status }; if ["success", "error", "stopped", "crashed", "anti_bot"].contains(value.outcome ?? value.status ?? "") { continuation.finish(); return }; try await Swift.Task.sleep(for: interval) } } catch { continuation.finish(throwing: error) } }; continuation.onTermination = { _ in task.cancel() } } }
}
/// API resource for schedules operations.
public struct SchedulesResource: Sendable { let client: Figranium
    /// Performs the list operation.
    public func list(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/schedules", options: options) }
    /// Performs the set operation.
    public func set(_ taskID: String, schedule: Schedule, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/schedules/\(pathID(taskID))", body: schedule, options: options) }
    /// Performs the delete operation.
    public func delete(_ taskID: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/schedules/\(pathID(taskID))", options: options) }
    /// Performs the status operation.
    public func status(_ taskID: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/schedules/\(pathID(taskID))/status", options: options) }
    /// Performs the describe operation.
    public func describe(_ taskID: String, schedule: Schedule, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/schedules/\(pathID(taskID))/describe", body: schedule, options: options) }
    /// Performs the overall status operation.
    public func overallStatus(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/schedules/status/all", options: options) }
}
/// API resource for captures operations.
public struct CapturesResource: Sendable { let client: Figranium
    /// Performs the list operation.
    public func list(runID: String? = nil, options: RequestOptions = .init()) async throws -> [Capture] { struct Response: Codable, Sendable { let captures: [Capture] }; let response: Response = try await client.request("GET", "/api/data/captures", query: ["runId": runID ?? ""], options: options); return response.captures }
    /// Performs the screenshots operation.
    public func screenshots(options: RequestOptions = .init()) async throws -> [Capture] { struct Response: Codable, Sendable { let screenshots: [Capture] }; let response: Response = try await client.request("GET", "/api/data/screenshots", options: options); return response.screenshots }
    /// Performs the delete operation.
    public func delete(_ name: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/data/captures/\(pathID(name))", options: options) }
    /// Performs the cookies operation.
    /// Performs the delete cookie operation.
    /// Performs the clear operation.
    public func clear(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/data/clear-screenshots", options: options) }
    /// Performs the clear cookies operation.
}
/// API resource for cabinets operations.
public struct CabinetsResource: Sendable { let client: Figranium
    /// Performs the list operation.
    public func list(options: RequestOptions = .init()) async throws -> [Cabinet] { struct Response: Codable, Sendable { let defaultCabinetId: String; let cabinets: [Cabinet] }; let response: Response = try await client.request("GET", "/api/cabinets", options: options); return response.cabinets }
    /// Performs the create operation.
    public func create(_ name: String, options: RequestOptions = .init()) async throws -> Cabinet { try await client.request("POST", "/api/cabinets", body: ["name": name], options: options) }
    /// Performs the rename operation.
    public func rename(_ id: String, name: String, options: RequestOptions = .init()) async throws -> Cabinet { try await client.request("PATCH", "/api/cabinets/\(pathID(id))", body: ["name": name], options: options) }
    /// Performs the delete operation.
    public func delete(_ id: String, targetCabinetID: String? = nil, migrate: Bool = false, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/cabinets/\(pathID(id))", body: ["targetCabinetId": targetCabinetID, "mode": migrate ? "migrate" : nil], options: options) }
    /// Performs the list items operation.
    public func listItems(_ id: String, options: RequestOptions = .init()) async throws -> [CabinetItem] { struct Response: Codable, Sendable { let items: [CabinetItem] }; let response: Response = try await client.request("GET", "/api/cabinets/\(pathID(id))/items", options: options); return response.items }
    /// Performs the clear operation.
    public func clear(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/cabinets/\(pathID(id))/clear", options: options) }
    /// Performs the set item status operation.
    public func setItemStatus(_ cabinetID: String, itemIDs: [String], status: String, options: RequestOptions = .init()) async throws -> [CabinetItem] { struct Response: Codable, Sendable { let items: [CabinetItem] }; struct Input: Codable { let itemIds: [String]; let status: String }; let response: Response = try await client.request("PATCH", "/api/cabinets/\(pathID(cabinetID))/items/status", body: Input(itemIds: itemIDs, status: status), options: options); return response.items }
    /// Performs the remove items operation.
    public func removeItems(_ cabinetID: String, itemIDs: [String], options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/cabinets/\(pathID(cabinetID))/items", body: ["itemIds": itemIDs], options: options) }
    /// Performs the zip items operation.
    public func zipItems(_ cabinetID: String, itemIDs: [String], name: String? = nil, options: RequestOptions = .init()) async throws -> CabinetItem { struct Input: Codable { let itemIds: [String]; let name: String? }; return try await client.request("POST", "/api/cabinets/\(pathID(cabinetID))/zip", body: Input(itemIds: itemIDs, name: name), options: options) }
    /// Performs the unzip item operation.
    public func unzipItem(_ cabinetID: String, itemID: String, options: RequestOptions = .init()) async throws -> CabinetItem { try await client.request("POST", "/api/cabinets/\(pathID(cabinetID))/items/\(pathID(itemID))/unzip", options: options) }
    /// Performs the download url operation.
    public func downloadURL(cabinetID: String, itemID: String) -> URL { client.baseURL.appendingPathComponent("api/cabinets/\(pathID(cabinetID))/items/\(pathID(itemID))/download") }
}
/// API resource for credentials operations.



public struct ExecutionResource: Sendable { let client: Figranium
    /// Performs the scrape operation.
    public func scrape<Value: Codable & Sendable>(_ input: JSONObject, options: RequestOptions = .init()) async throws -> ExecutionResult<Value> { try await client.request("POST", "/scrape", body: input, options: options) }
    /// Performs the agent operation.
    public func agent<Value: Codable & Sendable>(_ input: JSONObject, options: RequestOptions = .init()) async throws -> ExecutionResult<Value> { try await client.request("POST", "/agent", body: input, options: options) }
    /// Performs the headful operation.
    public func headful<Value: Codable & Sendable>(_ input: JSONObject, options: RequestOptions = .init()) async throws -> ExecutionResult<Value> { try await client.request("POST", "/headful", body: input, options: options) }
}
/// API resource for health operations.
public struct HealthResource: Sendable { let client: Figranium; public func check(options: RequestOptions = .init()) async throws -> HealthStatus { try await client.request("GET", "/api/health", options: options) } }
