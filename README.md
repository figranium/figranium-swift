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
    .package(url: "https://github.com/figranium/figranium-swift.git", from: "0.1.0")
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

Execution events and selector picks are `AsyncThrowingStream`s and stop when their consuming task is cancelled.

```swift
for try await event in client.executions.stream() {
    print(event.event ?? "message", event.data)
}

for try await execution in client.executions.watch("execution-id") {
    print(execution.status ?? execution.outcome ?? "unknown")
}
```

Use `client.browser.selectorStream()` to consume headful browser selector-picking events.

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
| `executions` | List, inspect, stop, delete, clear, stream, and watch runs |
| `schedules` | Configure, describe, disable, and inspect schedules |
| `captures` | List/delete recordings and screenshots; manage cookies |
| `cabinets` | Manage intercepted downloads and other files |
| `credentials` | Manage output credentials and browse Baserow metadata |
| `browser` | Open sessions, highlight selectors, inspect headful sessions, and stream selector events |
| `execution` | Direct `scrape`, `agent`, and `headful` execution endpoints |
| `settings` | Session-protected keys, AI providers/models, themes, user agents, and proxies |
| `auth` | Setup, login, logout, and current-user methods |
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

## Session-only administration

Figranium’s settings endpoints require an authenticated user session rather than an API key:

```swift
let admin = Figranium(
    baseURL: "https://figranium.example",
    authentication: .session
)

let theme = try await admin.settings.getTheme()
```

Your app must supply and persist session cookies. API-key authentication is recommended for most native and server integrations.

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
