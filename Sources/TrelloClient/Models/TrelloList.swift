// MARK: - TrelloList

/// A Trello list (column) on a board.
public struct TrelloList: Codable {
    /// Trello list identifier.
    public let id: String
    /// Display name of the list.
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
