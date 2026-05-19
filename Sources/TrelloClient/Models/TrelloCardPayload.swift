// MARK: - TrelloCardPayload

/// Parameters for creating a new Trello card via `POST /1/cards`.
///
/// Trello API field names (`idList`, `idLabels`, `pos`) are mapped from these
/// Swift-idiomatic names inside `TrelloAPIClient.createCard(_:)`.
public struct TrelloCardPayload {
    /// Card title.
    public let name: String
    /// Card description body.
    public let desc: String
    /// Identifier of the target list.
    public let idList: String
    /// Card placement within the list. Defaults to `"bottom"`.
    public let position: String?
    /// Trello label IDs to attach to the card.
    public let labelIds: [String]

    public init(
        name: String,
        desc: String,
        idList: String,
        position: String? = "bottom",
        labelIds: [String] = []
    ) {
        self.name = name
        self.desc = desc
        self.idList = idList
        self.position = position
        self.labelIds = labelIds
    }
}

// MARK: - TrelloCardUpdate

/// Parameters for updating an existing Trello card via `PUT /1/cards/{id}`.
///
/// All fields are optional — only non-`nil` values are included in the request body.
public struct TrelloCardUpdate {
    /// New card title, or `nil` to leave it unchanged.
    public let name: String?
    /// New card description body, or `nil` to leave it unchanged.
    public let desc: String?
    /// Due date action: set a date or clear the existing one.
    /// Pass `nil` to leave the due date unchanged.
    public let due: TrelloDue?
    /// Target list identifier for moving the card, or `nil` to stay in place.
    public let idList: String?

    public init(
        name: String? = nil,
        desc: String? = nil,
        due: TrelloDue? = nil,
        idList: String? = nil
    ) {
        self.name = name
        self.desc = desc
        self.due = due
        self.idList = idList
    }
}

// MARK: - TrelloDue

/// Represents a due-date update for a Trello card.
public enum TrelloDue {
    /// Sets the card's due date to the given ISO 8601 string.
    case date(String)
    /// Removes the card's due date.
    case clear
}
