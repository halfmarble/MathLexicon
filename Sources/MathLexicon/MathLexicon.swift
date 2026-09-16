import Foundation

/// Reads written math aloud: `E=mc^2` becomes "E equals m c squared".
///
/// A speech engine given `E=mc²` either spells the symbols, skips them, or
/// reads "E M C two". This rewrites the expression into the words a person
/// would say, and leaves everything else exactly as it was.
///
/// **The scope is the whole design.** Only a span that is *clearly* an
/// equation is touched: it must contain one of `=` `^` `²` `³` `√` `≈` `≠`
/// `≤` `≥` with an operand on each side it needs, and the whole span must
/// parse. Anything that does not parse is returned unchanged. So "3-2 win",
/// "C++", "e-mail", "A=B testing", "20 m²" and "key=value" all pass through
/// untouched. Getting a formula wrong is recoverable; rewriting prose is not.
///
/// Two symbols are always math and are read wherever they appear: `π`
/// ("pi") and subscript digits (`H₂O` → "H 2 O").
///
/// Units, ranges, fractions, `×`, comparison signs and lone Greek letters in
/// prose have their own pass with the same rule — see `Measures.swift`.
///
///     MathLexicon.english.speakable("Einstein wrote E = mc².")
///     // "Einstein wrote E equals m c squared."
///
/// Numbers are left as digits ("the square root of 2"), because every speech
/// engine already reads digits and each app has its own rules for them.
public struct MathLexicon: Sendable {

    /// The spoken vocabulary. Replace it to read math in another language.
    public var words: Words

    public init(words: Words = .english) {
        self.words = words
    }

    /// The English reader.
    public static let english = MathLexicon()

    // MARK: - Public API

    /// `text` with every clearly-math span replaced by its reading.
    public func speakable(_ text: String) -> String {
        let chars = Array(text)
        var out = ""
        var cursor = 0
        for span in Self.candidateSpans(chars, words: words) {
            guard !Self.touchesNonMath(chars, span),
                  let spoken = reading(String(chars[span])) else { continue }
            out += String(chars[cursor..<span.lowerBound])
            out += spoken
            cursor = span.upperBound
        }
        out += String(chars[cursor...])
        return alwaysMath(measures(out))
    }

    /// The reading of one expression, or `nil` when it is not clearly math.
    ///
    ///     MathLexicon.english.reading("a^n")   // "a to the power of n"
    ///     MathLexicon.english.reading("C++")   // nil
    public func reading(_ expression: String) -> String? {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !Self.isUnitNotation(trimmed),
              let tokens = Self.lex(Array(trimmed), words: words),
              tokens.contains(where: \.isTrigger) else { return nil }
        var parser = Parser(tokens: tokens, words: words)
        guard let tree = parser.parseAll(), !Self.isLabel(tree) else { return nil }
        return read(tree)
    }

    // MARK: - Vocabulary

    /// Every word the reader says. All fields are public so a translation is
    /// a single value: `MathLexicon(words: .init(equals: "égale", ...))`.
    public struct Words: Sendable {
        public var equals: String
        public var approximately: String
        public var notEqual: String
        public var lessOrEqual: String
        public var greaterOrEqual: String
        public var less: String
        public var greater: String
        public var plus: String
        public var minus: String
        public var times: String
        public var over: String
        public var squared: String
        public var cubed: String
        /// "to the power of" — followed by the exponent's reading.
        public var toThePowerOf: String
        /// A whole-number exponent above 3: 4 → "to the 4th power".
        public var nthPower: @Sendable (Int) -> String
        public var squareRootOf: String
        public var cubeRootOf: String
        /// Introduces a parenthesised group: "the quantity a plus b, squared".
        public var theQuantity: String
        /// Symbol → spoken name: "π" → "pi", "θ" → "theta", "∞" → "infinity".
        public var symbols: [Character: String]
        /// Function name → spoken lead-in: "sin" → "sine of".
        public var functions: [String: String]

        // Units and symbols in prose (Measures.swift). Plain properties with
        // English defaults, so a translation overrides them by assignment.

        /// Unit symbol, CASE-SENSITIVE, read only right after a number.
        public var units: [String: Unit] = MathLexicon.englishUnits
        /// Units allowed only after a slash: "s" in "m/s", "h" in "km/h".
        public var denominatorUnits: [String: Unit] = MathLexicon.englishDenominatorUnits
        public var fractions: [Character: Fraction] = MathLexicon.englishFractions
        /// "25–36" → "25 to 36".
        public var rangeTo = "to"
        /// "4×4" → "4 by 4".
        public var by = "by"
        /// "m/s" → "meters per second".
        public var per = "per"
        /// "m²" → "square meters", "m³" → "cubic meters".
        public var square = "square"
        public var cubic = "cubic"
        /// A comparison sign before a number, in prose: "(< 33 °C)".
        public var proseComparisons: [Character: String] = [
            "<": "less than", ">": "more than", "≤": "at most", "≥": "at least"]
        /// Pre-decimal British money: "7s. 6d." → "7 shillings and 6 pence",
        /// "£ 88 10s." → "88 pounds 10 shillings".
        public var pound = Unit("pound", "pounds")
        public var shilling = Unit("shilling", "shillings")
        public var penny = Unit("penny", "pence")
        public var moneyAnd = "and"

        public init(equals: String, approximately: String, notEqual: String,
                    lessOrEqual: String, greaterOrEqual: String, less: String,
                    greater: String, plus: String, minus: String, times: String,
                    over: String, squared: String, cubed: String, toThePowerOf: String,
                    nthPower: @escaping @Sendable (Int) -> String,
                    squareRootOf: String, cubeRootOf: String, theQuantity: String,
                    symbols: [Character: String], functions: [String: String]) {
            self.equals = equals; self.approximately = approximately
            self.notEqual = notEqual; self.lessOrEqual = lessOrEqual
            self.greaterOrEqual = greaterOrEqual; self.less = less
            self.greater = greater; self.plus = plus; self.minus = minus
            self.times = times; self.over = over; self.squared = squared
            self.cubed = cubed; self.toThePowerOf = toThePowerOf
            self.nthPower = nthPower
            self.squareRootOf = squareRootOf; self.cubeRootOf = cubeRootOf
            self.theQuantity = theQuantity; self.symbols = symbols
            self.functions = functions
        }

        public static let english = Words(
            equals: "equals", approximately: "is approximately",
            notEqual: "is not equal to", lessOrEqual: "is less than or equal to",
            greaterOrEqual: "is greater than or equal to", less: "is less than",
            greater: "is greater than", plus: "plus", minus: "minus", times: "times",
            over: "over", squared: "squared", cubed: "cubed",
            toThePowerOf: "to the power of",
            nthPower: { n in
                let suffix: String
                switch (n % 100, n % 10) {
                case (11...13, _): suffix = "th"
                case (_, 1): suffix = "st"
                case (_, 2): suffix = "nd"
                case (_, 3): suffix = "rd"
                default: suffix = "th"
                }
                return "to the \(n)\(suffix) power"
            },
            squareRootOf: "the square root of", cubeRootOf: "the cube root of",
            theQuantity: "the quantity",
            symbols: ["π": "pi", "α": "alpha", "β": "beta", "γ": "gamma",
                      "δ": "delta", "Δ": "delta", "ε": "epsilon", "θ": "theta",
                      "λ": "lambda", "μ": "mu", "µ": "mu", "ρ": "rho",
                      "σ": "sigma", "Σ": "sigma", "τ": "tau", "φ": "phi",
                      "ω": "omega", "Ω": "omega", "∞": "infinity"],
            functions: ["sin": "sine of", "cos": "cosine of", "tan": "tangent of",
                        "log": "log of", "ln": "natural log of"])
    }

    // MARK: - Finding candidate spans

    static let binaryOperators: Set<Character> = ["=", "≈", "≠", "≤", "≥", "<", ">",
                                                  "+", "-", "−", "*", "×", "·", "/", "^"]
    static let superscripts: [Character: Character] = [
        "⁰": "0", "¹": "1", "²": "2", "³": "3", "⁴": "4", "⁵": "5", "⁶": "6",
        "⁷": "7", "⁸": "8", "⁹": "9", "⁺": "+", "⁻": "-", "ⁿ": "n", "ⁱ": "i"]
    static let subscripts: [Character: Character] = [
        "₀": "0", "₁": "1", "₂": "2", "₃": "3", "₄": "4", "₅": "5", "₆": "6",
        "₇": "7", "₈": "8", "₉": "9"]

    static func isMathChar(_ c: Character, words: Words = .english) -> Bool {
        if c.isASCII && (c.isLetter || c.isNumber) { return true }
        if binaryOperators.contains(c) || superscripts[c] != nil || subscripts[c] != nil {
            return true
        }
        return "().√∛".contains(c) || words.symbols[c] != nil || c == "π" || c == "∞"
    }

    /// Maximal runs of math characters. A run may cross spaces only next to a
    /// binary operator ("E = mc²"), and never across a spaced ASCII hyphen,
    /// which in prose is a dash ("E = mc² - the famous one").
    static func candidateSpans(_ chars: [Character], words: Words = .english) -> [Range<Int>] {
        let n = chars.count
        var spans: [Range<Int>] = []
        var i = 0
        func spacedHyphen(_ at: Int) -> Bool {
            chars[at] == "-" && at > 0 && chars[at - 1] == " "
                && at + 1 < n && chars[at + 1] == " "
        }
        while i < n {
            guard isMathChar(chars[i], words: words) else { i += 1; continue }
            var end = i + 1
            var j = end
            while j < n {
                if isMathChar(chars[j], words: words) {
                    end = j + 1; j += 1; continue
                }
                guard chars[j] == " " else { break }
                var k = j
                while k < n && chars[k] == " " { k += 1 }
                guard k < n, isMathChar(chars[k], words: words) else { break }
                let before = end - 1
                let joins = (binaryOperators.contains(chars[before]) && !spacedHyphen(before))
                    || (binaryOperators.contains(chars[k]) && !spacedHyphen(k))
                guard joins else { break }
                j = k
            }
            if let trimmed = trim(chars, i..<end) { spans.append(trimmed) }
            i = end
        }
        return spans
    }

    /// Drop sentence punctuation, dangling operators and unbalanced
    /// parentheses from the ends: "(E=mc²)." → "E=mc²".
    static func trim(_ chars: [Character], _ span: Range<Int>) -> Range<Int>? {
        var lo = span.lowerBound, hi = span.upperBound
        let leadingOK: Set<Character> = ["-", "−", "(", "√", "∛"]
        var changed = true
        while changed && lo < hi {
            changed = false
            let first = chars[lo], last = chars[hi - 1]
            let opens = chars[lo..<hi].filter { $0 == "(" }.count
            let closes = chars[lo..<hi].filter { $0 == ")" }.count
            if first == " " || first == "." || (binaryOperators.contains(first) && !leadingOK.contains(first)) {
                lo += 1; changed = true
            } else if last == " " || last == "." || last == "(" || binaryOperators.contains(last) {
                hi -= 1; changed = true
            } else if first == "(" && opens > closes {
                lo += 1; changed = true
            } else if last == ")" && closes > opens {
                hi -= 1; changed = true
            }
        }
        return lo < hi ? lo..<hi : nil
    }

    /// A span glued to a character that is not math belongs to something
    /// else: a URL query (`?q=a`), a variable (`$x=5`), a word (`café=`).
    static func touchesNonMath(_ chars: [Character], _ span: Range<Int>) -> Bool {
        let glue: Set<Character> = ["?", "&", "=", "/", ":", "@", "#", "%", "_", "\\", "$", "~", "'", "’", "!", "|", "[", "]", "{", "}", "<", ">", "`", "\""]
        if span.lowerBound > 0 {
            let c = chars[span.lowerBound - 1]
            if glue.contains(c) || c.isLetter || c.isNumber { return true }
        }
        if span.upperBound < chars.count {
            let c = chars[span.upperBound]
            if glue.contains(c) || c.isLetter || c.isNumber { return true }
        }
        return false
    }

    // MARK: - Declines

    static let unitSymbols = "m|cm|mm|km|nm|μm|µm|ft|in|mi|yd|s|h|g|kg|N|Pa|J|W|L|mL"

    /// "20 m²", "9.8 m/s²", "kg·m²": units, not algebra. Declined, so an app's
    /// own unit reader ("square meters") gets them intact.
    static func isUnitNotation(_ s: String) -> Bool {
        let unit = "(?:\(unitSymbols))[²³]?"
        let pattern = "^[0-9.\\s]*\(unit)(?:[/·]\(unit))*$"
        return s.contains(where: { $0 == "²" || $0 == "³" })
            && s.range(of: pattern, options: .regularExpression) != nil
    }

    /// "A=B testing": capital letters joined only by a relation are a label,
    /// not an equation.
    static func isLabel(_ node: Node) -> Bool {
        switch node {
        case .relation(let l, _, let r): return isLabel(l) && isLabel(r)
        case .atom(let s, let isCapital): return isCapital && s.count == 1
        default: return false
        }
    }

    // MARK: - Lexing

    enum Token: Equatable {
        case number(String)
        case atom(String, isCapital: Bool)
        case function(String)
        case op(Character)
        case superscript(String)
        case subscripted(String)
        case open, close
        case root(cube: Bool)

        var isTrigger: Bool {
            switch self {
            case .op(let c): return "=≈≠≤≥^".contains(c)
            case .superscript(let s): return s != "1"   // a lone ¹ is a footnote
            case .root: return true
            default: return false
            }
        }
    }

    static func lex(_ chars: [Character], words: Words = .english) -> [Token]? {
        var tokens: [Token] = []
        var i = 0
        let n = chars.count
        while i < n {
            let c = chars[i]
            if c == " " { i += 1; continue }
            if c.isASCII && c.isNumber {
                var s = ""
                var sawPoint = false
                while i < n, chars[i].isASCII,
                      chars[i].isNumber || (chars[i] == "." && !sawPoint && i + 1 < n && chars[i + 1].isNumber) {
                    if chars[i] == "." { sawPoint = true }
                    s.append(chars[i]); i += 1
                }
                tokens.append(.number(s))
                continue
            }
            if c.isASCII && c.isLetter {
                var run = ""
                while i < n, chars[i].isASCII, chars[i].isLetter { run.append(chars[i]); i += 1 }
                if words.functions[run.lowercased()] != nil {
                    tokens.append(.function(run.lowercased())); continue
                }
                if run.lowercased() == "sqrt" { tokens.append(.root(cube: false)); continue }
                // A letter run is a product of single-letter variables ("mc",
                // "nRT") — unless it looks like a word, which means prose.
                let allLower = run == run.lowercased(), allUpper = run == run.uppercased()
                if run.count >= 4 || (run.count == 3 && (allLower || allUpper)) { return nil }
                for l in run { tokens.append(.atom(String(l), isCapital: l.isUppercase)) }
                continue
            }
            if let name = words.symbols[c] {
                tokens.append(.atom(name, isCapital: false)); i += 1; continue
            }
            if superscripts[c] != nil {
                var s = ""
                while i < n, let d = superscripts[chars[i]] { s.append(d); i += 1 }
                tokens.append(.superscript(s)); continue
            }
            if subscripts[c] != nil {
                var s = ""
                while i < n, let d = subscripts[chars[i]] { s.append(d); i += 1 }
                tokens.append(.subscripted(s)); continue
            }
            switch c {
            case "(": tokens.append(.open)
            case ")": tokens.append(.close)
            case "√": tokens.append(.root(cube: false))
            case "∛": tokens.append(.root(cube: true))
            case _ where binaryOperators.contains(c): tokens.append(.op(c))
            default: return nil
            }
            i += 1
        }
        return tokens
    }

    // MARK: - Parsing

    indirect enum Node: Equatable {
        case number(String)
        case atom(String, isCapital: Bool)
        case group(Node)
        case negative(Node)
        case relation(Node, Character, Node)
        case arithmetic(Node, Character, Node)
        case product([Node])
        case power(Node, Node)
        case root(Node, cube: Bool)
        case function(String, Node)
        case subscripted(Node, String)

        /// Needs "the quantity" in front when it is a base or a radicand.
        var isCompound: Bool {
            switch self {
            case .group(let inner): return inner.isCompound
            case .relation, .arithmetic, .product, .negative: return true
            default: return false
            }
        }
    }

    struct Parser {
        let tokens: [Token]
        let words: Words
        var i = 0

        init(tokens: [Token], words: Words) { self.tokens = tokens; self.words = words }

        var peek: Token? { i < tokens.count ? tokens[i] : nil }

        mutating func parseAll() -> Node? {
            guard let node = relation(), i == tokens.count else { return nil }
            return node
        }

        mutating func relation() -> Node? {
            guard var lhs = additive() else { return nil }
            while case .op(let c)? = peek, "=≈≠≤≥<>".contains(c) {
                i += 1
                guard let rhs = additive() else { return nil }
                lhs = .relation(lhs, c, rhs)
            }
            return lhs
        }

        mutating func additive() -> Node? {
            guard var lhs = multiplicative() else { return nil }
            while case .op(let c)? = peek, "+-−".contains(c) {
                i += 1
                guard let rhs = multiplicative() else { return nil }
                lhs = .arithmetic(lhs, c, rhs)
            }
            return lhs
        }

        mutating func multiplicative() -> Node? {
            guard var lhs = implicitProduct() else { return nil }
            while case .op(let c)? = peek, "*×·/".contains(c) {
                i += 1
                guard let rhs = implicitProduct() else { return nil }
                lhs = .arithmetic(lhs, c, rhs)
            }
            return lhs
        }

        /// Juxtaposition: "2ab" is 2 times a times b.
        mutating func implicitProduct() -> Node? {
            guard let first = unary() else { return nil }
            var items = [first]
            while startsOperand(peek) {
                guard let next = rootOrPower() else { return nil }
                items.append(next)
            }
            return items.count == 1 ? first : .product(items)
        }

        func startsOperand(_ t: Token?) -> Bool {
            switch t {
            case .number?, .atom?, .function?, .open?, .root?: return true
            default: return false
            }
        }

        mutating func unary() -> Node? {
            if case .op(let c)? = peek, c == "-" || c == "−" {
                i += 1
                return unary().map { .negative($0) }
            }
            if case .op("+")? = peek { i += 1; return unary() }
            return rootOrPower()
        }

        mutating func rootOrPower() -> Node? {
            if case .root(let cube)? = peek {
                i += 1
                return rootOrPower().map { .root($0, cube: cube) }
            }
            return power()
        }

        mutating func power() -> Node? {
            guard var base = postfix() else { return nil }
            while true {
                if case .op("^")? = peek {
                    i += 1
                    guard let exponent = exponent() else { return nil }
                    base = .power(base, exponent)
                } else if case .superscript(let s)? = peek {
                    i += 1
                    guard let exponent = superscriptExponent(s) else { return nil }
                    base = .power(base, exponent)
                } else {
                    return base
                }
            }
        }

        mutating func exponent() -> Node? {
            if case .op(let c)? = peek, c == "-" || c == "−" {
                i += 1
                return exponent().map { .negative($0) }
            }
            if case .op("+")? = peek { i += 1 }
            return primary()
        }

        func superscriptExponent(_ s: String) -> Node? {
            guard let tokens = MathLexicon.lex(Array(s), words: words) else { return nil }
            var sub = Parser(tokens: tokens, words: words)
            return sub.parseAll()
        }

        mutating func postfix() -> Node? {
            guard var node = primary() else { return nil }
            while case .subscripted(let s)? = peek {
                i += 1
                node = .subscripted(node, s)
            }
            return node
        }

        mutating func primary() -> Node? {
            switch peek {
            case .number(let s)?:
                i += 1; return .number(s)
            case .atom(let s, let isCapital)?:
                i += 1; return .atom(s, isCapital: isCapital)
            case .function(let name)?:
                i += 1
                return rootOrPower().map { .function(name, $0) }
            case .open?:
                i += 1
                guard let inner = relation(), case .close? = peek else { return nil }
                i += 1
                return .group(inner)
            default:
                return nil
            }
        }
    }

    // MARK: - Reading

    func read(_ node: Node) -> String {
        switch node {
        case .number(let s), .atom(let s, _):
            return s
        case .group(let inner):
            return read(inner)
        case .negative(let inner):
            return "\(words.minus) \(read(inner))"
        case .relation(let l, let c, let r):
            let word: String
            switch c {
            case "=": word = words.equals
            case "≈": word = words.approximately
            case "≠": word = words.notEqual
            case "≤": word = words.lessOrEqual
            case "≥": word = words.greaterOrEqual
            case "<": word = words.less
            default: word = words.greater
            }
            return "\(read(l)) \(word) \(read(r))"
        case .arithmetic(let l, let c, let r):
            let word: String
            switch c {
            case "+": word = words.plus
            case "-", "−": word = words.minus
            case "/": word = words.over
            default: word = words.times
            }
            return "\(read(l)) \(word) \(read(r))"
        case .product(let items):
            return items.map(read).joined(separator: " ")
        case .power(let base, let exponent):
            let b = base.isCompound ? "\(words.theQuantity) \(read(base))," : read(base)
            return "\(b) \(readExponent(exponent))"
        case .root(let radicand, let cube):
            let lead = cube ? words.cubeRootOf : words.squareRootOf
            let r = radicand.isCompound ? "\(words.theQuantity) \(read(radicand))" : read(radicand)
            return "\(lead) \(r)"
        case .function(let name, let argument):
            let lead = words.functions[name] ?? name
            let a = argument.isCompound ? "\(words.theQuantity) \(read(argument))" : read(argument)
            return "\(lead) \(a)"
        case .subscripted(let base, let digits):
            return "\(read(base)) \(digits)"
        }
    }

    /// A LETTER EXPONENT IS "to the power of n", NOT "to the n-th power".
    /// Measured by round trip (synthesise, then transcribe): "a to the n-th
    /// power" came back "a to the end they power", and both "nth" and "enth"
    /// came back "10th". "to the power of n" came back as written.
    func readExponent(_ exponent: Node) -> String {
        switch exponent {
        case .number("2"): return words.squared
        case .number("3"): return words.cubed
        case .number(let s):
            if let n = Int(s) { return words.nthPower(n) }
        default:
            break
        }
        return "\(words.toThePowerOf) \(read(exponent))"
    }

    // MARK: - Symbols that are math wherever they appear

    /// `π` and subscript digits have no prose reading, so they are read
    /// everywhere: "2π" → "2 pi", "H₂O" → "H 2 O".
    func alwaysMath(_ text: String) -> String {
        guard text.contains(where: { $0 == "π" || Self.subscripts[$0] != nil }) else { return text }
        let chars = Array(text)
        var out = ""
        var i = 0
        func padBefore() {
            if let last = out.last, last.isLetter || last.isNumber { out.append(" ") }
        }
        while i < chars.count {
            let c = chars[i]
            var word: String?
            if c == "π" {
                word = words.symbols["π"] ?? "pi"; i += 1
            } else if Self.subscripts[c] != nil {
                var s = ""
                while i < chars.count, let d = Self.subscripts[chars[i]] { s.append(d); i += 1 }
                word = s
            }
            if let word {
                padBefore()
                out += word
                if i < chars.count, chars[i].isLetter || chars[i].isNumber { out.append(" ") }
            } else {
                out.append(c); i += 1
            }
        }
        return out
    }
}
