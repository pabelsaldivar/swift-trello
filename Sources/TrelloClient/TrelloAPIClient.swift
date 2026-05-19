import Foundation

// MARK: - TrelloMember

/// Minimal member model used for authentication verification.
public struct TrelloMember: Codable {
    public let id: String
    public let fullName: String?
    public let username: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "fullName"
        case username
    }
}

// MARK: - TrelloAPIClient

/// Thread-safe Trello REST API client.
///
/// Declared as an `actor` to guarantee mutual exclusion on the shared URL session.
/// All methods are `async throws` — callers must handle `TrelloAPIError`.
///
/// Usage:
/// ```swift
/// let client = TrelloAPIClient(apiKey: "...", apiToken: "...")
/// let cards  = try await client.fetchCards(listId: "...")
/// ```
public actor TrelloAPIClient {

    // MARK: Private state

    private let apiKey: String
    private let apiToken: String
    private let session: URLSession

    private static let baseURL = "https://api.trello.com"

    // MARK: Init

    /// Creates a new client.
    ///
    /// - Parameters:
    ///   - apiKey: Trello API key.
    ///   - apiToken: Trello user token.
    ///   - session: `URLSession` to use for requests. Defaults to `.shared`.
    public init(
        apiKey: String,
        apiToken: String,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.apiToken = apiToken
        self.session = session
    }

    // MARK: Authentication

    /// Verifies credentials by fetching the authenticated member profile.
    ///
    /// - Throws: `TrelloAPIError.missingCredentials` when credentials are empty.
    /// - Returns: The authenticated `TrelloMember`.
    public func fetchCurrentMember() async throws -> TrelloMember {
        try validateCredentials()
        let url = try makeURL(path: "/1/members/me")
        return try await get(url: url)
    }

    // MARK: Boards

    /// Fetches all boards accessible to the authenticated member.
    public func fetchBoards() async throws -> [TrelloBoard] {
        try validateCredentials()
        let url = try makeURL(path: "/1/members/me/boards")
        return try await get(url: url)
    }

    // MARK: Lists

    /// Fetches all lists on a board.
    ///
    /// - Parameter boardId: Trello board identifier.
    public func fetchLists(boardId: String) async throws -> [TrelloList] {
        try validateCredentials()
        let url = try makeURL(path: "/1/boards/\(boardId)/lists")
        return try await get(url: url)
    }

    // MARK: Labels

    /// Fetches all labels defined on a board.
    ///
    /// - Parameter boardId: Trello board identifier.
    public func fetchLabels(boardId: String) async throws -> [TrelloLabel] {
        try validateCredentials()
        let url = try makeURL(path: "/1/boards/\(boardId)/labels")
        return try await get(url: url)
    }

    /// Creates a new label on a board.
    ///
    /// - Parameters:
    ///   - boardId: Trello board identifier.
    ///   - name: Display name of the label (e.g. `"Reel"`, `"Blog"`).
    ///   - color: Optional Trello color key (e.g. `"green"`, `"blue"`).
    ///             Pass `nil` to create the label with no color.
    /// - Returns: The newly created `TrelloLabel`.
    public func createLabel(boardId: String, name: String, color: String? = nil) async throws -> TrelloLabel {
        try validateCredentials()
        let url = try makeURL(path: "/1/boards/\(boardId)/labels")
        var params: [String: String] = ["name": name]
        if let color { params["color"] = color }
        return try await postWithFormBody(url: url, params: params)
    }

    // MARK: Cards — reads

    /// Fetches all cards in a list.
    ///
    /// - Parameter listId: Trello list identifier.
    public func fetchCards(listId: String) async throws -> [TrelloCard] {
        try validateCredentials()
        let url = try makeURL(path: "/1/lists/\(listId)/cards")
        return try await get(url: url)
    }

    // MARK: Cards — writes

    /// Creates a new card and returns its Trello identifier.
    ///
    /// - Parameter payload: Card creation parameters.
    /// - Returns: The newly created `TrelloCard` (includes `id`, `shortUrl`, etc.).
    public func createCard(_ payload: TrelloCardPayload) async throws -> TrelloCard {
        try validateCredentials()

        // Short identifiers and parameters travel in the URL as before.
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "idList", value: payload.idList),
        ]

        if let pos = payload.position {
            queryItems.append(URLQueryItem(name: "pos", value: pos))
        }

        if !payload.labelIds.isEmpty {
            queryItems.append(
                URLQueryItem(name: "idLabels", value: payload.labelIds.joined(separator: ","))
            )
        }

        let url = try makeURL(path: "/1/cards", queryItems: queryItems)

        // Potentially long fields (`name`, `desc`) travel in the form-encoded
        // body so we never trigger HTTP 414 (URI Too Long) when the description
        // approaches Trello's 16 KB limit.
        let bodyParams: [String: String] = [
            "name": payload.name,
            "desc": payload.desc,
        ]
        return try await postWithFormBody(url: url, params: bodyParams)
    }

    /// Updates one or more fields of an existing card.
    ///
    /// Only non-`nil` fields in `update` are included in the request body.
    /// The `due` field accepts either a date string or `.clear` to remove the date.
    ///
    /// - Parameters:
    ///   - cardId: Trello card identifier.
    ///   - update: Fields to update.
    public func updateCard(cardId: String, update: TrelloCardUpdate) async throws {
        try validateCredentials()

        // Short fields stay in the URL as before.
        var queryItems: [URLQueryItem] = []

        if let due = update.due {
            switch due {
            case .date(let iso):
                queryItems.append(URLQueryItem(name: "due", value: iso))
            case .clear:
                queryItems.append(URLQueryItem(name: "due", value: "null"))
            }
        }

        if let listId = update.idList {
            queryItems.append(URLQueryItem(name: "idList", value: listId))
        }

        // Potentially long fields (`name`) travel in the form-encoded body to
        // avoid HTTP 414 when card titles include long IDs / timestamps.
        var bodyParams: [String: String] = [:]
        if let name = update.name {
            bodyParams["name"] = name
        }
        if let desc = update.desc {
            bodyParams["desc"] = desc
        }

        // Nothing to update.
        if queryItems.isEmpty && bodyParams.isEmpty { return }

        let url = try makeURL(path: "/1/cards/\(cardId)", queryItems: queryItems)
        if bodyParams.isEmpty {
            try await put(url: url)
        } else {
            try await putWithFormBody(url: url, params: bodyParams)
        }
    }

    /// Moves a card to a different list.
    ///
    /// - Parameters:
    ///   - cardId: Trello card identifier.
    ///   - targetListId: Identifier of the destination list.
    public func moveCard(cardId: String, toListId targetListId: String) async throws {
        try await updateCard(cardId: cardId, update: TrelloCardUpdate(idList: targetListId))
    }

    /// Adds a new comment to an existing card.
    ///
    /// - Parameters:
    ///   - cardId: Trello card identifier.
    ///   - text: Full comment body in Markdown/plain text.
    public func addComment(cardId: String, text: String) async throws {
        try validateCredentials()

        let url = try makeURL(
            path: "/1/cards/\(cardId)/actions/comments",
            queryItems: [URLQueryItem(name: "text", value: text)]
        )
        try await post(url: url)
    }

    /// Adds an existing label to a card.
    ///
    /// - Parameters:
    ///   - cardId: Trello card identifier.
    ///   - labelId: Trello label identifier to attach.
    public func addLabelToCard(cardId: String, labelId: String) async throws {
        try validateCredentials()

        let url = try makeURL(
            path: "/1/cards/\(cardId)/idLabels",
            queryItems: [URLQueryItem(name: "value", value: labelId)]
        )
        try await post(url: url)
    }

    /// Removes a label from a card.
    ///
    /// - Parameters:
    ///   - cardId: Trello card identifier.
    ///   - labelId: Trello label identifier to detach.
    public func removeLabelFromCard(cardId: String, labelId: String) async throws {
        try validateCredentials()
        let url = try makeURL(path: "/1/cards/\(cardId)/idLabels/\(labelId)")
        try await delete(url: url)
    }

    /// Fetches comments (actions of type `commentCard`) for a card.
    ///
    /// - Parameter cardId: Trello card identifier.
    /// - Returns: Array of `TrelloComment` in reverse-chronological order.
    public func fetchComments(cardId: String) async throws -> [TrelloComment] {
        try validateCredentials()
        let url = try makeURL(
            path: "/1/cards/\(cardId)/actions",
            queryItems: [URLQueryItem(name: "filter", value: "commentCard")]
        )
        return try await get(url: url)
    }
}

// MARK: - Private networking helpers

private extension TrelloAPIClient {

    /// Validates that credentials are non-empty before making any request.
    func validateCredentials() throws {
        guard !apiKey.isPlaceholderOrEmpty, !apiToken.isPlaceholderOrEmpty else {
            throw TrelloAPIError.missingCredentials
        }
    }

    /// Builds an authenticated Trello API URL.
    ///
    /// - Parameters:
    ///   - path: API path (e.g. `"/1/cards"`).
    ///   - queryItems: Additional query parameters.
    /// - Throws: `TrelloAPIError.invalidURL` when the URL cannot be constructed.
    func makeURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        var components = URLComponents(string: Self.baseURL + path)
        var items = queryItems
        items.append(URLQueryItem(name: "key",   value: apiKey))
        items.append(URLQueryItem(name: "token", value: apiToken))
        components?.queryItems = items

        guard let url = components?.url else {
            throw TrelloAPIError.invalidURL(path: path)
        }
        return url
    }

    // MARK: Generic HTTP verbs

    /// Performs a `GET` request and decodes the response into `T`.
    func get<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        try validate(response: response, data: data)
        return try decode(T.self, from: data)
    }

    /// Performs a `POST` request and decodes the response into `T`.
    func post<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try decode(T.self, from: data)
    }

    /// Performs a `POST` request when the response body is not needed.
    func post(url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
    }

    /// Performs a `POST` request with form-encoded body parameters and decodes
    /// the response into `T`.
    ///
    /// Use this for endpoints whose payload may be large (e.g. card `desc`
    /// approaching Trello's 16 KB limit) — keeping the URL short avoids
    /// HTTP 414 (URI Too Long) responses from intermediate proxies.
    func postWithFormBody<T: Decodable>(url: URL, params: [String: String]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formEncode(params)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try decode(T.self, from: data)
    }

    /// Performs a `PUT` request with form-encoded body parameters (no response
    /// body expected). Mirrors `postWithFormBody` for endpoints that update
    /// long fields like `name`.
    func putWithFormBody(url: URL, params: [String: String]) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formEncode(params)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
    }

    /// Form-encodes a parameter dictionary using `URLComponents` so the encoding
    /// is consistent with what the rest of the SDK does for query strings.
    private static func formEncode(_ params: [String: String]) -> Data? {
        var components = URLComponents()
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.percentEncodedQuery?.data(using: .utf8)
    }

    /// Performs a `PUT` request (no response body expected).
    func put(url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
    }

    /// Performs a `DELETE` request (no response body expected).
    func delete(url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
    }

    // MARK: Response helpers

    func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TrelloAPIError.httpError(statusCode: http.statusCode, body: body)
        }
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw TrelloAPIError.decodingError(underlying: error)
        }
    }
}

// MARK: - String helper (file-private)

private extension String {
    var isPlaceholderOrEmpty: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hasPrefix("PEGA_AQUI")
    }
}
