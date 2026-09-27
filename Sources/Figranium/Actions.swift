import Foundation

public func variable(_ name: String) -> String { precondition(!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Variable name must not be empty"); return "{$\(name)}" }

public enum Actions {
    public static func action(_ value: Action) -> Action { var copy = value; if copy.id == nil { copy.id = "act_\(copy.type)_\(UUID().uuidString.lowercased())" }; return copy }
    public static func navigate(_ url: String) -> Action { action(.init(type: "navigate", value: url)) }
    public static func click(_ selector: String, kind: String = "single") -> Action { action(.init(type: "click", selector: selector, clickType: kind == "single" ? nil : kind)) }
    public static func check(_ selector: String) -> Action { action(.init(type: "check", selector: selector)) }
    public static func uncheck(_ selector: String) -> Action { action(.init(type: "uncheck", selector: selector)) }
    public static func dragAndDrop(_ selector: String, to target: String) -> Action { action(.init(type: "drag_and_drop", selector: selector, targetSelector: target)) }
    public static func reload() -> Action { action(.init(type: "reload")) }
    public static func select(_ selector: String, value: String) -> Action { action(.init(type: "select", selector: selector, value: value)) }
    public static func type(_ selector: String, value: String, mode: String = "replace") -> Action { action(.init(type: "type", selector: selector, value: value, typeMode: mode)) }
    public static func wait(_ seconds: Double) -> Action { action(.init(type: "wait", value: String(seconds))) }
    public static func waitFor(_ selector: String) -> Action { action(.init(type: "wait_selector", selector: selector)) }
    public static func waitForDownloads(_ timeout: Double? = nil) -> Action { action(.init(type: "wait_downloads", value: timeout.map { String($0) })) }
    public static func press(_ key: String, selector: String? = nil) -> Action { action(.init(type: "press", selector: selector, key: key)) }
    public static func scroll(selector: String? = nil, value: String? = nil) -> Action { action(.init(type: "scroll", selector: selector, value: value)) }
    public static func javascript(_ script: String, varName: String? = nil) -> Action { action(.init(type: "javascript", value: script, varName: varName)) }
    public static func csv(_ value: String? = nil, selector: String? = nil, varName: String? = nil) -> Action { action(.init(type: "csv", selector: selector, value: value, varName: varName)) }
    public static func hover(_ selector: String) -> Action { action(.init(type: "hover", selector: selector)) }
    public static func merge(_ name: String, value: String) -> Action { action(.init(type: "merge", value: value, varName: name)) }
    public static func screenshot(_ name: String? = nil) -> Action { action(.init(type: "screenshot", value: name)) }
    public static func conditional(_ type: String, selector: String? = nil, value: String? = nil, variable: String? = nil, variableType: String? = nil, operation: String? = nil, comparisonValue: String? = nil) -> Action { action(.init(type: type, selector: selector, value: value, conditionVar: variable, conditionVarType: variableType, conditionOp: operation, conditionValue: comparisonValue)) }
    public static func elseBlock() -> Action { action(.init(type: "else")) }; public static func end() -> Action { action(.init(type: "end")) }
    public static func `while`(selector: String? = nil, value: String? = nil, variable: String? = nil, variableType: String? = nil, operation: String? = nil, comparisonValue: String? = nil) -> Action { conditional("while", selector: selector, value: value, variable: variable, variableType: variableType, operation: operation, comparisonValue: comparisonValue) }
    public static func `if`(selector: String? = nil, value: String? = nil, variable: String? = nil, variableType: String? = nil, operation: String? = nil, comparisonValue: String? = nil) -> Action { conditional("if", selector: selector, value: value, variable: variable, variableType: variableType, operation: operation, comparisonValue: comparisonValue) }
    public static func repeatCount(_ count: Int) -> Action { action(.init(type: "repeat", value: String(count))) }
    public static func forEach(selector: String? = nil, value: String? = nil, varName: String? = nil) -> Action { action(.init(type: "foreach", selector: selector, value: value, varName: varName)) }
    public static func stop(_ outcome: String = "success") -> Action { action(.init(type: "stop", value: outcome)) }; public static func set(_ name: String, value: String) -> Action { action(.init(type: "set", value: value, varName: name)) }
    public static func onError(_ value: String? = nil) -> Action { action(.init(type: "on_error", value: value)) }; public static func doNothing() -> Action { action(.init(type: "do_nothing")) }; public static func start(_ taskId: String) -> Action { action(.init(type: "start", value: taskId)) }
    public static func request(_ url: String, method: String? = nil, headers: String? = nil, body: String? = nil, varName: String? = nil) -> Action { action(.init(type: "http_request", value: url, varName: varName, method: method, headers: headers, body: body)) }
    public static func getContent(selector: String? = nil, varName: String? = nil) -> Action { action(.init(type: "get_content", selector: selector, varName: varName)) }
    public static func captcha(_ type: String, captchaType: String? = nil, selector: String? = nil, varName: String? = nil, timeout: Double? = nil) -> Action { action(.init(type: type, selector: selector, varName: varName, captchaType: captchaType, timeout: timeout)) }
    public static func solveCaptcha(captchaType: String? = nil, selector: String? = nil, varName: String? = nil, timeout: Double? = nil) -> Action { captcha("solve_captcha", captchaType: captchaType, selector: selector, varName: varName, timeout: timeout) }
    public static func waitForCaptcha(captchaType: String? = nil, selector: String? = nil, varName: String? = nil, timeout: Double? = nil) -> Action { captcha("wait_captcha", captchaType: captchaType, selector: selector, varName: varName, timeout: timeout) }
    public static func upload(selector: String? = nil, cabinetId: String? = nil, markAsUploaded: Bool? = nil) -> Action { action(.init(type: "upload", selector: selector, cabinetId: cabinetId, markAsUploaded: markAsUploaded)) }
    public static func finalizeUploads() -> Action { action(.init(type: "finalize_uploads")) }
}
