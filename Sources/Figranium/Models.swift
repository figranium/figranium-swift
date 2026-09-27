import Foundation

public enum JSONValue: Codable, Sendable, Equatable {
    case string(String), number(Double), bool(Bool), array([JSONValue]), object([String: JSONValue]), null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([JSONValue].self) { self = .array(value) }
        else { self = .object(try container.decode([String: JSONValue].self)) }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

public typealias JSONObject = [String: JSONValue]
public typealias RuntimeVariables = [String: JSONValue]
public typealias TaskMode = String
public typealias TaskOutcome = String

public struct RequestOptions: Sendable {
    public var headers: [String: String]
    public var timeout: TimeInterval?
    public init(headers: [String: String] = [:], timeout: TimeInterval? = nil) { self.headers = headers; self.timeout = timeout }
}

public struct TaskVariable: Codable, Sendable, Equatable {
    public var type: String
    public var value: JSONValue
    public var autoCreated: Bool?
    public init(type: String, value: JSONValue, autoCreated: Bool? = nil) { self.type = type; self.value = value; self.autoCreated = autoCreated }
}

public struct StealthConfig: Codable, Sendable, Equatable {
    public var allowTypos, idleMovements, overscroll, deadClicks, fatigue, naturalTyping, cursorGlide, randomizeClicks: Bool?
    public init() {}
}

public struct TaskTranslation: Codable, Sendable, Equatable {
    public var enabled: Bool
    public var targetLanguage: String
    public init(enabled: Bool, targetLanguage: String) { self.enabled = enabled; self.targetLanguage = targetLanguage }
}

public struct Schedule: Codable, Sendable, Equatable {
    public var enabled: Bool
    public var frequency: String?, intervalMinutes: Int?, hour: Int?, minute: Int?, daysOfWeek: [Int]?, dayOfMonth: Int?, cron: String?
    public var lastRun: Double?, lastRunStatus: String?, lastRunDurationMs: Double?, nextRun: Double?
    public init(enabled: Bool, frequency: String? = nil, intervalMinutes: Int? = nil, hour: Int? = nil, minute: Int? = nil, daysOfWeek: [Int]? = nil, dayOfMonth: Int? = nil, cron: String? = nil) {
        self.enabled = enabled; self.frequency = frequency; self.intervalMinutes = intervalMinutes; self.hour = hour; self.minute = minute; self.daysOfWeek = daysOfWeek; self.dayOfMonth = dayOfMonth; self.cron = cron
    }
}

public struct TaskOutput: Codable, Sendable, Equatable {
    public var provider, credentialId, tableId: String
    public var onError: String?
    public init(provider: String = "baserow", credentialId: String, tableId: String, onError: String? = nil) { self.provider = provider; self.credentialId = credentialId; self.tableId = tableId; self.onError = onError }
}

/// A task action. Every field defined by AGENT_SPEC.md is represented here; use `Actions` for ergonomic construction.
public struct Action: Codable, Sendable, Equatable, Identifiable {
    public var id: String?
    public var type: String
    public var disabled: Bool?
    public var selector, targetSelector, value, clickType, typeMode, key, varName, method, headers, body: String?
    public var conditionVar, conditionVarType, conditionOp, conditionValue, captchaType, cabinetId: String?
    public var timeout: Double?
    public var markAsUploaded: Bool?
    public init(type: String, id: String? = nil, disabled: Bool? = nil, selector: String? = nil, targetSelector: String? = nil, value: String? = nil, clickType: String? = nil, typeMode: String? = nil, key: String? = nil, varName: String? = nil, method: String? = nil, headers: String? = nil, body: String? = nil, conditionVar: String? = nil, conditionVarType: String? = nil, conditionOp: String? = nil, conditionValue: String? = nil, captchaType: String? = nil, timeout: Double? = nil, cabinetId: String? = nil, markAsUploaded: Bool? = nil) {
        self.type = type; self.id = id; self.disabled = disabled; self.selector = selector; self.targetSelector = targetSelector; self.value = value; self.clickType = clickType; self.typeMode = typeMode; self.key = key; self.varName = varName; self.method = method; self.headers = headers; self.body = body; self.conditionVar = conditionVar; self.conditionVarType = conditionVarType; self.conditionOp = conditionOp; self.conditionValue = conditionValue; self.captchaType = captchaType; self.timeout = timeout; self.cabinetId = cabinetId; self.markAsUploaded = markAsUploaded
    }
}

public struct Task: Codable, Sendable, Equatable, Identifiable {
    public var id: String?
    public var name: String
    public var description, url, mode: String
    public var wait: Double?, selector: String?
    public var rotateUserAgents, rotateProxies, rotateViewport, humanTyping: Bool?
    public var stealth: StealthConfig?, autoSolveCaptcha: Bool?, translation: TaskTranslation?
    public var actions: [Action]?, variables: [String: TaskVariable]?, schedule: Schedule?, output: TaskOutput?
    public var extractionScript, extractionFormat: String?
    public var includeHtml, includeShadowDom, disableRecording, statelessExecution: Bool?
    public var downloadCabinetId, cabinetId: String?
    public init(name: String, url: String, mode: String, description: String = "", actions: [Action]? = nil, variables: [String: TaskVariable]? = nil) {
        self.name = name; self.url = url; self.mode = mode; self.description = description; self.actions = actions; self.variables = variables
    }
}

public struct ExecuteTaskOptions: Codable, Sendable, Equatable {
    public var variables: RuntimeVariables?, taskVariables: RuntimeVariables?, webhookUrl, runId: String?
    public init(variables: RuntimeVariables? = nil, taskVariables: RuntimeVariables? = nil, webhookUrl: String? = nil, runId: String? = nil) { self.variables = variables; self.taskVariables = taskVariables; self.webhookUrl = webhookUrl; self.runId = runId }
}

public struct ExecutionResult<Value: Codable & Sendable>: Codable, Sendable {
    public var data: Value?, outcome: String?, success: Bool?, error, runId: String?
    public init(data: Value? = nil, outcome: String? = nil, success: Bool? = nil, error: String? = nil, runId: String? = nil) { self.data = data; self.outcome = outcome; self.success = success; self.error = error; self.runId = runId }
}

public struct StreamEvent<Value: Sendable>: Sendable {
    public var data: Value
    public var event, id: String?
    public var retry: Int?
    public var raw: String
}

public struct Execution: Codable, Sendable {
    public var id: String; public var timestamp: Double
    public var method, path, status, outcome: String?; public var durationMs: Double?
    public var source, mode, taskId, taskName, url: String?; public var result: JSONValue?
}

public struct TaskSummary: Codable, Sendable { public var id, name: String; public var description: String? }
public struct TaskVersion: Codable, Sendable { public var id: String; public var timestamp: Double; public var name, mode: String? }
public struct Cabinet: Codable, Sendable { public var id, name: String; public var isDefault: Bool?; public var itemCount: Int?; public var createdAt: Double? }
public struct CabinetItem: Codable, Sendable { public var id, name, kind, status: String; public var size: Int?; public var createdAt: Double?; public var sourceTaskId, sourceRunId: String? }
public struct Capture: Codable, Sendable { public var name, url: String; public var size: Int; public var modified: Double; public var type: String }
public struct CredentialInput: Codable, Sendable { public var name, provider: String; public var config: [String: String]; public init(name: String, provider: String = "baserow", config: [String: String]) { self.name = name; self.provider = provider; self.config = config } }
public struct Credential: Codable, Sendable { public var id, name, provider: String; public var config: [String: String] }
public struct BrowserSession: Codable, Sendable { public var sessionId, status: String; public var wsEndpoint: String? }
public struct SelectorCandidate: Codable, Sendable { public var css: String; public var xpath: String?; public var confidence: Double? }
public struct HealthStatus: Codable, Sendable { public var status, version: String? }
public struct User: Codable, Sendable { public var id, name, email: String? }
public struct ProxyInput: Codable, Sendable { public var server: String; public var username, password, label: String?; public var isRotatingPool: Bool?; public var estimatedPoolSize: Int? }
