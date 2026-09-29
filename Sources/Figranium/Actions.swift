import Foundation

/// Creates a Figranium variable template such as `{$name}`.
public func variable(_ name: String) -> String { precondition(!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Variable name must not be empty"); return "{$\(name)}" }

/// Factory helpers for constructing Figranium task actions.
public enum Actions {
    /// Creates a Figranium action action.
    public static func action(_ value: Action) -> Action { var copy = value; if copy.id == nil { copy.id = "act_\(copy.type)_\(UUID().uuidString.lowercased())" }; return copy }
    /// Creates a Figranium navigate action.
    public static func navigate(_ url: String) -> Action { action(.init(type: "navigate", value: url)) }
    /// Creates a Figranium click action.
    public static func click(_ selector: String, kind: String = "single") -> Action { action(.init(type: "click", selector: selector, clickType: kind == "single" ? nil : kind)) }
    /// Creates a Figranium check action.
    public static func check(_ selector: String) -> Action { action(.init(type: "check", selector: selector)) }
    /// Creates a Figranium uncheck action.
    public static func uncheck(_ selector: String) -> Action { action(.init(type: "uncheck", selector: selector)) }
    /// Creates a Figranium drag and drop action.
    public static func dragAndDrop(_ selector: String, to target: String) -> Action { action(.init(type: "drag_and_drop", selector: selector, targetSelector: target)) }
    /// Creates a Figranium reload action.
    public static func reload() -> Action { action(.init(type: "reload")) }
    /// Creates a Figranium select action.
    public static func select(_ selector: String, value: String) -> Action { action(.init(type: "select", selector: selector, value: value)) }
    /// Creates a Figranium type action.
    public static func type(_ selector: String, value: String, mode: String = "replace") -> Action { action(.init(type: "type", selector: selector, value: value, typeMode: mode)) }
    /// Creates a Figranium wait action.
    public static func wait(_ seconds: Double) -> Action { action(.init(type: "wait", value: String(seconds))) }
    /// Creates a Figranium wait for action.
    public static func waitFor(_ selector: String) -> Action { action(.init(type: "wait_selector", selector: selector)) }
    /// Creates a Figranium wait for downloads action.
    public static func waitForDownloads(_ timeout: Double? = nil) -> Action { action(.init(type: "wait_downloads", value: timeout.map { String($0) })) }
    /// Creates a Figranium press action.
    public static func press(_ key: String, selector: String? = nil) -> Action { action(.init(type: "press", selector: selector, key: key)) }
    /// Creates a Figranium scroll action.
    public static func scroll(selector: String? = nil, value: String? = nil) -> Action { action(.init(type: "scroll", selector: selector, value: value)) }
    /// Creates a Figranium javascript action.
    public static func javascript(_ script: String, varName: String? = nil) -> Action { action(.init(type: "javascript", value: script, varName: varName)) }
    /// Creates a Figranium csv action.
    public static func csv(_ value: String? = nil, selector: String? = nil, varName: String? = nil) -> Action { action(.init(type: "csv", selector: selector, value: value, varName: varName)) }
    /// Creates a Figranium hover action.
    public static func hover(_ selector: String) -> Action { action(.init(type: "hover", selector: selector)) }
    /// Creates a Figranium merge action.
    public static func merge(_ name: String, value: String) -> Action { action(.init(type: "merge", value: value, varName: name)) }
    /// Creates a Figranium screenshot action.
    public static func screenshot(_ name: String? = nil) -> Action { action(.init(type: "screenshot", value: name)) }
    /// Creates a Figranium conditional action.
    public static func conditional(_ type: String, selector: String? = nil, value: String? = nil, variable: String? = nil, variableType: String? = nil, operation: String? = nil, comparisonValue: String? = nil) -> Action { action(.init(type: type, selector: selector, value: value, conditionVar: variable, conditionVarType: variableType, conditionOp: operation, conditionValue: comparisonValue)) }
    /// Creates a Figranium else block action.
    public static func elseBlock() -> Action { action(.init(type: "else")) }; public static func end() -> Action { action(.init(type: "end")) }
    /// Creates a Figranium while action.
    public static func `while`(selector: String? = nil, value: String? = nil, variable: String? = nil, variableType: String? = nil, operation: String? = nil, comparisonValue: String? = nil) -> Action { conditional("while", selector: selector, value: value, variable: variable, variableType: variableType, operation: operation, comparisonValue: comparisonValue) }
    /// Creates a Figranium if action.
    public static func `if`(selector: String? = nil, value: String? = nil, variable: String? = nil, variableType: String? = nil, operation: String? = nil, comparisonValue: String? = nil) -> Action { conditional("if", selector: selector, value: value, variable: variable, variableType: variableType, operation: operation, comparisonValue: comparisonValue) }
    /// Creates a Figranium repeat count action.
    public static func repeatCount(_ count: Int) -> Action { action(.init(type: "repeat", value: String(count))) }
    /// Creates a Figranium for each action.
    public static func forEach(selector: String? = nil, value: String? = nil, varName: String? = nil) -> Action { action(.init(type: "foreach", selector: selector, value: value, varName: varName)) }
    /// Creates a Figranium stop action.
    public static func stop(_ outcome: String = "success") -> Action { action(.init(type: "stop", value: outcome)) }; public static func set(_ name: String, value: String) -> Action { action(.init(type: "set", value: value, varName: name)) }
    /// Creates a Figranium on error action.
    public static func onError(_ value: String? = nil) -> Action { action(.init(type: "on_error", value: value)) }; public static func doNothing() -> Action { action(.init(type: "do_nothing")) }; public static func start(_ taskId: String) -> Action { action(.init(type: "start", value: taskId)) }
    /// Creates a Figranium request action.
    public static func request(_ url: String, method: String? = nil, headers: String? = nil, body: String? = nil, varName: String? = nil) -> Action { action(.init(type: "http_request", value: url, varName: varName, method: method, headers: headers, body: body)) }
    /// Creates a Figranium get content action.
    public static func getContent(selector: String? = nil, varName: String? = nil) -> Action { action(.init(type: "get_content", selector: selector, varName: varName)) }
    /// Creates a Figranium captcha action.
    public static func captcha(_ type: String, captchaType: String? = nil, selector: String? = nil, varName: String? = nil, timeout: Double? = nil) -> Action { action(.init(type: type, selector: selector, varName: varName, captchaType: captchaType, timeout: timeout)) }
    /// Creates a Figranium solve captcha action.
    public static func solveCaptcha(captchaType: String? = nil, selector: String? = nil, varName: String? = nil, timeout: Double? = nil) -> Action { captcha("solve_captcha", captchaType: captchaType, selector: selector, varName: varName, timeout: timeout) }
    /// Creates a Figranium wait for captcha action.
    public static func waitForCaptcha(captchaType: String? = nil, selector: String? = nil, varName: String? = nil, timeout: Double? = nil) -> Action { captcha("wait_captcha", captchaType: captchaType, selector: selector, varName: varName, timeout: timeout) }
    /// Creates a Figranium upload action.
    public static func upload(selector: String? = nil, cabinetId: String? = nil, markAsUploaded: Bool? = nil) -> Action { action(.init(type: "upload", selector: selector, cabinetId: cabinetId, markAsUploaded: markAsUploaded)) }
    /// Creates a Figranium finalize uploads action.
    public static func finalizeUploads() -> Action { action(.init(type: "finalize_uploads")) }
}
