// MARK: - TrelloComment

/// A comment action returned by the Trello API (`/1/cards/{id}/actions?filter=commentCard`).
public struct TrelloComment: Decodable {
    /// Action identifier.
    public let id: String
    /// Comment body text.
    public let text: String
    /// ISO 8601 creation date.
    public let date: String

    enum CodingKeys: String, CodingKey {
        case id
        case data
        case date
    }

    private enum DataKeys: String, CodingKey {
        case text
    }

    public init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        id   = try container.decode(String.self, forKey: .id)
        date = try container.decode(String.self, forKey: .date)
        let data = try container.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        text = try data.decode(String.self, forKey: .text)
    }

    public init(id: String, text: String, date: String) {
        self.id   = id
        self.text = text
        self.date = date
    }
}
