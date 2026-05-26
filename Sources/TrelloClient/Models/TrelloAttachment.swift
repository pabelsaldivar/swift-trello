import Foundation

// MARK: - TrelloAttachment

/// A file attached to a Trello card (`/1/cards/{id}/attachments`).
///
/// Trello attachments can be either:
/// - **Uploaded files** (`isUpload == true`) — `url` points to a Trello-hosted
///   resource that requires the same API auth (key + token) to download.
/// - **External URL references** (`isUpload == false`) — `url` is whatever
///   external resource was added; no auth needed.
public struct TrelloAttachment: Codable {
    public let id: String
    /// Filename or display name.
    public let name: String?
    /// Download URL.
    public let url: String?
    /// MIME type (e.g. "image/png"). Absent for URL-only attachments.
    public let mimeType: String?
    /// Size in bytes. Absent for URL-only attachments.
    public let bytes: Int?
    /// ISO 8601 creation date.
    public let date: String?
    /// Trello member ID of the uploader.
    public let idMember: String?
    /// True if the attachment is a file Trello hosts; false for external URLs.
    public let isUpload: Bool?

    public init(
        id: String,
        name: String? = nil,
        url: String? = nil,
        mimeType: String? = nil,
        bytes: Int? = nil,
        date: String? = nil,
        idMember: String? = nil,
        isUpload: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.mimeType = mimeType
        self.bytes = bytes
        self.date = date
        self.idMember = idMember
        self.isUpload = isUpload
    }
}
