# MathLexicon

Reads written math aloud, for text-to-speech.

A speech engine handed `E=mc²` spells the symbols, skips them, or says "E M C two". MathLexicon
rewrites the expression into what a person would say, and leaves every other character alone:

```swift
import MathLexicon

MathLexicon.english.speakable("Einstein wrote E = mc².")
// "Einstein wrote E equals m c squared."
```

Swift, Foundation only, no dependencies. iOS 15, macOS 12, tvOS 15, watchOS 8, visionOS 1.

## What it reads

| written | spoken |
|---|---|
| `E=mc^2`, `E = mc²` | E equals m c squared |
| `x^3`, `x³` | x cubed |
| `a^n`, `aⁿ` | a to the power of n |
| `2^10` | 2 to the 10th power |
| `x^-1`, `10⁻³` | x to the power of minus 1 |
| `√2` | the square root of 2 |
| `√(x+1)` | the square root of the quantity x plus 1 |
| `(a+b)²` | the quantity a plus b, squared |
| `F=ma` | F equals m a |
| `a²+b²=c²` | a squared plus b squared equals c squared |
| `PV=nRT` | P V equals n R T |
| `π ≈ 3.14` | pi is approximately 3.14 |
| `x ≠ 0`, `n ≥ 2` | x is not equal to 0, n is greater than or equal to 2 |
| `e^(iπ)+1=0` | e to the power of i pi plus 1 equals 0 |
| `H₂O` | H 2 O |

Numbers stay as digits. Every speech engine already reads digits, and apps disagree about how
("3.14" as "three point one four" or "three point fourteen"), so that choice is left to you.

## Units and symbols in prose

A second pass reads measurements and symbols in ordinary sentences, with the same rule: a reading
needs something that makes it unambiguous.

| written | spoken |
|---|---|
| `25–36 kg (55–80 lb)` | 25 to 36 kilograms (55 to 80 pounds) |
| `(< 33 °C)` | (less than 33 degrees Celsius) |
| `45°–48°` | 45 to 48 degrees |
| `9.8 m/s²`, `20 m²` | 9.8 meters per second squared, 20 square meters |
| `The SI unit for velocity is m/s.` | …is meters per second. |
| `(1792–1852)` | (1792 to 1852) |
| `4½ per cent` | 4 and a half per cent |
| `4×4` | 4 by 4 |
| `the wavelength λ`, `ΔH` | the wavelength lambda, delta H |

- **A unit is read only right after a number** (`5 m`), or as a slash compound whose halves are
  both units (`m/s`). Unit symbols are case-sensitive.
- **Single capitals are not units.** In `1200 W Main St` the W is West, and N, S, E, A, V and L
  collide the same way. `s` is not a unit either (`the 1960 s`), except after a slash.
- **A range needs an en dash** between numbers (`1792–1852`), or a unit after it. An ASCII hyphen
  between bare numbers is a score or a phone number (`3-2 win`, `555-1234`).
- **A comparison sign needs a space and then a number**: `< 33` is read; `<3` and `a <= b` are not.
- **A lone Greek letter is read**, and so is one followed by a single letter (`Δx`). A Greek word
  (`σιρός`) is left alone.
- A compound the table cannot read whole (`g/cm3`) is left whole rather than half-read.

Known limits: `5 m budget` reads as meters (only `$5 m` is recognised as money), and a range whose
ends carry different units (`5 m–10 cm`) is left unread.

## What it leaves alone

**This is the design, not a limitation.** A span is rewritten only if it is clearly an equation:

1. It contains one of `=` `^` `²` `³` `√` `≈` `≠` `≤` `≥`, with an operand on each side that
   operator needs.
2. The whole span parses as an expression. If it does not, nothing in it changes.
3. It is not a word (`cost=5`, `width=100`), a label (`A=B testing`), a unit (`20 m²`,
   `9.8 m/s²`), code (`x == y`, `a <= b`, `x += 1`), or part of a URL or variable (`?q=a`, `$x=5`).

So `3-2 win`, `C++`, `e-mail`, `X-ray`, `a+b`, `Ohio¹` and `221B Baker Street` all come back
unchanged. A formula read slightly wrong is a small miss. Prose rewritten into math is a bug.

`π` and subscript digits are the exception: they have no prose reading, so they are read wherever
they appear.

## Using it

```swift
.package(url: "https://github.com/halfmarble/MathLexicon.git", from: "1.0.0")
```

## API

```swift
let lexicon = MathLexicon.english

lexicon.speakable(text)        // the whole text, math spans replaced
lexicon.reading("a^n")         // "a to the power of n"
lexicon.reading("C++")         // nil: not clearly math
```

Every spoken word lives in `MathLexicon.Words`, so another language is one value:

```swift
var words = MathLexicon.Words.english
words.equals = "égale"
words.squared = "au carré"
MathLexicon(words: words).speakable("E=mc²")   // "E égale m c au carré"
```

## Contributing

`docs/ARCHITECTURE.md` explains how the reader is put together — the three passes and why their
order is load-bearing, why a span is declined, and the constraints you cannot move without
breaking a reading. Read it before changing anything in `Sources/`.

The tests are tables in `Tests/MathLexiconTests/MathLexiconTests.swift`. Two of them carry most
of the work:

- **`phrasings`**: written math and what a person says. Each row is checked on its own, mid-sentence
  and before a full stop.
- **`lookAlikes`**: text that must come back byte-for-byte unchanged.

The rest are the same pairing on a narrower subject: `measures` and `symbols` for units and symbols
in prose, `oldMoney` and `oldMoneyLookAlikes` for pre-decimal British money, and `coordinates` for
written latitude and longitude.

The most useful contribution is a row. When you add a reading, add its nearest look-alike too: every
rule that widens what counts as math has to show what it still leaves alone. A pull request that
adds a phrasing and makes a look-alike fail will not be merged, however good the phrasing is.

```sh
swift test
```

Please also check a reading by ear, or by round trip: synthesise it with your speech engine, run a
speech recogniser on the audio, and compare the transcript with the row. A reading can be correct
text and still come out of a voice badly.

## License

Apache 2.0. See `LICENSE`.
