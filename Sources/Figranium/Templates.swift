import Foundation

/// v0.20 template catalog. Import tracking is separate from saving the task.
public struct TemplatesResource: Sendable {
    let client: Figranium

    /// Legacy unpaginated catalog.
    public func list(options: RequestOptions = .init()) async throws -> [JSONObject] {
        try await client.request("GET", "/api/templates", options: options)
    }

    /// Search the paginated catalog.
    public func search(limit: Int = 12, offset: Int = 0, sort: String = "popular",
                       category: String = "all", search: String = "",
                       options: RequestOptions = .init()) async throws -> TemplatePage {
        try await client.request("GET", "/api/templates",
            query: ["limit": String(limit), "offset": String(offset), "sort": sort,
                    "category": category, "search": search], options: options)
    }

    public func get(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject {
        try await client.request("GET", "/api/templates/\(pathID(id))", options: options)
    }

    /// Invoke after a successful local task import.
    public func recordImport(_ id: String, options: RequestOptions = .init()) async throws -> JSONObject {
        try await client.request("POST", "/api/templates/\(pathID(id))/import", options: options)
    }
}

public struct TemplatePage: Codable, Sendable {
    public let items: [JSONObject]
    public let total: Int
}

extension Figranium {
    public var templates: TemplatesResource { TemplatesResource(client: self) }
}
