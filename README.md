<div align="center">
  <img src="https://raw.githubusercontent.com/figranium/figranium-swift/main/banner.png" alt="Figranium Banner">

  <h1>Figranium Swift SDK</h1>

  <a href="https://swiftpackageindex.com/figranium/figranium-swift" target="_blank"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffigranium%2Ffigranium-swift%2Fbadge%3Ftype%3Dplatforms&style=for-the-badge" alt="Platforms"></a>
  <a href="https://swiftpackageindex.com/figranium/figranium-swift" target="_blank"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffigranium%2Ffigranium-swift%2Fbadge%3Ftype%3Dswift-versions&style=for-the-badge" alt="Swift versions"></a>

  <p><strong>Official Swift SDK for Figranium, the self-hosted browser automation and web-scraping platform.</strong></p>

  <p><a href="https://figranium.dev/docs/sdk/swift" target="_blank"><strong>Documentation</strong></a></p>
</div>

- Async/await-first API built on `URLSession`
- Code-defined Figranium tasks and action builders
- Codable request and response models
- API-key/session authentication, timeouts, structured errors, and SSE streams
- App Intents and Foundation Models integrations where supported
- No third-party runtime dependencies

## Requirements

- Swift 6.0+
- macOS 13+, iOS 16+, tvOS 16+, or watchOS 9+
- A running Figranium instance

App Intents are conditionally compiled. Foundation Models tools require iOS 26, macOS 26, or visionOS 26 plus a toolchain that provides its macro runtime.

## Install

In Xcode, choose **File → Add Package Dependencies** and paste:

```text
https://github.com/figranium/figranium-swift.git
```

Or add it with Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/figranium/figranium-swift.git", from: "0.2.0")
]
```

Add `Figranium` to your target dependencies, then import it:

```swift
import Figranium
```

## Quick start

```swift
let client = Figranium(
    baseURL: "http://localhost:11345",
    apiKey: "YOUR_FIGRANIUM_API_KEY"
)

let tasks = try await client.tasks.listSummaries()
let result: ExecutionResult<JSONValue> = try await client.runTask(
    tasks[0].id,
    input: .init(variables: ["query": .string("Swift SDK")])
)

print(result.data ?? .null)
print(result.outcome ?? "unknown") // success | error | stopped | crashed | anti_bot
```

`baseURL` defaults to `http://localhost:11345`. API keys use `Authorization: Bearer`; set `apiKeyHeader: "x-api-key"` for deployments that expect that header.

`tasks.listSummaries()` uses `/api/tasks/list` for API keys and `/api/tasks` for authenticated workspace sessions. Legacy AI selector/script-generation endpoints have been removed from Figranium and are not exposed by this SDK.

## Define a task in Swift

Tasks can be built in the visual editor and invoked by ID, or defined in Swift and versioned alongside your application.

```swift
let task = Task(
    name: "Search and extract",
    url: "https://example.com",
    mode: "agent",
    description: "Searches a page and captures visible results",
    actions: [
        Actions.waitFor("#search"),
        Actions.type("#search", value: variable("query")),
        Actions.press("Enter", selector: "#search"),
        Actions.waitFor(".results"),
        Actions.getContent(selector: ".results", varName: "resultText")
    ],
    variables: [
        "query": TaskVariable(type: "string", value: .string("figranium"))
    ]
)

let saved = try await client.tasks.save(task)
let result: ExecutionResult<JSONValue> = try await client.runTask(
    saved.id!,
    input: .init(variables: ["query": .string("browser automation")])
)
```

`variable("query")` creates Figranium’s `{$query}` template token. Action builders assign unique action IDs automatically.

For v0.21+ Tasks, select a named cookie state or explicitly request a fresh state:

```swift
var statefulTask = task
statefulTask.cookieStateId = .named("cookie-state-id") // reuse a saved state
statefulTask.cookieStateId = .fresh                  // send JSON null for a fresh state
// Leave cookieStateId nil to omit it and use the instance default.

statefulTask.output = TaskOutput(
    credentialId: "baserow-credential-id",
    tableId: "table-id",
    databaseId: "database-id",
    dedicated: true
)
```

The legacy `statelessExecution` option is deprecated. Scoped API keys must have the appropriate Task permissions and cannot bypass their Task allowlists.

## Action builders

`Actions` supports navigation, clicks, forms, extraction, control flow, HTTP, CAPTCHA handling, and cabinet uploads:

```swift
let actions: [Action] = [
    Actions.navigate("https://example.com"),
    Actions.click(".file-row", kind: "double"),
    Actions.check("#terms"),
    Actions.select("#language", value: "en"),
    Actions.dragAndDrop(".backlog-card", to: ".done-column"),
    Actions.reload(),
    Actions.waitForCaptcha(captchaType: "turnstile", selector: "#challenge", timeout: 120),
    Actions.solveCaptcha(captchaType: "turnstile", timeout: 120),
    Actions.screenshot("finished"),
    Actions.getContent(selector: ".results", varName: "results")
]
```

For advanced fields, construct `Action` directly. `Task`, `Action`, `Schedule`, `StealthConfig`, `TaskTranslation`, and their supporting models are Codable and use Figranium API field names.

## Streams and execution watching

Execution events are `AsyncThrowingStream`s and stop when their consuming task is cancelled. The execution stream requires a workspace session and a run ID (`runID:`); an API key alone cannot open it.

```swift
for try await event in client.executions.stream(runID: "run-id") {
    print(event.event ?? "message", event.data)
}

for try await execution in client.executions.watch("execution-id") {
    print(execution.status ?? execution.outcome ?? "unknown")
}
```

Use `client.browser.selectorStream()` to consume headful browser selector-picking events.

`client.executions.list()` automatically selects the session endpoint for `.session` authentication and the `results:read` endpoint for API keys; `apiKeyRoute:` can override the choice. Recorded numeric HTTP statuses (such as 200) decode into `Execution.status` as strings for compatibility. Use `try await client.executions.getFullResult("execution-id")` to retrieve a retained complete result as `JSONValue`. API keys need `results:read` and access to that execution's Task.

## Error handling

All transport, timeout, response, and API failures are represented by `FigraniumError`.

```swift
do {
    let _: ExecutionResult<JSONValue> = try await client.runTask("missing-task")
} catch let error as FigraniumError {
    print(error.status)                 // HTTP status, or 0 for transport failures
    print(error.code ?? "")
    print(error.details ?? .null)
    print(error.requestID ?? "")
}
```

Override headers or the timeout for individual requests:

```swift
let tasks = try await client.tasks.list(
    options: .init(headers: ["x-client-name": "my-swift-app"], timeout: 60)
)
```

## Client resources

| Resource | Purpose |
| --- | --- |
| `tasks` | Save, update, delete, version, generate, and execute tasks |
| `cookieStates` | Session-only list/get/create/rename/update/delete named browser storage states |
| `executions` | List, inspect, stop, delete, clear, stream, and watch runs |
| `schedules` | Configure, describe, disable, and inspect schedules |
| `captures` | List/delete recordings and screenshots |
| `cabinets` | Manage intercepted downloads and other files |
| `execution` | Direct `scrape`, `agent`, and `headful` execution endpoints |
| `health` | Service health check |

Shortcuts are available at `client.runTask`, `client.scrape`, `client.agent`, and `client.headful`.

## Direct execution

Execute a one-off automation without first saving a reusable task:

```swift
let result: ExecutionResult<JSONValue> = try await client.scrape([
    "url": .string("https://example.com"),
    "selector": .string("main")
])
```

## Administration and authentication

Named cookie states are available through a workspace-authenticated `URLSession` and `authentication: .session`:

```swift
let client = Figranium(
    baseURL: URL(string: "https://figranium.example")!,
    authentication: .session,
    session: authenticatedURLSession // provide a session with workspace cookies
)
let states = try await client.cookieStates.list()
let _: JSONObject = try await client.cookieStates.create(
    name: "login",
    state: ["cookies": .array([]), "origins": .array([])]
)
```

The SDK does not perform interactive login or acquire workspace cookies. It adds a CSRF hint to session-authenticated mutations when no Origin or Referer is supplied. Scoped API keys cannot administer cookie states. Manage settings, scoped API keys, 1Password credentials, Baserow connections, imports/exports, and Cloud sign-in in the Figranium workspace UI. The Swift SDK does not expose a `settings` resource; Task-allowlisted keys cannot access unrelated global resources.

## App Intents and Shortcuts

Configure an app-owned provider at launch. Keep keys in Keychain or other secure app storage; intents never accept credentials as parameters.

```swift
struct FigraniumProvider: FigraniumIntentClientProvider {
    func client() throws -> Figranium {
        Figranium(baseURL: "https://figranium.example", apiKey: "YOUR_API_KEY")
    }
}

FigraniumIntentConfiguration.configure(FigraniumProvider())
```

The SDK provides `FigraniumTask`, `RunFigraniumTaskIntent`, `StopFigraniumExecutionIntent`, and `GetFigraniumExecutionStatusIntent` for Shortcuts, Siri, and related system experiences.

## Foundation Models tools

On iOS 26, macOS 26, and visionOS 26, `RunFigraniumTaskTool` lets a `LanguageModelSession` invoke only explicitly approved deterministic tasks.

```swift
let tool = RunFigraniumTaskTool(
    client: client,
    allowedTaskIDs: ["lookup-order", "check-inventory"]
)

// Pass `tool` to your LanguageModelSession configuration.
```

The allowlist prevents a model from creating arbitrary browser actions or accessing credentials.

## Development

Use the full Xcode toolchain for package tests:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
swift test
```

## License

Apache-2.0
