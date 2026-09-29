import Foundation

/// A Sendable, Codable representation of an arbitrary JSON value.
public enum JSONValue: Codable, Sendable, Equatable {
    case string(String), number(Double), bool(Bool), array([JSONValue]), object([String: JSONValue]), null

    /// Creates a new JSONValue.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([JSONValue].self) { self = .array(value) }
        else { self = .object(try container.decode([String: JSONValue].self)) }
    }

    /// Performs the encode operation.
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

/// Convenience type for jsonobject values.
public typealias JSONObject = [String: JSONValue]
/// Convenience type for runtime variables values.
public typealias RuntimeVariables = [String: JSONValue]
/// Convenience type for task mode values.
public typealias TaskMode = String
/// Convenience type for task outcome values.
public typealias TaskOutcome = String

/// Per-request headers and timeout overrides.
public struct RequestOptions: Sendable {
    /// The headers value.
    public var headers: [String: String]
    /// The timeout value.
    public var timeout: TimeInterval?
    /// Creates a new RequestOptions.
    public init(headers: [String: String] = [:], timeout: TimeInterval? = nil) { self.headers = headers; self.timeout = timeout }
}

/// Represents task variable data used by the Figranium SDK.
public struct TaskVariable: Codable, Sendable, Equatable {
    /// The type value.
    public var type: String
    /// The value value.
    public var value: JSONValue
    /// The auto created value.
    public var autoCreated: Bool?
    /// Creates a new TaskVariable.
    public init(type: String, value: JSONValue, autoCreated: Bool? = nil) { self.type = type; self.value = value; self.autoCreated = autoCreated }
}

/// Represents stealth config data used by the Figranium SDK.
public struct StealthConfig: Codable, Sendable, Equatable {
    /// The allow typos value.
    public var allowTypos, idleMovements, overscroll, deadClicks, fatigue, naturalTyping, cursorGlide, randomizeClicks: Bool?
    /// Creates a new StealthConfig.
    public init() {}
}

/// Represents task translation data used by the Figranium SDK.
public struct TaskTranslation: Codable, Sendable, Equatable {
    /// The enabled value.
    public var enabled: Bool
    /// The target language value.
    public var targetLanguage: String
    /// Creates a new TaskTranslation.
    public init(enabled: Bool, targetLanguage: String) { self.enabled = enabled; self.targetLanguage = targetLanguage }
}

/// Represents schedule data used by the Figranium SDK.
public struct Schedule: Codable, Sendable, Equatable {
    /// The enabled value.
    public var enabled: Bool
    /// The frequency value.
    public var frequency: String?, intervalMinutes: Int?, hour: Int?, minute: Int?, daysOfWeek: [Int]?, dayOfMonth: Int?, cron: String?
    /// The last run value.
    public var lastRun: Double?, lastRunStatus: String?, lastRunDurationMs: Double?, nextRun: Double?
    /// Creates a new Schedule.
    public init(enabled: Bool, frequency: String? = nil, intervalMinutes: Int? = nil, hour: Int? = nil, minute: Int? = nil, daysOfWeek: [Int]? = nil, dayOfMonth: Int? = nil, cron: String? = nil) {
        self.enabled = enabled; self.frequency = frequency; self.intervalMinutes = intervalMinutes; self.hour = hour; self.minute = minute; self.daysOfWeek = daysOfWeek; self.dayOfMonth = dayOfMonth; self.cron = cron
    }
}

/// Represents task output data used by the Figranium SDK.
public struct TaskOutput: Codable, Sendable, Equatable {
    /// The provider value.
    public var provider, credentialId, tableId: String
    /// The on error value.
    public var onError: String?
    /// Creates a new TaskOutput.
    public init(provider: String = "baserow", credentialId: String, tableId: String, onError: String? = nil) { self.provider = provider; self.credentialId = credentialId; self.tableId = tableId; self.onError = onError }
}

/// A task action. Every field defined by AGENT_SPEC.md is represented here; use `Actions` for ergonomic construction.
public struct Action: Codable, Sendable, Equatable, Identifiable {
    /// The id value.
    public var id: String?
    /// The type value.
    public var type: String
    /// The disabled value.
    public var disabled: Bool?
    /// The selector value.
    public var selector, targetSelector, value, clickType, typeMode, key, varName, method, headers, body: String?
    /// The condition var value.
    public var conditionVar, conditionVarType, conditionOp, conditionValue, captchaType, cabinetId: String?
    /// The timeout value.
    public var timeout: Double?
    /// The mark as uploaded value.
    public var markAsUploaded: Bool?
    /// Creates a new Action.
    public init(type: String, id: String? = nil, disabled: Bool? = nil, selector: String? = nil, targetSelector: String? = nil, value: String? = nil, clickType: String? = nil, typeMode: String? = nil, key: String? = nil, varName: String? = nil, method: String? = nil, headers: String? = nil, body: String? = nil, conditionVar: String? = nil, conditionVarType: String? = nil, conditionOp: String? = nil, conditionValue: String? = nil, captchaType: String? = nil, timeout: Double? = nil, cabinetId: String? = nil, markAsUploaded: Bool? = nil) {
        self.type = type; self.id = id; self.disabled = disabled; self.selector = selector; self.targetSelector = targetSelector; self.value = value; self.clickType = clickType; self.typeMode = typeMode; self.key = key; self.varName = varName; self.method = method; self.headers = headers; self.body = body; self.conditionVar = conditionVar; self.conditionVarType = conditionVarType; self.conditionOp = conditionOp; self.conditionValue = conditionValue; self.captchaType = captchaType; self.timeout = timeout; self.cabinetId = cabinetId; self.markAsUploaded = markAsUploaded
    }
}

/// A Figranium browser automation task.
public struct Task: Codable, Sendable, Equatable, Identifiable {
    /// The id value.
    public var id: String?
    /// The name value.
    public var name: String
    /// The description value.
    public var description, url, mode: String
    /// The wait value.
    public var wait: Double?, selector: String?
    /// The rotate user agents value.
    public var rotateUserAgents, rotateProxies, rotateViewport, humanTyping: Bool?
    /// The stealth value.
    public var stealth: StealthConfig?, autoSolveCaptcha: Bool?, translation: TaskTranslation?
    /// The actions value.
    public var actions: [Action]?, variables: [String: TaskVariable]?, schedule: Schedule?, output: TaskOutput?
    /// The extraction script value.
    public var extractionScript, extractionFormat: String?
    /// The include html value.
    public var includeHtml, includeShadowDom, disableRecording, statelessExecution: Bool?
    /// The download cabinet id value.
    public var downloadCabinetId, cabinetId: String?
    /// Creates a new Task.
    public init(name: String, url: String, mode: String, description: String = "", actions: [Action]? = nil, variables: [String: TaskVariable]? = nil) {
        self.name = name; self.url = url; self.mode = mode; self.description = description; self.actions = actions; self.variables = variables
    }
}

/// Represents execute task options data used by the Figranium SDK.
public struct ExecuteTaskOptions: Codable, Sendable, Equatable {
    /// The variables value.
    public var variables: RuntimeVariables?, taskVariables: RuntimeVariables?, webhookUrl, runId: String?
    /// Creates a new ExecuteTaskOptions.
    public init(variables: RuntimeVariables? = nil, taskVariables: RuntimeVariables? = nil, webhookUrl: String? = nil, runId: String? = nil) { self.variables = variables; self.taskVariables = taskVariables; self.webhookUrl = webhookUrl; self.runId = runId }
}

/// The structured result returned by a Figranium execution.
public struct ExecutionResult<Value: Codable & Sendable>: Codable, Sendable {
    /// The data value.
    public var data: Value?, outcome: String?, success: Bool?, error, runId: String?
    /// Creates a new ExecutionResult.
    public init(data: Value? = nil, outcome: String? = nil, success: Bool? = nil, error: String? = nil, runId: String? = nil) { self.data = data; self.outcome = outcome; self.success = success; self.error = error; self.runId = runId }
}

/// A server-sent event emitted by a Figranium stream.
public struct StreamEvent<Value: Sendable>: Sendable {
    /// The data value.
    public var data: Value
    /// The event value.
    public var event, id: String?
    /// The retry value.
    public var retry: Int?
    /// The raw value.
    public var raw: String
}

/// A recorded Figranium execution.
public struct Execution: Codable, Sendable {
    /// The id value.
    public var id: String; public var timestamp: Double
    /// The method value.
    public var method, path, status, outcome: String?; public var durationMs: Double?
    /// The source value.
    public var source, mode, taskId, taskName, url: String?; public var result: JSONValue?
}

/// Represents task summary data used by the Figranium SDK.
public struct TaskSummary: Codable, Sendable { public var id, name: String; public var description: String? }
/// Represents task version data used by the Figranium SDK.
public struct TaskVersion: Codable, Sendable { public var id: String; public var timestamp: Double; public var name, mode: String? }
/// Represents cabinet data used by the Figranium SDK.
public struct Cabinet: Codable, Sendable { public var id, name: String; public var isDefault: Bool?; public var itemCount: Int?; public var createdAt: Double? }
/// Represents cabinet item data used by the Figranium SDK.
public struct CabinetItem: Codable, Sendable { public var id, name, kind, status: String; public var size: Int?; public var createdAt: Double?; public var sourceTaskId, sourceRunId: String? }
/// Represents capture data used by the Figranium SDK.
public struct Capture: Codable, Sendable { public var name, url: String; public var size: Int; public var modified: Double; public var type: String }
/// Represents credential input data used by the Figranium SDK.
public struct CredentialInput: Codable, Sendable { public var name, provider: String; public var config: [String: String]; public init(name: String, provider: String = "baserow", config: [String: String]) { self.name = name; self.provider = provider; self.config = config } }
/// Represents credential data used by the Figranium SDK.
public struct Credential: Codable, Sendable { public var id, name, provider: String; public var config: [String: String] }
/// Represents browser session data used by the Figranium SDK.
public struct BrowserSession: Codable, Sendable { public var sessionId, status: String; public var wsEndpoint: String? }
/// Represents selector candidate data used by the Figranium SDK.
public struct SelectorCandidate: Codable, Sendable { public var css: String; public var xpath: String?; public var confidence: Double? }
/// Represents health status data used by the Figranium SDK.
public struct HealthStatus: Codable, Sendable { public var status, version: String? }
/// Represents user data used by the Figranium SDK.
public struct User: Codable, Sendable { public var id, name, email: String? }
/// Represents proxy input data used by the Figranium SDK.
public struct ProxyInput: Codable, Sendable { public var server: String; public var username, password, label: String?; public var isRotatingPool: Bool?; public var estimatedPoolSize: Int? }
