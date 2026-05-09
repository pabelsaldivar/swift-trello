// MARK: - TrelloCard

/// A Trello card as returned by the API.
///
/// All properties are optional except `id` and `name` because the API can
/// omit fields depending on the request scope.
public struct TrelloCard: Codable {
    /// Trello card identifier.
    public let id: String
    /// Card title.
    public let name: String
    /// Card description body (may be empty string, never `nil` from the API).
    public let desc: String?
    /// Short URL of the card.
    public let shortUrl: String?
    /// Full URL of the card.
    public let url: String?
    /// ISO 8601 due date string (e.g. `"2026-04-15T19:30:00.000Z"`).
    public let due: String?
    /// Identifier of the list this card belongs to.
    public let idList: String?
    /// Labels attached to the card.
    public let labels: [TrelloLabel]?

    public init(
        id: String,
        name: String,
        desc: String? = nil,
        shortUrl: String? = nil,
        url: String? = nil,
        due: String? = nil,
        idList: String? = nil,
        labels: [TrelloLabel]? = nil
    ) {
        self.id = id
        self.name = name
        self.desc = desc
        self.shortUrl = shortUrl
        self.url = url
        self.due = due
        self.idList = idList
        self.labels = labels
    }
}
