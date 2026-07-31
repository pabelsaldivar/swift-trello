import XCTest
@testable import TrelloClient

/// The shape of the `multipart/form-data` body used to upload attachments.
///
/// This is tested rather than eyeballed because one detail is a correctness
/// requirement and not a style choice: **text fields must precede the file
/// part**. Trello parses a text field placed after the binary payload
/// inconsistently, and when it loses `setCover` the flag silently does nothing —
/// the upload succeeds, so nothing looks wrong until the card shows the wrong
/// image on its front.
final class MultipartBodyTests: XCTestCase {

    private let boundary = "Boundary-TEST"

    private func body(_ extra: [String: String] = [:]) -> String {
        let data = TrelloAPIClient.multipartBody(
            boundary: boundary,
            fieldName: "file",
            filename: "foto.jpg",
            mimeType: "image/jpeg",
            fileData: Data([0xFF, 0xD8, 0xFF]),
            extraFields: extra
        )
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - Orden

    func testTextFieldsComeBeforeTheFilePart() throws {
        let s = body(["setCover": "false"])
        let campo = try XCTUnwrap(s.range(of: "name=\"setCover\""))
        let archivo = try XCTUnwrap(s.range(of: "filename=\"foto.jpg\""))
        XCTAssertLessThan(campo.lowerBound, archivo.lowerBound,
                          "setCover después del binario se pierde y la portada queda mal")
    }

    /// Deterministic ordering — otherwise the body differs run to run and this
    /// suite could pass or fail by dictionary luck.
    func testExtraFieldsAreSortedByName() throws {
        let s = body(["setCover": "false", "name": "foto.jpg"])
        let a = try XCTUnwrap(s.range(of: "name=\"name\""))
        let b = try XCTUnwrap(s.range(of: "name=\"setCover\""))
        XCTAssertLessThan(a.lowerBound, b.lowerBound)
    }

    // MARK: - Estructura

    func testWithoutExtraFieldsTheBodyIsUnchanged() {
        let s = body()
        XCTAssertTrue(s.hasPrefix("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"foto.jpg\""),
                      "Un upload sin campos extra debe salir byte a byte como antes")
        XCTAssertTrue(s.hasSuffix("\r\n--\(boundary)--\r\n"))
    }

    func testTheFilePartCarriesItsMimeType() {
        XCTAssertTrue(body().contains("Content-Type: image/jpeg\r\n\r\n"))
    }

    /// The bytes must survive verbatim: re-encoding an image would corrupt it.
    func testTheFileBytesAreNotAltered() {
        let bytes = Data([0xFF, 0xD8, 0xFF, 0x00, 0x0A, 0x0D])
        let data = TrelloAPIClient.multipartBody(
            boundary: boundary, fieldName: "file", filename: "a.jpg",
            mimeType: "image/jpeg", fileData: bytes
        )
        XCTAssertTrue(data.range(of: bytes) != nil, "El binario tiene que ir intacto")
    }

    /// Trello accepts UTF-8 filenames; escaping them would rename the attachment.
    func testAccentedFilenamesGoThroughVerbatim() {
        let data = TrelloAPIClient.multipartBody(
            boundary: boundary, fieldName: "file", filename: "atracción_ñ.jpg",
            mimeType: "image/jpeg", fileData: Data([0x1])
        )
        XCTAssertTrue(String(decoding: data, as: UTF8.self).contains("filename=\"atracción_ñ.jpg\""))
    }
}
