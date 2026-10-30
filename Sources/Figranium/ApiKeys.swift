import Foundation

/// Permissions accepted by Figranium v0.21 scoped API keys.
public enum ApiKeyPermission: String, Codable, Sendable, CaseIterable {
    case tasksRead = "tasks:read"
    case tasksRun = "tasks:run"
    case tasksManage = "tasks:manage"
}

/// A key's public metadata. The plaintext secret is returned only at creation.
public struct ScopedApiKey: Codable, Sendable {
    public let id: String
    public let name: String
    public let permissions: [ApiKeyPermission]
    /// An empty allowlist grants access to all Tasks.
    public let taskIds: [String]
    public let createdAt: String
    public let legacy: Bool?
}

public struct ApiKeyListResponse: Codable, Sendable {
    public let keys: [ScopedApiKey]
    /// May contain a sensitive legacy plaintext secret.
    public let legacySecret: String?
    public let permissions: [ApiKeyPermission]
}

public struct ApiKeyCreateInput: Codable, Sendable {
    public var permissions: [ApiKeyPermission]
    public var name: String?
    /// Omitted or empty grants access to all Tasks.
    public var taskIds: [String]?

    public init(permissions: [ApiKeyPermission], name: String? = nil, taskIds: [String]? = nil) {
        self.permissions = permissions
        self.name = name
        self.taskIds = taskIds
    }
}

public struct ApiKeyCreateResponse: Codable, Sendable {
    public let key: ScopedApiKey
    public let secret: String
}

public struct ApiKeyRenameResponse: Codable, Sendable {
    public let key: ScopedApiKey
}

public struct ApiKeyRevokeResponse: Codable, Sendable {
    public let ok: Bool
}

/// Session-only API-key management; never authorize with another API key.
public struct ApiKeysResource: Sendable {
    let client: Figranium

    private func requireSession() throws {
        guard case .session = client.authentication else {
            throw FigraniumError(message: "API key administration requires a workspace session", code: "SESSION_REQUIRED")
        }
    }

    public func list(options: RequestOptions = .init()) async throws -> ApiKeyListResponse {
        try requireSession()
        return try await client.request("GET", "/api/api-keys", options: options)
    }

    public func create(_ input: ApiKeyCreateInput, options: RequestOptions = .init()) async throws -> ApiKeyCreateResponse {
        try requireSession()
        return try await client.request("POST", "/api/api-keys", body: input, options: options)
    }

    public func rename(_ id: String, name: String, options: RequestOptions = .init()) async throws -> ApiKeyRenameResponse {
        try requireSession()
        return try await client.request("PATCH", "/api/api-keys/\(pathID(id))", body: ["name": name], options: options)
    }

    public func revoke(_ id: String, options: RequestOptions = .init()) async throws -> ApiKeyRevokeResponse {
        try requireSession()
        return try await client.request("DELETE", "/api/api-keys/\(pathID(id))", options: options)
    }
}

public extension Figranium {
    /// Workspace-session-only scoped API key administration (v0.21+).
    var apiKeys: ApiKeysResource { ApiKeysResource(client: self) }
}
