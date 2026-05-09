// MARK: - TrelloLabel

/// A label attached to a Trello card or defined on a board.
public struct TrelloLabel: Codable {
    /// Trello label identifier.
    public let id: String
    /// Display name of the label (e.g. `"Reel"`, `"Blog"`).
    public let name: String
    /// Color key as defined by Trello (e.g. `"green"`, `"blue"`).
    /// `nil` when the label has no color assigned.
    public let color: String?

    public init(id: String, name: String, color: String? = nil) {
        self.id = id
        self.name = name
        self.color = color
    }
}
