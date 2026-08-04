import XCTest
@testable import TrelloClient

// MARK: - Campos que el prompt pedía y ningún tipo leía

/// `url_slug` llevaba tiempo en el prompt —con su regex y todo— sin que nadie
/// lo decodificara: llegaba y se evaporaba. Sobrevivía de casualidad porque el
/// prompt exige que `archivo_final` sea exactamente el mismo texto.
final class CamposRecuperadosTests: XCTestCase {

    func testUrlSlugSeDecodifica() throws {
        let json = Data("""
        { "platform": "blog_post", "platform_label": "Blog", "trello_title": "t",
          "archivo_final": "mi-post", "titulo": "T", "descripcion": "d",
          "hashtags": [], "resumen_descripcion": "r", "url_slug": "mi-post" }
        """.utf8)
        let c = try JSONDecoder().decode(GeneratedCard.self, from: json)
        XCTAssertEqual(c.urlSlug, "mi-post")
    }

    /// Y su ausencia no rompe nada: los JSON de antes siguen entrando.
    func testSinUrlSlugSigueDecodificando() throws {
        let json = Data("""
        { "platform": "x", "platform_label": "X", "trello_title": "t",
          "archivo_final": "a", "titulo": "T", "descripcion": "d",
          "hashtags": [], "resumen_descripcion": "r" }
        """.utf8)
        let c = try JSONDecoder().decode(GeneratedCard.self, from: json)
        XCTAssertNil(c.urlSlug)
    }

    /// El bloque `anuncios` viajaba en el mismo JSON y este tipo no lo conocía,
    /// así que el consumidor lo re-parseaba a mano: dos lectores del mismo
    /// contrato, que es como empiezan a discrepar.
    func testLosAnunciosSeDecodificanConElResto() throws {
        let json = Data("""
        { "id": "v", "archivo_base": "DTAV_v", "cards": [],
          "anuncios": [
            { "platform": "x", "platform_label": "X", "trello_title": "t",
              "archivo_final": "a", "titulo": "Estreno", "descripcion": "Hoy.",
              "hashtags": [], "resumen_descripcion": "r" }
          ] }
        """.utf8)
        let o = try JSONDecoder().decode(YouTubePromptOutput.self, from: json)
        XCTAssertEqual(o.anuncios.count, 1)
        XCTAssertEqual(o.anuncios[0].platform, "x")
    }

    func testSinAnunciosNoRompe() throws {
        let json = Data(#"{ "id": "v", "archivo_base": "DTAV_v", "cards": [] }"#.utf8)
        let o = try JSONDecoder().decode(YouTubePromptOutput.self, from: json)
        XCTAssertTrue(o.anuncios.isEmpty)
    }
}
