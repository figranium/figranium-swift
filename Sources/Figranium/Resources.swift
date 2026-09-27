import Foundation

public struct AuthResource: Sendable { let client: Figranium
    public func checkSetup(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/auth/check-setup", options: options) }
    public func setup(name: String, email: String, password: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/auth/setup", body: ["name": name, "email": email, "password": password], options: options) }
    public func login(email: String, password: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/auth/login", body: ["email": email, "password": password], options: options) }
    public func logout(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/auth/logout", options: options) }
    public func me(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/auth/me", options: options) }
}
public struct TasksResource: Sendable { let client: Figranium
    public func list(options: RequestOptions = .init()) async throws -> [Task] { try await client.request("GET", "/api/tasks", options: options) }
    public func listSummaries(options: RequestOptions = .init()) async throws -> [TaskSummary] { struct Response: Codable, Sendable { let tasks: [TaskSummary] }; let response: Response = try await client.request("GET", "/api/tasks/list", options: options); return response.tasks }
    public func save(_ task: Task, createVersion: Bool = false, options: RequestOptions = .init()) async throws -> Task { try await client.request("POST", "/api/tasks", body: task, query: ["version": createVersion ? "true" : ""], options: options) }
    public func touch(_ id: String, options: RequestOptions = .init()) async throws -> Task { try await client.request("POST", "/api/tasks/\(pathID(id))/touch", options: options) }
    public func update(_ id: String, patch: JSONObject, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("PATCH", "/api/tasks/\(pathID(id))", body: patch, options: options) }
    public func delete(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/tasks/\(pathID(id))", options: options) }
    public func versions(_ id: String, options: RequestOptions = .init()) async throws -> [TaskVersion] { struct Response: Codable, Sendable { let versions: [TaskVersion] }; let response: Response = try await client.request("GET", "/api/tasks/\(pathID(id))/versions", options: options); return response.versions }
    public func version(_ id: String, versionID: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/tasks/\(pathID(id))/versions/\(pathID(versionID))", options: options) }
    public func clearVersions(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/tasks/\(pathID(id))/versions/clear", options: options) }
    public func rollback(_ id: String, versionID: String, options: RequestOptions = .init()) async throws -> Task { try await client.request("POST", "/api/tasks/\(pathID(id))/rollback", body: ["versionId": versionID], options: options) }
    public func generateSelector(task: Task, actionIndex: Int, prompt: String, options: RequestOptions = .init()) async throws -> String { struct Response: Codable, Sendable { let selector: String }; struct Input: Codable { let task: Task; let actionIndex: Int; let prompt: String }; let response: Response = try await client.request("POST", "/api/tasks/generate-selector", body: Input(task: task, actionIndex: actionIndex, prompt: prompt), options: options); return response.selector }
    public func generateScript(_ description: String, options: RequestOptions = .init()) async throws -> String { struct Response: Codable, Sendable { let script: String }; let response: Response = try await client.request("POST", "/api/tasks/generate-script", body: ["description": description], options: options); return response.script }
    public func run<Value: Codable & Sendable>(_ id: String, input: ExecuteTaskOptions = .init(), options: RequestOptions = .init()) async throws -> ExecutionResult<Value> { try await client.request("POST", "/tasks/\(pathID(id))/api", body: input, options: options) }
}
public struct ExecutionsResource: Sendable { let client: Figranium
    public func list(apiKeyRoute: Bool = true, options: RequestOptions = .init()) async throws -> [Execution] { struct Response: Codable, Sendable { let executions: [Execution] }; let response: Response = try await client.request("GET", apiKeyRoute ? "/api/executions/list" : "/api/executions", options: options); return response.executions }
    public func get(_ id: String, options: RequestOptions = .init()) async throws -> Execution { struct Response: Codable, Sendable { let execution: Execution }; let response: Response = try await client.request("GET", "/api/executions/\(pathID(id))", options: options); return response.execution }
    public func delete(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/executions/\(pathID(id))", options: options) }
    public func clear(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/executions/clear", options: options) }
    public func stop(runID: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/executions/stop", body: ["runId": runID], options: options) }
    public func stream(options: RequestOptions = .init()) -> AsyncThrowingStream<StreamEvent<JSONValue>, Error> { client.stream("/api/executions/stream", options: options) }
    public func watch(_ executionID: String, interval: Duration = .seconds(1), options: RequestOptions = .init()) -> AsyncThrowingStream<Execution, Error> { AsyncThrowingStream { continuation in let task = Swift.Task { do { var lastStatus: String?; while !Swift.Task.isCancelled { let value = try await get(executionID, options: options); if value.status != lastStatus { continuation.yield(value); lastStatus = value.status }; if ["success", "error", "stopped", "crashed", "anti_bot"].contains(value.outcome ?? value.status ?? "") { continuation.finish(); return }; try await Swift.Task.sleep(for: interval) } } catch { continuation.finish(throwing: error) } }; continuation.onTermination = { _ in task.cancel() } } }
}
public struct SchedulesResource: Sendable { let client: Figranium
    public func list(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/schedules", options: options) }
    public func set(_ taskID: String, schedule: Schedule, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/schedules/\(pathID(taskID))", body: schedule, options: options) }
    public func delete(_ taskID: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/schedules/\(pathID(taskID))", options: options) }
    public func status(_ taskID: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/schedules/\(pathID(taskID))/status", options: options) }
    public func describe(_ taskID: String, schedule: Schedule, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/schedules/\(pathID(taskID))/describe", body: schedule, options: options) }
    public func overallStatus(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/schedules/status/all", options: options) }
}
public struct CapturesResource: Sendable { let client: Figranium
    public func list(runID: String? = nil, options: RequestOptions = .init()) async throws -> [Capture] { struct Response: Codable, Sendable { let captures: [Capture] }; let response: Response = try await client.request("GET", "/api/data/captures", query: ["runId": runID ?? ""], options: options); return response.captures }
    public func screenshots(options: RequestOptions = .init()) async throws -> [Capture] { struct Response: Codable, Sendable { let screenshots: [Capture] }; let response: Response = try await client.request("GET", "/api/data/screenshots", options: options); return response.screenshots }
    public func delete(_ name: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/data/captures/\(pathID(name))", options: options) }
    public func cookies(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/data/cookies", options: options) }
    public func deleteCookie(name: String, domain: String? = nil, path: String? = nil, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/data/cookies/delete", body: ["name": name, "domain": domain, "path": path], options: options) }
    public func clear(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/data/clear-screenshots", options: options) }
    public func clearCookies(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/data/clear-cookies", options: options) }
}
public struct CabinetsResource: Sendable { let client: Figranium
    public func list(options: RequestOptions = .init()) async throws -> [Cabinet] { try await client.request("GET", "/api/cabinets", options: options) }
    public func create(_ name: String, options: RequestOptions = .init()) async throws -> Cabinet { try await client.request("POST", "/api/cabinets", body: ["name": name], options: options) }
    public func rename(_ id: String, name: String, options: RequestOptions = .init()) async throws -> Cabinet { try await client.request("PATCH", "/api/cabinets/\(pathID(id))", body: ["name": name], options: options) }
    public func delete(_ id: String, targetCabinetID: String? = nil, migrate: Bool = false, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/cabinets/\(pathID(id))", body: ["targetCabinetId": targetCabinetID, "mode": migrate ? "migrate" : nil], options: options) }
    public func listItems(_ id: String, options: RequestOptions = .init()) async throws -> [CabinetItem] { struct Response: Codable, Sendable { let items: [CabinetItem] }; let response: Response = try await client.request("GET", "/api/cabinets/\(pathID(id))/items", options: options); return response.items }
    public func clear(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/cabinets/\(pathID(id))/clear", options: options) }
    public func setItemStatus(_ cabinetID: String, itemIDs: [String], status: String, options: RequestOptions = .init()) async throws -> [CabinetItem] { struct Response: Codable, Sendable { let items: [CabinetItem] }; struct Input: Codable { let itemIds: [String]; let status: String }; let response: Response = try await client.request("PATCH", "/api/cabinets/\(pathID(cabinetID))/items/status", body: Input(itemIds: itemIDs, status: status), options: options); return response.items }
    public func removeItems(_ cabinetID: String, itemIDs: [String], options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/cabinets/\(pathID(cabinetID))/items", body: ["itemIds": itemIDs], options: options) }
    public func zipItems(_ cabinetID: String, itemIDs: [String], name: String? = nil, options: RequestOptions = .init()) async throws -> CabinetItem { struct Input: Codable { let itemIds: [String]; let name: String? }; return try await client.request("POST", "/api/cabinets/\(pathID(cabinetID))/zip", body: Input(itemIds: itemIDs, name: name), options: options) }
    public func unzipItem(_ cabinetID: String, itemID: String, options: RequestOptions = .init()) async throws -> [CabinetItem] { struct Response: Codable, Sendable { let items: [CabinetItem] }; let response: Response = try await client.request("POST", "/api/cabinets/\(pathID(cabinetID))/items/\(pathID(itemID))/unzip", options: options); return response.items }
    public func downloadURL(cabinetID: String, itemID: String) -> URL { client.baseURL.appendingPathComponent("api/cabinets/\(pathID(cabinetID))/items/\(pathID(itemID))/download") }
}
public struct CredentialsResource: Sendable { let client: Figranium
    public func list(options: RequestOptions = .init()) async throws -> [Credential] { try await client.request("GET", "/api/credentials", options: options) }
    public func create(_ input: CredentialInput, options: RequestOptions = .init()) async throws -> Credential { try await client.request("POST", "/api/credentials", body: input, options: options) }
    public func update(_ id: String, input: CredentialInput, options: RequestOptions = .init()) async throws -> Credential { try await client.request("PUT", "/api/credentials/\(pathID(id))", body: input, options: options) }
    public func delete(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/credentials/\(pathID(id))", options: options) }
    public func baserowDatabases(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/credentials/\(pathID(id))/proxy/baserow/databases", options: options) }
    public func baserowTables(_ id: String, databaseID: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/credentials/\(pathID(id))/proxy/baserow/databases/\(pathID(databaseID))/tables", options: options) }
}
public struct BrowserResource: Sendable { let client: Figranium
    public func open(_ input: JSONObject = [:], options: RequestOptions = .init()) async throws -> BrowserSession { try await client.request("POST", "/api/browser/open", body: input, options: options) }
    public func highlight(_ input: JSONObject, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/inspector/highlight", body: input, options: options) }
    public func stopHeadful(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/headful/stop", options: options) }
    public func headfulStatus(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/headful/status", options: options) }
    public func inspect(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/headful/inspect", options: options) }
    public func vncPassword(options: RequestOptions = .init()) async throws -> String { struct Response: Codable, Sendable { let password: String }; let response: Response = try await client.request("GET", "/api/headful/vnc-password", options: options); return response.password }
    public func selectorStream(options: RequestOptions = .init()) -> AsyncThrowingStream<StreamEvent<JSONValue>, Error> { client.stream("/api/headful/selector_stream", options: options) }
}
public struct SettingsResource: Sendable { let client: Figranium
    public func getAPIKey(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/settings/api-key", options: options) }
    public func setAPIKey(_ key: String? = nil, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/api-key", body: ["apiKey": key], options: options) }
    public func getUserAgent(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/settings/user-agent", options: options) }
    public func setUserAgent(_ selection: String?, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/user-agent", body: ["selection": selection], options: options) }
    public func getAIModels(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/settings/ai-models", options: options) }
    public func setAIModels(_ models: JSONObject, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/ai-models", body: models, options: options) }
    public func getTheme(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/settings/theme", options: options) }
    public func setTheme(_ theme: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/theme", body: ["theme": theme], options: options) }
    public func listProxies(options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("GET", "/api/settings/proxies", options: options) }
    public func addProxy(_ proxy: ProxyInput, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/proxies", body: proxy, options: options) }
    public func importProxies(_ proxies: [ProxyInput], options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/proxies/import", body: ["proxies": proxies], options: options) }
    public func updateProxy(_ id: String, proxy: ProxyInput, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("PUT", "/api/settings/proxies/\(pathID(id))", body: proxy, options: options) }
    public func deleteProxy(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/settings/proxies/\(pathID(id))", options: options) }
    public func deleteProxies(_ ids: [String], options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("DELETE", "/api/settings/proxies", body: ["ids": ids], options: options) }
    public func setDefaultProxy(_ id: String?, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/proxies/default", body: ["id": id], options: options) }
    public func setProxyRotation(_ input: JSONObject, options: RequestOptions = .init()) async throws -> JSONObject { try await client.request("POST", "/api/settings/proxies/rotation", body: input, options: options) }
    public func providerKeys(_ provider: String, options: RequestOptions = .init()) async throws -> JSONObject { let path = provider == "openai" ? "openai-api-key" : "\(provider)-api-key"; return try await client.request("GET", "/api/settings/\(path)", options: options) }
    public func setProviderKeys(_ provider: String, keys: [String], options: RequestOptions = .init()) async throws -> JSONObject { let path = provider == "openai" ? "openai-api-key" : "\(provider)-api-key"; let key = provider == "openai" ? "openAiApiKeys" : "\(provider)ApiKeys"; return try await client.request("POST", "/api/settings/\(path)", body: [key: keys], options: options) }
}
public struct ExecutionResource: Sendable { let client: Figranium
    public func scrape<Value: Codable & Sendable>(_ input: JSONObject, options: RequestOptions = .init()) async throws -> ExecutionResult<Value> { try await client.request("POST", "/scrape", body: input, options: options) }
    public func agent<Value: Codable & Sendable>(_ input: JSONObject, options: RequestOptions = .init()) async throws -> ExecutionResult<Value> { try await client.request("POST", "/agent", body: input, options: options) }
    public func headful<Value: Codable & Sendable>(_ input: JSONObject, options: RequestOptions = .init()) async throws -> ExecutionResult<Value> { try await client.request("POST", "/headful", body: input, options: options) }
}
public struct HealthResource: Sendable { let client: Figranium; public func check(options: RequestOptions = .init()) async throws -> HealthStatus { try await client.request("GET", "/api/health", options: options) } }
