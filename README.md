<div align="center">
  <img src="https://raw.githubusercontent.com/figranium/figranium-swift/main/banner.png" alt="Figranium Banner">
</div>

# Figranium Swift SDK

The official Swift client for [Figranium](https://github.com/figranium/figranium): invoke, define, schedule, and monitor browser automations from Apple and server-side Swift applications.

## Install

Add `https://github.com/figranium/figranium-swift.git` in Xcode, or add this package through Swift Package Manager. Then import `Figranium`.

## Define and run a task

```swift
import Figranium

let client = Figranium(apiKey: "YOUR_API_KEY")
let task = Task(
  name: "Search",
  url: "https://example.com",
  mode: "agent",
  actions: [
    Actions.waitFor("#search"),
    Actions.type("#search", value: variable("query")),
    Actions.press("Enter", selector: "#search"),
    Actions.getContent(selector: ".results", varName: "results")
  ]
)

let saved = try await client.tasks.save(task)
let result: ExecutionResult<JSONValue> = try await client.runTask(
  saved.id!, input: .init(variables: ["query": .string("Swift SDK")])
)
```

All calls use Swift concurrency. `executions.stream()` and `browser.selectorStream()` are `AsyncThrowingStream`s; `executions.watch(id:)` polls status and emits only changes.

## App Intents

On Apple platforms with App Intents, configure an app-owned client provider, then use `RunFigraniumTaskIntent`, `StopFigraniumExecutionIntent`, and `GetFigraniumExecutionStatusIntent` in Shortcuts and system experiences. Keep API keys in Keychain or another secure app-owned store; intents never accept credentials as parameters.

The core package has no dependencies. App Intents is conditionally compiled, so non-Apple Swift deployments use the client without it.
