import Foundation

/// Units, ranges, fractions and symbols in running prose: "25–36 kg" becomes
/// "25 to 36 kilograms", "< 33 °C" becomes "less than 33 degrees Celsius".
///
/// The same rule as the equation pass holds here: a reading needs something
/// that makes it unambiguous. A unit is read only straight after a number
/// ("5 m" yes, "m" no), except a slash compound whose halves are both units
/// ("m/s"). A range needs digits on both sides of an EN DASH, or a unit after
/// it — so "3-2 win" and "555-1234" are untouched. A comparison sign needs a
/// space and then a number, so "<3" and "a <= b" are untouched.
///
/// Why single capitals are not in the unit table: in "1200 W Main St" the W is
/// West, and "N", "S", "E", "A", "V", "L" collide the same way. "s" is out
/// because "1960 s" is a decade. Their multi-letter forms ("kW", "mV", "mA",
/// "mL") are in.
extension MathLexicon {

    /// A unit's two spoken forms.
    public struct Unit: Sendable, Equatable {
        public var singular: String
        public var plural: String
        public init(_ singular: String, _ plural: String) {
            self.singular = singular; self.plural = plural
        }
    }

    /// A vulgar fraction on its own ("one half") and after a whole number
    /// ("4 and a half").
    public struct Fraction: Sendable, Equatable {
        public var alone: String
        public var afterWhole: String
        public init(alone: String, afterWhole: String) {
            self.alone = alone; self.afterWhole = afterWhole
        }
    }

    static let englishUnits: [String: Unit] = [
        "mg": .init("milligram", "milligrams"), "g": .init("gram", "grams"),
        "kg": .init("kilogram", "kilograms"), "lb": .init("pound", "pounds"),
        "lbs": .init("pound", "pounds"), "oz": .init("ounce", "ounces"),
        "nm": .init("nanometer", "nanometers"), "μm": .init("micrometer", "micrometers"),
        "µm": .init("micrometer", "micrometers"), "mm": .init("millimeter", "millimeters"),
        "cm": .init("centimeter", "centimeters"), "m": .init("meter", "meters"),
        "km": .init("kilometer", "kilometers"), "ft": .init("foot", "feet"),
        "yd": .init("yard", "yards"), "mi": .init("mile", "miles"),
        "mL": .init("milliliter", "milliliters"), "ml": .init("milliliter", "milliliters"),
        "Hz": .init("hertz", "hertz"), "kHz": .init("kilohertz", "kilohertz"),
        "MHz": .init("megahertz", "megahertz"), "GHz": .init("gigahertz", "gigahertz"),
        "mW": .init("milliwatt", "milliwatts"), "kW": .init("kilowatt", "kilowatts"),
        "MW": .init("megawatt", "megawatts"), "kWh": .init("kilowatt hour", "kilowatt hours"),
        "mV": .init("millivolt", "millivolts"), "kV": .init("kilovolt", "kilovolts"),
        "mA": .init("milliamp", "milliamps"), "Pa": .init("pascal", "pascals"),
        "hPa": .init("hectopascal", "hectopascals"), "kPa": .init("kilopascal", "kilopascals"),
        "amu": .init("atomic mass unit", "atomic mass units"),
        "mol": .init("mole", "moles"), "mmol": .init("millimole", "millimoles"),
        "cal": .init("calorie", "calories"), "kcal": .init("kilocalorie", "kilocalories"),
        "ms": .init("millisecond", "milliseconds"), "min": .init("minute", "minutes"),
        "hr": .init("hour", "hours"),
        "°C": .init("degree Celsius", "degrees Celsius"),
        "°F": .init("degree Fahrenheit", "degrees Fahrenheit"),
        "°": .init("degree", "degrees"),
    ]

    /// Allowed only after a slash ("m/s", "km/h", "g/L"), where they cannot be
    /// a decade, a compass point or a grade.
    static let englishDenominatorUnits: [String: Unit] = [
        "s": .init("second", "seconds"), "h": .init("hour", "hours"),
        "L": .init("liter", "liters"),
    ]

    static let englishFractions: [Character: Fraction] = [
        "½": .init(alone: "one half", afterWhole: "and a half"),
        "¼": .init(alone: "one quarter", afterWhole: "and a quarter"),
        "¾": .init(alone: "three quarters", afterWhole: "and three quarters"),
        "⅓": .init(alone: "one third", afterWhole: "and a third"),
        "⅔": .init(alone: "two thirds", afterWhole: "and two thirds"),
        "⅛": .init(alone: "one eighth", afterWhole: "and an eighth"),
        "⅜": .init(alone: "three eighths", afterWhole: "and three eighths"),
        "⅝": .init(alone: "five eighths", afterWhole: "and five eighths"),
        "⅞": .init(alone: "seven eighths", afterWhole: "and seven eighths"),
    ]

    // MARK: - The pass

    func measures(_ text: String) -> String {
        var out = text
        out = numberWithUnit(out)
        out = slashUnits(out)
        out = numericRanges(out)
        out = fractions(out)
        out = dimensions(out)
        out = comparisons(out)
        out = greekLetters(out)
        return out
    }

    private func alternation(_ keys: [String]) -> String {
        keys.sorted { $0.count > $1.count }
            .map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
    }

    private func replacing(_ text: String, _ pattern: String,
                           _ spoken: (NSTextCheckingResult, NSString) -> String?) -> String {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return text }
        let ns = text as NSString
        var out = text
        for m in re.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            guard let s = spoken(m, ns) else { continue }
            out = (out as NSString).replacingCharacters(in: m.range, with: s)
        }
        return out
    }

    private func group(_ m: NSTextCheckingResult, _ i: Int, _ ns: NSString) -> String? {
        let r = m.range(at: i)
        return r.location == NSNotFound ? nil : ns.substring(with: r)
    }

    /// "4½" → "4 and a half", "½" → "one half", "12" → "12".
    private func spokenNumber(_ s: String) -> String {
        guard let last = s.last, let f = words.fractions[last] else { return s }
        let whole = String(s.dropLast())
        return whole.isEmpty ? f.alone : "\(whole) \(f.afterWhole)"
    }

    private var numberPattern: String {
        let fr = String(words.fractions.keys)
        return #"(?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d+)?[\#(fr)]?|[\#(fr)]"#
    }

    /// "25–36 kg" → "25 to 36 kilograms"; "9.8 m/s²" → "9.8 meters per second
    /// squared"; "20 m²" → "20 square meters"; "-5 °C" → "minus 5 degrees Celsius".
    func numberWithUnit(_ text: String) -> String {
        let units = alternation(Array(words.units.keys))
        let dens = alternation(Array(Set(words.units.keys).union(words.denominatorUnits.keys)))
        let num = numberPattern
        // Groups: 1 sign, 2 first number, 3 a unit repeated on the first
        // number ("45°–48°"), 4 second number, 5 unit, 6 its power, 7 the
        // denominator, 8 its power. `/` is refused after the match, so a
        // compound this table cannot read ("g/cm3") is left whole rather
        // than half-read as "grams/cm3".
        let pattern = #"(?<![\p{L}\p{N}$£€¥.,])([−-](?=\d))?(\#(num))(?:(?:\s?(\#(units)))?\s?[–-]\s?(\#(num)))?\s?(\#(units))([²³])?(?:/(\#(dens))([²³])?)?(?![\p{L}\p{N}/])"#
        return replacing(text, pattern) { m, ns in
            guard let first = group(m, 2, ns), let unitKey = group(m, 5, ns),
                  let unit = words.units[unitKey] else { return nil }
            if let repeated = group(m, 3, ns), repeated != unitKey { return nil }
            let sign = group(m, 1, ns) != nil ? "\(words.minus) " : ""
            let second = group(m, 4, ns)
            var amount = sign + spokenNumber(first)
            if let second { amount += " \(words.rangeTo) \(spokenNumber(second))" }
            let one = second == nil && sign.isEmpty && first == "1"
            var name = one ? unit.singular : unit.plural
            switch group(m, 6, ns) {
            case "²"?: name = "\(words.square) \(name)"
            case "³"?: name = "\(words.cubic) \(name)"
            default: break
            }
            if let denKey = group(m, 7, ns),
               let den = words.units[denKey] ?? words.denominatorUnits[denKey] {
                name += " \(words.per) \(den.singular)"
                switch group(m, 8, ns) {
                case "²"?: name += " \(words.squared)"
                case "³"?: name += " \(words.cubed)"
                default: break
                }
            }
            return "\(amount) \(name)"
        }
    }

    /// "The SI unit for velocity is m/s." → "meters per second". Both halves
    /// must be units; "and/or" and "A/B" are not.
    func slashUnits(_ text: String) -> String {
        let units = alternation(words.units.keys.filter { !$0.hasPrefix("°") })
        let dens = alternation(Set(words.units.keys).union(words.denominatorUnits.keys)
            .filter { !$0.hasPrefix("°") })
        let pattern = #"(?<![\p{L}\p{N}/])(\#(units))([²³])?/(\#(dens))([²³])?(?![\p{L}\p{N}/])"#
        return replacing(text, pattern) { m, ns in
            guard let a = group(m, 1, ns), let unit = words.units[a],
                  let b = group(m, 3, ns),
                  let den = words.units[b] ?? words.denominatorUnits[b] else { return nil }
            var name = unit.plural
            if group(m, 2, ns) == "²" { name = "\(words.square) \(name)" }
            if group(m, 2, ns) == "³" { name = "\(words.cubic) \(name)" }
            name += " \(words.per) \(den.singular)"
            if group(m, 4, ns) == "²" { name += " \(words.squared)" }
            if group(m, 4, ns) == "³" { name += " \(words.cubed)" }
            return name
        }
    }

    /// "(1792–1852)" → "(1792 to 1852)". EN DASH only: an ASCII hyphen between
    /// numbers is a score or a phone number as often as a range.
    func numericRanges(_ text: String) -> String {
        guard text.contains("–") else { return text }
        let num = numberPattern
        let pattern = #"(?<![\p{L}\p{N}.,])(\#(num))\s?–\s?(\#(num))(?![\p{L}\p{N}])"#
        return replacing(text, pattern) { m, ns in
            guard let a = group(m, 1, ns), let b = group(m, 2, ns) else { return nil }
            return "\(spokenNumber(a)) \(words.rangeTo) \(spokenNumber(b))"
        }
    }

    /// "4½ per cent" → "4 and a half per cent".
    func fractions(_ text: String) -> String {
        guard text.contains(where: { words.fractions[$0] != nil }) else { return text }
        let fr = String(words.fractions.keys)
        return replacing(text, #"(?<![\p{L}\p{N}.])(\d+)?([\#(fr)])(?![\p{N}])"#) { m, ns in
            guard let f = group(m, 2, ns) else { return nil }
            return spokenNumber((group(m, 1, ns) ?? "") + f)
        }
    }

    /// "4×4" → "4 by 4". Inside an equation × is "times", and the equation
    /// pass has already read it by the time this runs.
    func dimensions(_ text: String) -> String {
        guard text.contains("×") else { return text }
        return replacing(text, #"(?<=\d)\s?×\s?(?=\d)"#) { _, _ in " \(words.by) " }
    }

    /// "(< 33 °C)" → "(less than 33 degrees Celsius)". A space and then a
    /// number are both required: "<3" and "a <= b" stay as written.
    func comparisons(_ text: String) -> String {
        guard text.contains(where: { words.proseComparisons[$0] != nil }) else { return text }
        let signs = NSRegularExpression.escapedPattern(for: String(words.proseComparisons.keys))
        return replacing(text, #"(?<![\p{L}\p{N}<>=!])([\#(signs)])\s+(?=[−-]?\d)"#) { m, ns in
            guard let s = group(m, 1, ns), let c = s.first,
                  let word = words.proseComparisons[c] else { return nil }
            return "\(word) "
        }
    }

    /// "The wavelength λ" → "lambda"; "Δx" → "delta x". A lone Greek letter,
    /// or one followed by a single Latin letter. A Greek WORD ("σιρός") is
    /// left alone, and π is read everywhere by `alwaysMath`.
    func greekLetters(_ text: String) -> String {
        let greek = words.symbols.keys.filter { $0 != "π" && $0 != "∞" }
        guard text.contains(where: { greek.contains($0) }) else { return text }
        let set = NSRegularExpression.escapedPattern(for: String(greek))
        return replacing(text, #"(?<![\p{L}\p{N}])([\#(set)])([A-Za-z])?(?![\p{L}\p{N}])"#) { m, ns in
            guard let g = group(m, 1, ns)?.first, let name = words.symbols[g] else { return nil }
            if let latin = group(m, 2, ns) { return "\(name) \(latin)" }
            return name
        }
    }
}
