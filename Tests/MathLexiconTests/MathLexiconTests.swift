import XCTest
@testable import MathLexicon

/// Two tables. To contribute, add a row: a phrasing and what a person would
/// say, or a look-alike that must come back unchanged. A reading you add to
/// the first table should come with its nearest look-alike in the second.
final class MathLexiconTests: XCTestCase {

    let lexicon = MathLexicon.english

    /// Written → spoken. Each is checked inside a sentence as well as alone.
    static let phrasings: [(String, String)] = [
        ("E=mc^2", "E equals m c squared"),
        ("E = mc²", "E equals m c squared"),
        ("E=MC²", "E equals M C squared"),
        ("x^3", "x cubed"),
        ("x³", "x cubed"),
        ("a^n", "a to the power of n"),
        ("aⁿ", "a to the power of n"),
        ("2^10", "2 to the 10th power"),
        ("x^4", "x to the 4th power"),
        ("10^21", "10 to the 21st power"),
        ("10^12", "10 to the 12th power"),
        ("x^-1", "x to the power of minus 1"),
        ("10⁻³", "10 to the power of minus 3"),
        ("√2", "the square root of 2"),
        ("∛27", "the cube root of 27"),
        ("√(x+1)", "the square root of the quantity x plus 1"),
        ("F=ma", "F equals m a"),
        ("a²+b²=c²", "a squared plus b squared equals c squared"),
        ("c² = a² + b²", "c squared equals a squared plus b squared"),
        ("(a+b)²", "the quantity a plus b, squared"),
        ("PV=nRT", "P V equals n R T"),
        ("V=IR", "V equals I R"),
        ("I=V/R", "I equals V over R"),
        ("y = 2x + 1", "y equals 2 x plus 1"),
        ("x = -3", "x equals minus 3"),
        ("π ≈ 3.14", "pi is approximately 3.14"),
        ("A=πr²", "A equals pi r squared"),
        ("x ≠ 0", "x is not equal to 0"),
        ("0 ≤ x ≤ 1", "0 is less than or equal to x is less than or equal to 1"),
        ("n ≥ 2", "n is greater than or equal to 2"),
        ("e^(iπ)+1=0", "e to the power of i pi plus 1 equals 0"),
        ("sin(x)^2", "sine of x squared"),
        ("x₁ = 2", "x 1 equals 2"),
    ]

    /// Always-math symbols, read wherever they appear.
    static let symbols: [(String, String)] = [
        ("π", "pi"),
        ("2π", "2 pi"),
        ("H₂O", "H 2 O"),
        ("CO₂ levels", "CO 2 levels"),
        ("The ratio is π times the radius squared.", "The ratio is pi times the radius squared."),
    ]

    /// Must come back byte-for-byte unchanged.
    static let lookAlikes: [String] = [
        "3-2 win",
        "C++",
        "e-mail",
        "A=B testing",
        "X-ray",
        "Wi-Fi",
        "a+b",
        "x < y",
        "20 m²",
        "9.8 m/s²",
        "5 km² of forest",
        "kg·m²",
        "^_^",
        "key=value",
        "width=100",
        "5=best",
        "rating = 5",
        "https://example.com/search?q=a&x=1",
        "$x=5",
        "x == y",
        "a <= b",
        "a != b",
        "x += 1",
        "a => b",
        "[^1]",
        "Ohio¹",
        "cost=5",
        "The score was 3 - 2 at half time.",
        "Call 555-1234 now.",
        "Route 66 = the Mother Road",
        "WWII",
        "221B Baker Street",
        "It's 7:15.",
        "= Heading =",
    ]

    func testPhrasingsAlone() {
        for (written, spoken) in Self.phrasings {
            XCTAssertEqual(lexicon.speakable(written), spoken, "alone: \(written)")
        }
    }

    func testPhrasingsInsideASentence() {
        for (written, spoken) in Self.phrasings {
            XCTAssertEqual(lexicon.speakable("Remember \(written), always."),
                           "Remember \(spoken), always.", "in a sentence: \(written)")
            XCTAssertEqual(lexicon.speakable("The answer is \(written)."),
                           "The answer is \(spoken).", "before a full stop: \(written)")
        }
    }

    func testSymbols() {
        for (written, spoken) in Self.symbols {
            XCTAssertEqual(lexicon.speakable(written), spoken, "symbol: \(written)")
        }
    }

    func testLookAlikesAreUntouched() {
        for text in Self.lookAlikes {
            XCTAssertEqual(lexicon.speakable(text), text, "changed a look-alike: \(text)")
        }
    }

    /// The pairing the scope rule rests on: the same characters, read once as
    /// math and once left as prose, decided by the trigger and not by luck.
    func testTheTriggerDecides() {
        XCTAssertEqual(lexicon.speakable("a+b=c"), "a plus b equals c")
        XCTAssertEqual(lexicon.speakable("a+b"), "a+b")
        XCTAssertEqual(lexicon.speakable("F=ma"), "F equals m a")
        XCTAssertEqual(lexicon.speakable("A=B"), "A=B")
        XCTAssertEqual(lexicon.speakable("x²"), "x squared")
        XCTAssertEqual(lexicon.speakable("m²"), "m²")
    }

    func testReadingReturnsNilForProse() {
        XCTAssertEqual(lexicon.reading("a^n"), "a to the power of n")
        XCTAssertNil(lexicon.reading("C++"))
        XCTAssertNil(lexicon.reading("hello"))
        XCTAssertNil(lexicon.reading(""))
    }

    func testSeveralEquationsInOneText() {
        XCTAssertEqual(
            lexicon.speakable("First F=ma, then E=mc², and finally a²+b²=c²."),
            "First F equals m a, then E equals m c squared, and finally a squared plus b squared equals c squared.")
    }

    func testTheVocabularyIsReplaceable() {
        var words = MathLexicon.Words.english
        words.equals = "égale"
        words.squared = "au carré"
        let french = MathLexicon(words: words)
        XCTAssertEqual(french.speakable("E=mc²"), "E égale m c au carré")
    }
}
