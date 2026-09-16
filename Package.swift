// swift-tools-version: 5.9
import PackageDescription

// MathLexicon — reads written math aloud for a text-to-speech voice.
//
// Foundation only, no dependencies, every Apple platform: it is a pure
// String -> String transform, so `swift test` runs it on a Mac in seconds.
let package = Package(
    name: "MathLexicon",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8), .visionOS(.v1)],
    products: [
        .library(name: "MathLexicon", targets: ["MathLexicon"]),
    ],
    targets: [
        .target(name: "MathLexicon"),
        .testTarget(name: "MathLexiconTests", dependencies: ["MathLexicon"]),
    ]
)
