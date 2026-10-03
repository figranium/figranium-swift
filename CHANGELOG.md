# Changelog

All notable changes to Figranium Swift are documented in this file.

## [0.3.0] - 2026-10-03

### Added

- v0.20 Templates API resource for catalog listing, paginated search, template details and successful-import tracking.



## [0.2.0] - 2026-09-29

### Added

- Public DocC-compatible documentation comments across the SDK's public API.
- Swift Package Index metadata linking directly to the hosted Swift SDK documentation.

### Changed

- Pointed the README documentation link directly to the Swift SDK docs.
- Updated the Swift Package Manager installation example to the current release line.
- Adopted normal semantic version progression for releases: new functionality increments the minor version while patch releases are reserved for backwards-compatible fixes.

## [0.1.0] - 2026-09-27

First release of the official Figranium Swift SDK.

### Added

- Swift Package Manager library product and `Figranium` import module for macOS, iOS, tvOS, and watchOS.
- An async/await-first `Figranium` client with base URL configuration, API-key or session authentication, custom headers, request timeouts, and normalized `FigraniumError` failures.
- Codable JSON support through `JSONValue` and `JSONObject`, including typed core models for tasks, task variables, actions, schedules, executions, captures, cabinets, credentials, browser sessions, proxies, health, and users.
- Code-defined browser automation tasks with the complete current action builder set: navigation, clicks, form controls, typing, waits, downloads, scrolling, JavaScript, CSV, extraction, screenshots, conditions, loops, HTTP requests, CAPTCHA actions, cabinet uploads, and control-flow actions.
- Figranium template variables through `variable("name")`, producing the platform’s `{$name}` format.
- Resource clients for authentication, tasks, executions, schedules, captures and cookies, cabinets, credentials, browser and headful sessions, settings, direct execution endpoints, and service health.
- Task lifecycle operations including save, update, delete, version history, rollback, selector generation, script generation, and remote execution.
- Execution lifecycle operations including list, retrieve, stop, delete, clear, server-sent event streaming, and a cancellation-aware status watcher that emits changes as an `AsyncThrowingStream`.
- Server-sent event streams for execution activity and browser selector picking.
- Cabinet management, including item status changes, zipping, unzipping, clearing, removal, and download URL construction.
- Session-protected settings methods for API keys, user agents, AI models/providers, themes, and proxy configuration.
- Conditionally compiled App Intents integrations: `FigraniumTask`, Run Figranium Task, Stop Figranium Execution, and Get Figranium Execution Status.
- An app-owned intent-client provider configuration so Shortcuts and system integrations never receive API keys as intent parameters.
- A conditionally compiled Foundation Models `Tool` adapter for invoking only explicitly allowlisted Figranium tasks from `LanguageModelSession` workflows.
- README installation, configuration, code-defined-task, streaming, and Apple-platform integration guidance.
- Initial unit coverage for task JSON serialization, action generation, variable templates, and JSON value round-tripping.

### Changed

- Replaced the generated Swift package scaffold with the `Figranium` module and public SDK API.
- Lowered the package tools version from Swift 6.4 to Swift 6.0 so it builds with the available Swift/Xcode toolchains.
