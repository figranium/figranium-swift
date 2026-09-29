import Foundation

/// API resource for auth operations.
public struct AuthResource: Sendable { let client: Figranium
    /// Performs the check setup operation.
    public func checkSetup(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/auth/check-setup", options: options) }
    /// Performs the setup operation.
    public func setup(name: String, email: String, password: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/auth/setup", body: ["name": name, "email": email, "password": password], options: options) }
    /// Performs the login operation.
    public func login(email: String, password: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/auth/login", body: ["email": email, "password": password], options: options) }
    /// Performs the logout operation.
    public func logout(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/auth/logout", options: options) }
    /// Performs the me operation.
    public func me(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/auth/me", options: options) }
}
/// API resource for tasks operations.
public struct TasksResource: Sendable { let client: Figranium
    /// Performs the list operation.
    public func list(options: RequestOptions = .init()) async throws -> [Task] { try await client.request("GET", "/api/tasks", options: options) }
    /// Performs the list summaries operation.
    public func listSummaries(options: RequestOptions = .init()) async throws -> [TaskSummary] { struct Response: Codable, Sendable { let tasks: [TaskSummary] }; let response: Response = try await client.request("GET", "/api/tasks/list", options: options); return response.tasks }
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
    /// Performs the clear versions operation.
    public func clearVersions(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/tasks/\(pathID(id))/versions/clear", options: options) }
    /// Performs the rollback operation.
    public func rollback(_ id: String, versionID: String, options: RequestOptions = .init()) async throws -> Task { try await client.request("POST", "/api/tasks/\(pathID(id))/rollback", body: ["versionId": versionID], options: options) }
    /// Performs the generate selector operation.
    public func generateSelector(task: Task, actionIndex: Int, prompt: String, options: RequestOptions = .init()) async throws -> String { struct Response: Codable, Sendable { let selector: String }; struct Input: Codable { let task: Task; let actionIndex: Int; let prompt: String }; let response: Response = try await client.request("POST", "/api/tasks/generate-selector", body: Input(task: task, actionIndex: actionIndex, prompt: prompt), options: options); return response.selector }
    /// Performs the generate script operation.
    public func generateScript(_ description: String, options: RequestOptions = .init()) async throws -> String { struct Response: Codable, Sendable { let script: String }; let response: Response = try await client.request("POST", "/api/tasks/generate-script", body: ["description": description], options: options); return response.script }
    /// Executes a saved Figranium task and decodes its structured result.
    public func run<Value: Codable & Sendable>(_ id: String, input: ExecuteTaskOptions = .init(), options: RequestOptions = .init()) async throws -> ExecutionResult<Value> { try await client.request("POST", "/tasks/\(pathID(id))/api", body: input, options: options) }
}
/// API resource for executions operations.
public struct ExecutionsResource: Sendable { let client: Figranium
    /// Performs the list operation.
    public func list(apiKeyRoute: Bool = true, options: RequestOptions = .init()) async throws -> [Execution] { struct Response: Codable, Sendable { let executions: [Execution] }; let response: Response = try await client.request("GET", apiKeyRoute ? "/api/executions/list" : "/api/executions", options: options); return response.executions }
    /// Performs the get operation.
    public func get(_ id: String, options: RequestOptions = .init()) async throws -> Execution { struct Response: Codable, Sendable { let execution: Execution }; let response: Response = try await client.request("GET", "/api/executions/\(pathID(id))", options: options); return response.execution }
    /// Performs the delete operation.
    public func delete(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/executions/\(pathID(id))", options: options) }
    /// Performs the clear operation.
    public func clear(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/executions/clear", options: options) }
    /// Performs the stop operation.
    public func stop(runID: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/executions/stop", body: ["runId": runID], options: options) }
    /// Opens a server-sent event stream for live Figranium updates.
    public func stream(options: RequestOptions = .init()) -> AsyncThrowingStream<StreamEvent<JSONValue>, Error> { client.stream("/api/executions/stream", options: options) }
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
    public func cookies(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/data/cookies", options: options) }
    /// Performs the delete cookie operation.
    public func deleteCookie(name: String, domain: String? = nil, path: String? = nil, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/data/cookies/delete", body: ["name": name, "domain": domain, "path": path], options: options) }
    /// Performs the clear operation.
    public func clear(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/data/clear-screenshots", options: options) }
    /// Performs the clear cookies operation.
    public func clearCookies(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/data/clear-cookies", options: options) }
}
/// API resource for cabinets operations.
public struct CabinetsResource: Sendable { let client: Figranium
    /// Performs the list operation.
    public func list(options: RequestOptions = .init()) async throws -> [Cabinet] { try await client.request("GET", "/api/cabinets", options: options) }
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
    public func unzipItem(_ cabinetID: String, itemID: String, options: RequestOptions = .init()) async throws -> [CabinetItem] { struct Response: Codable, Sendable { let items: [CabinetItem] }; let response: Response = try await client.request("POST", "/api/cabinets/\(pathID(cabinetID))/items/\(pathID(itemID))/unzip", options: options); return response.items }
    /// Performs the download url operation.
    public func downloadURL(cabinetID: String, itemID: String) -> URL { client.baseURL.appendingPathComponent("api/cabinets/\(pathID(cabinetID))/items/\(pathID(itemID))/download") }
}
/// API resource for credentials operations.
public struct CredentialsResource: Sendable { let client: Figranium
    /// Performs the list operation.
    public func list(options: RequestOptions = .init()) async throws -> [Credential] { try await client.request("GET", "/api/credentials", options: options) }
    /// Performs the create operation.
    public func create(_ input: CredentialInput, options: RequestOptions = .init()) async throws -> Credential { try await client.request("POST", "/api/credentials", body: input, options: options) }
    /// Performs the update operation.
    public func update(_ id: String, input: CredentialInput, options: RequestOptions = .init()) async throws -> Credential { try await client.request("PUT", "/api/credentials/\(pathID(id))", body: input, options: options) }
    /// Performs the delete operation.
    public func delete(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/credentials/\(pathID(id))", options: options) }
    /// Performs the baserow databases operation.
    public func baserowDatabases(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/credentials/\(pathID(id))/proxy/baserow/databases", options: options) }
    /// Performs the baserow tables operation.
    public func baserowTables(_ id: String, databaseID: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/credentials/\(pathID(id))/proxy/baserow/databases/\(pathID(databaseID))/tables", options: options) }
}
/// API resource for browser operations.
public struct BrowserResource: Sendable { let client: Figranium
    /// Performs the open operation.
    public func open(_ input: JSONObject = [:], options: RequestOptions = .init()) async throws -> BrowserSession { try await client.request("POST", "/api/browser/open", body: input, options: options) }
    /// Performs the highlight operation.
    public func highlight(_ input: JSONObject, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/inspector/highlight", body: input, options: options) }
    /// Performs the stop headful operation.
    public func stopHeadful(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/headful/stop", options: options) }
    /// Performs the headful status operation.
    public func headfulStatus(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/headful/status", options: options) }
    /// Performs the inspect operation.
    public func inspect(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/headful/inspect", options: options) }
    /// Performs the vnc password operation.
    public func vncPassword(options: RequestOptions = .init()) async throws -> String { struct Response: Codable, Sendable { let password: String }; let response: Response = try await client.request("GET", "/api/headful/vnc-password", options: options); return response.password }
    /// Opens a server-sent event stream for live Figranium updates.
    public func selectorStream(options: RequestOptions = .init()) -> AsyncThrowingStream<StreamEvent<JSONValue>, Error> { client.stream("/api/headful/selector_stream", options: options) }
}
/// API resource for settings operations.
public struct SettingsResource: Sendable { let client: Figranium
    /// Performs the get apikey operation.
    public func getAPIKey(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/settings/api-key", options: options) }
    /// Performs the set apikey operation.
    public func setAPIKey(_ key: String? = nil, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/api-key", body: ["apiKey": key], options: options) }
    /// Performs the get user agent operation.
    public func getUserAgent(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/settings/user-agent", options: options) }
    /// Performs the set user agent operation.
    public func setUserAgent(_ selection: String?, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/user-agent", body: ["selection": selection], options: options) }
    /// Performs the get aimodels operation.
    public func getAIModels(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/settings/ai-models", options: options) }
    /// Performs the set aimodels operation.
    public func setAIModels(_ models: JSONObject, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/ai-models", body: models, options: options) }
    /// Performs the get theme operation.
    public func getTheme(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/settings/theme", options: options) }
    /// Performs the set theme operation.
    public func setTheme(_ theme: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/theme", body: ["theme": theme], options: options) }
    /// Performs the list proxies operation.
    public func listProxies(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/settings/proxies", options: options) }
    /// Performs the add proxy operation.
    public func addProxy(_ proxy: ProxyInput, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/proxies", body: proxy, options: options) }
    /// Performs the import proxies operation.
    public func importProxies(_ proxies: [ProxyInput], options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/proxies/import", body: ["proxies": proxies], options: options) }
    /// Performs the update proxy operation.
    public func updateProxy(_ id: String, proxy: ProxyInput, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("PUT", "/api/settings/proxies/\(pathID(id))", body: proxy, options: options) }
    /// Performs the delete proxy operation.
    public func deleteProxy(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/settings/proxies/\(pathID(id))", options: options) }
    /// Performs the delete proxies operation.
    public func deleteProxies(_ ids: [String], options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/settings/proxies", body: ["ids": ids], options: options) }
    /// Performs the set default proxy operation.
    public func setDefaultProxy(_ id: String?, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/proxies/default", body: ["id": id], options: options) }
    /// Performs the set proxy rotation operation.
    public func setProxyRotation(_ input: JSONObject, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/proxies/rotation", body: input, options: options) }
    /// Performs the provider keys operation.
    public func providerKeys(_ provider: String, options: RequestOptions = .init()) async throws -> JSONObject { let path = provider == "openai" ? "openai-api-key" : "\(provider)-api-key"; return try await client.request("GET", "/api/settings/\(path)", options: options) }
    /// Performs the set provider keys operation.
    public func setProviderKeys(_ provider: String, keys: [String], options: RequestOptions = .init()) async throws -> JSONObject { let path = provider == "openai" ? "openai-api-key" : "\(provider)-api-key"; let key = provider == "openai" ? "openAiApiKeys" : "\(provider)ApiKeys"; return try await client.request("POST", "/api/settings/\(path)", body: [key: keys], options: options) }
}
/// API resource for execution operations.
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
