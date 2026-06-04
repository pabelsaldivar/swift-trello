import Foundation

// MARK: - TrelloAttachment

/// An attachment on a Trello card (uploaded file or linked URL).
public struct TrelloAttachment: Codable, Sendable, Identifiable {

    public let id: String
    public let name: String?
    /// Public URL of the attachment (for linked URLs, or the hosted file).
    public let url: String?
    public let mimeType: String?
    /// `true` when the attachment is an uploaded file (vs a linked URL).
    public let isUpload: Bool?
    public let bytes: Int?

    public init(
        id: String,
        name: String? = nil,
        url: String? = nil,
        mimeType: String? = nil,
        isUpload: Bool? = nil,
        bytes: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.mimeType = mimeType
        self.isUpload = isUpload
        self.bytes = bytes
    }

    enum CodingKeys: String, CodingKey {
        case id, name, url, mimeType, isUpload, bytes
    }
}
