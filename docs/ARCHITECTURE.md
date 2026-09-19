# Architecture

How MathLexicon is put together, and why it declines as much as it reads. The README covers what it
reads; this covers how, and which parts you cannot move without breaking something.

## The shape of it

A pure `String -> String` transform. No state, no I/O, no dependencies beyond Foundation. That is
why the whole suite runs on the host machine in a fraction of a second, and why you can reason about
any input by reading two files.

**The scope rule is the design, not a limitation.** A span is rewritten only when it is
unambiguously math; everything else comes back byte-for-byte. A formula read slightly wrong is a
small miss, but prose rewritten into math is a bug. So every feature here is half reading and half
decline, and the declines are where the real logic lives.

## Three stages, in a fixed order

`speakable(_:)` runs three stages, and the order is load-bearing:

1. **The equation pass** (`MathLexicon.swift`). `candidateSpans` finds maximal runs of math
   characters — crossing a space only when a binary operator sits on one side of it, and never
   across a spaced ASCII hyphen, which in prose is a dash. Each span is narrowed by `trim`, which
   drops sentence punctuation, dangling operators and unbalanced parentheses, and rejected by
   `touchesNonMath` when it is glued to a URL, a variable or a word. What survives goes to
   `reading(_:)`, which lexes and parses it.
2. **`measures(_:)`** (`Measures.swift`). Nine regex passes over the *result* of stage 1, handling
   units, ranges, fractions, pre-decimal money, coordinates, `×`, comparison signs and lone Greek
   letters as they appear in ordinary prose.
3. **`alwaysMath(_:)`**. `π` and subscript digits last, because they have no prose reading at all
   and so are read wherever they occur (`H₂O` → "H 2 O").

## Why a span is left alone

A rewrite needs two things: a **trigger** — `Token.isTrigger`, meaning one of `=` `^` `≈` `≠` `≤`
`≥`, a root, or a superscript that is not a lone `¹` — and a **parse of the whole span**. The parser
is recursive descent:

```
relation → additive → multiplicative → implicitProduct → unary → rootOrPower → power → postfix → primary
```

It never error-recovers. A `nil` anywhere means the span is returned untouched. That is deliberate:
partial parses are how a reader starts inventing math that was not there.

Four further declines carry most of the weight, and each exists because of a specific look-alike:

| decline | rejects | because |
|---|---|---|
| `isUnitNotation` | `20 m²`, `9.8 m/s²` | units, not algebra — the prose pass should get them |
| `isLabel` | `A=B testing` | single capitals joined only by a relation are a label |
| the word-guard in `lex` | `and`, `the` | a letter run of 4+, or of 3 in one case, is prose, not a product of single-letter variables — this is what separates `nRT` from a word |
| `touchesNonMath` | `?q=a`, `$x=5` | the span belongs to a URL or a variable |

## Ordering constraints inside `measures`

These are not stylistic. Moving them breaks readings that currently pass:

- **`coordinates` must precede `numberWithUnit`**, because `°` is itself in the unit table. Once
  `39°` has become "39 degrees", the coordinate pattern — which needs `\d{1,3}°` — can no longer
  match.
- **`dimensions`** reads `×` as "by", and is safe only because the equation pass has already
  consumed any `×` inside a real equation, where it means "times".
- **`slashUnits`** deliberately filters `°`-prefixed keys out of both sides of the slash.

## The unit table has deliberate holes

Single capitals — `W`, `N`, `S`, `E`, `A`, `V`, `L` — and a bare `s` are **not** units. `1200 W Main
St` is a street address and `the 1960 s` is a decade. Their unambiguous multi-letter forms (`kW`,
`mV`, `mA`, `mL`) are in.

`s`, `h` and `L` live in `denominatorUnits`, legal only after a slash, where nothing else they could
be survives. Outside that, a unit is read only immediately after a number.

If you are tempted to add a single capital to the table, add its look-alike to the tests first and
watch it fail.

## Localization seam

`MathLexicon.Words` holds every spoken string *and* the unit, fraction and comparison tables, so
another language is one value rather than a code change.

Note the split. The equation vocabulary are required arguments on the memberwise `init`, while the
prose and measures vocabulary are `var` properties carrying English defaults. A translation
therefore constructs the first group and *assigns* the second:

```swift
var words = MathLexicon.Words.english
words.equals = "égale"
words.squared = "au carré"
MathLexicon(words: words).speakable("E=mc²")   // "E égale m c au carré"
```

## The tests are tables

Seven of them, driven by thirteen test methods:

| table | rows | holds |
|---|---|---|
| `phrasings` | 33 | written math → spoken, checked alone, mid-sentence and before a full stop |
| `lookAlikes` | 42 | text that must come back byte-for-byte unchanged |
| `measures` | 26 | units, ranges, fractions, `×` and comparisons in prose |
| `oldMoneyLookAlikes` | 12 | decades, ages and model numbers that are not money |
| `oldMoney` | 7 | pre-decimal British money, as whole sentences |
| `symbols` | 5 | always-math symbols |
| `coordinates` | 4 | latitude and longitude |

**Every rule that widens what counts as math owes a row showing what it still leaves alone.** A
change that adds a phrasing and breaks a look-alike is not an improvement, however good the phrasing
is. The look-alike tables are the only thing making the scope rule real rather than aspirational.

## Running the tests

```sh
swift test                                          # 13 tests
swift test --filter 'MathLexiconTests.testOldMoney$' # exactly one test
swift test --filter MathLexiconTests                 # the whole class
```

`--filter` takes an unanchored regex over `Class.method`, so `--filter MathLexiconTests.testOldMoney`
runs **two** tests — it also matches `testOldMoneyLookAlikesAreUntouched`. Anchor it with `$` when
you want one.

`Package.swift` declares swift-tools 5.9 and targets iOS 15, macOS 12, tvOS 15, watchOS 8 and
visionOS 1.

## Check readings by ear, not by argument

A reading can be correct as text and still come out of a voice wrong. The readings here were settled
by synthesising them and running a speech recogniser over the audio, then comparing the transcript
against the expected row — not by reasoning about what ought to sound right. The evidence is kept in
the doc comments because it cannot be recovered from the code:

- `a^n` reads "to the power of n" rather than "to the nth power", because "a to the n-th power" came
  back transcribed as "a to the end they power", and both "nth" and "enth" came back as "10th".
- `7s. 6d.` came back as "760", and `26s. 4d.` as "264D", before the money pass existed.
- `39°50′N` came back as "Axa and W" before the coordinate pass existed.

When you change how something is read, round-trip it the same way and record what you heard in the
doc comment. Do not replace a measured reading with a reasoned one.

## Numbers stay digits

Numerals are never spelled out. Every speech engine already reads digits, and applications disagree
about how — "3.14" as "three point one four" or "three point fourteen" — so that choice belongs to
the caller, not to this library.
