import Foundation

// MARK: - TrelloCustomField

/// A Custom Field definition on a board (`text`, `number`, `date`, `checkbox`,
/// or `list`). For `list`, `options` holds the allowed values.
public struct TrelloCustomField: Codable, Sendable, Identifiable {

    public let id: String
    public let name: String
    /// Field kind: `"text"`, `"number"`, `"date"`, `"checkbox"`, `"list"`.
    public let type: String
    public let options: [Option]?

    public init(id: String, name: String, type: String, options: [Option]? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.options = options
    }

    public struct Option: Codable, Sendable, Identifiable {
        public let id: String
        public let value: Value

        public init(id: String, value: Value) {
            self.id = id
            self.value = value
        }

        public struct Value: Codable, Sendable {
            public let text: String?
            public init(text: String?) { self.text = text }
        }
    }

    enum CodingKeys: String, CodingKey { case id, name, type, options }
}

// MARK: - TrelloCustomFieldItem

/// The value of a Custom Field *on a specific card*. For `list` fields the
/// selection is in `idValue` (an option id); otherwise it's in `value`.
public struct TrelloCustomFieldItem: Codable, Sendable {

    public let idCustomField: String
    public let idValue: String?
    public let value: Value?

    public init(idCustomField: String, idValue: String? = nil, value: Value? = nil) {
        self.idCustomField = idCustomField
        self.idValue = idValue
        self.value = value
    }

    /// Trello returns these as strings.
    public struct Value: Codable, Sendable {
        public let text: String?
        public let number: String?
        public let checked: String?
        public let date: String?

        public init(text: String? = nil, number: String? = nil, checked: String? = nil, date: String? = nil) {
            self.text = text
            self.number = number
            self.checked = checked
            self.date = date
        }
    }

    enum CodingKeys: String, CodingKey { case idCustomField, idValue, value }
}
