// MARK: - TrelloBoard

/// A Trello board.
public struct TrelloBoard: Codable {
    /// Trello board identifier.
    public let id: String
    /// Display name of the board.
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
