import Foundation

// MARK: - TrelloAPIError

/// Typed errors thrown by `TrelloAPIClient`.
///
/// Every case includes enough context to produce a human-readable log message
/// via the Spanish-language `errorDescription`.
public enum TrelloAPIError: Error, LocalizedError {
    /// The path could not be composed into a valid `URL`.
    case invalidURL(path: String)
    /// The server returned a non-2xx HTTP status code.
    case httpError(statusCode: Int, body: String)
    /// The response contained no data.
    case noData
    /// `JSONDecoder` failed to parse the response body.
    case decodingError(underlying: Error)
    /// `apiKey` or `apiToken` is empty or a placeholder value.
    case missingCredentials

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let path):
            return "URL inválida para el path: \(path)"
        case .httpError(let code, let body):
            return "HTTP \(code): \(body)"
        case .noData:
            return "La respuesta no contiene datos"
        case .decodingError(let error):
            return "Error de decodificación: \(error.localizedDescription)"
        case .missingCredentials:
            return "Faltan credenciales de Trello (apiKey / apiToken)"
        }
    }
}
