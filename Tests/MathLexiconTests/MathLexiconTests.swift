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
        // Units and symbols: each is the nearest miss of a reading below.
        "1200 W Main St",
        "the 1960 s",
        "relative density 0.53724 g/cm3",
        // "$5 m" is money. A bare "5 m budget" DOES read as meters — known limit.
        "a $5 m budget",
        "<3",
        "and/or",
        "A/B testing",
        "The Greek σιρός means pit.",
        "kg·m²",
        "5 in the morning",
        "Call 555-1234",
    ]

    /// Units, ranges, fractions, × and comparison signs in prose — every
    /// written form here was taken from real reference text.
    static let measures: [(String, String)] = [
        ("25–36 kg (55–80 lb)", "25 to 36 kilograms (55 to 80 pounds)"),
        ("(< 33 °C)", "(less than 33 degrees Celsius)"),
        ("-5 °C", "minus 5 degrees Celsius"),
        ("45°–48°", "45 to 48 degrees"),
        ("1 kg (1000 g)", "1 kilogram (1000 grams)"),
        ("20 m²", "20 square meters"),
        ("5 km²", "5 square kilometers"),
        ("9.8 m/s²", "9.8 meters per second squared"),
        ("50 km/h", "50 kilometers per hour"),
        ("m/s", "meters per second"),
        ("1,200 km", "1,200 kilometers"),
        ("127 ft (38.7 m)", "127 feet (38.7 meters)"),
        ("0.1 to 5.0 μm", "0.1 to 5.0 micrometers"),
        ("500 nm", "500 nanometers"),
        ("18 amu", "18 atomic mass units"),
        ("110 kV", "110 kilovolts"),
        ("5 mL", "5 milliliters"),
        ("(1792–1852)", "(1792 to 1852)"),
        ("4½ per cent", "4 and a half per cent"),
        ("½ mile", "one half mile"),
        ("4×4", "4 by 4"),
        ("(> 600 nm)", "(more than 600 nanometers)"),
        ("≥ 18", "at least 18"),
        ("the wavelength λ", "the wavelength lambda"),
        ("the value of ΔH", "the value of delta H"),
        ("α- or β-adrenergic", "alpha- or beta-adrenergic"),
    ]

    /// Pre-decimal money, verbatim from the Holmes stories, as whole sentences
    /// because the full stop is part of the notation.
    static let oldMoney: [(String, String)] = [
        ("Twenty-four geese at 7s. 6d.’”", "Twenty-four geese at 7 shillings and 6 pence.’”"),
        ("My gross takings amount to £ 27 10s. Every day, from nine",
         "My gross takings amount to 27 pounds 10 shillings. Every day, from nine"),
        ("amount to £ 88 10s., while he has £ 220 standing",
         "amount to 88 pounds 10 shillings, while he has £ 220 standing"),
        ("I had received no less than 26s. 4d.", "I had received no less than 26 shillings and 4 pence."),
        ("rooms 8s., breakfast 2s. 6d., cocktail 1s., lunch 2s. 6d., glass sherry, 8d.’ I see",
         "rooms 8 shillings, breakfast 2 shillings and 6 pence, cocktail 1 shilling, lunch 2 shillings and 6 pence, glass sherry, 8 pence.’ I see"),
        ("of the Alpha, at 12s.’”", "of the Alpha, at 12 shillings.’”"),
        ("to return cheque £1 17s. 9d, amount of overplus",
         "to return cheque 1 pound 17 shillings and 9 pence, amount of overplus"),
    ]

    /// The nearest things to old money that are not.
    static let oldMoneyLookAlikes: [String] = [
        "£10 Reward.",
        "not less than £ 1000 a year",
        "in her 20s.",
        "the 1960s.",
        "It happened in the 60s.",
        "Boeing 747s.",
        "B-52s.",
        "from 10−35 to about 10−32s.",
        "a 3D print",
        "the 12d. pence rule",
        "his 2nd. attempt",
        "5s.o.s",
    ]

    /// Verbatim from the geography packs.
    static let coordinates: [(String, String)] = [
        ("is located at 39°50′N 98°35′W, about 2.6 miles",
         "is located at 39 degrees 50 minutes north 98 degrees 35 minutes west, about 2.6 miles"),
        ("South Dakota at 44°58′2.08″N 103°46′17.60″W.",
         "South Dakota at 44 degrees 58 minutes 2.08 seconds north 103 degrees 46 minutes 17.60 seconds west."),
        ("from each island at 168°58′37″ W.", "from each island at 168 degrees 58 minutes 37 seconds west."),
        ("on the meridian at 71°32′N 180°0′E, also", "on the meridian at 71 degrees 32 minutes north 180 degrees 0 minutes east, also"),
    ]

    func testCoordinates() {
        for (written, spoken) in Self.coordinates {
            XCTAssertEqual(lexicon.speakable(written), spoken, written)
        }
        // The nearest look-alikes: a plain angle, a height, a range of degrees.
        XCTAssertEqual(lexicon.speakable("a 45° angle"), "a 45 degrees angle")
        XCTAssertEqual(lexicon.speakable("He was 5′ 10″ tall"), "He was 5′ 10″ tall")
        XCTAssertEqual(lexicon.speakable("45°–48°"), "45 to 48 degrees")
    }

    func testOldMoney() {
        for (written, spoken) in Self.oldMoney {
            XCTAssertEqual(lexicon.speakable(written), spoken, written)
        }
    }

    func testOldMoneyLookAlikesAreUntouched() {
        for text in Self.oldMoneyLookAlikes {
            XCTAssertEqual(lexicon.speakable(text), text, "changed a look-alike: \(text)")
        }
    }

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

    func testMeasures() {
        for (written, spoken) in Self.measures {
            XCTAssertEqual(lexicon.speakable(written), spoken, "alone: \(written)")
            XCTAssertEqual(lexicon.speakable("We saw \(written) there."),
                           "We saw \(spoken) there.", "in a sentence: \(written)")
        }
    }

    /// A range whose two ends carry DIFFERENT units is not a range this pass
    /// can read, and is left whole rather than half-read. Known gap.
    func testMixedUnitRangeIsLeftAlone() {
        XCTAssertEqual(lexicon.speakable("from 5 m–10 cm"), "from 5 m–10 cm")
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
