//
//  PixelArcadeScoreNumberView.swift
//  ScoreKeepUI
//
//  Classic 80s-arcade score display: 5×7 chunky pixel digits drawn as solid
//  square sprites, with a CRT scan-line overlay across the digit area.
//  Distinct from the LED scoreboard style (round dots, ambient texture) —
//  these are sharp square pixels with no background panel.
//

import SwiftUI

public struct PixelArcadeScoreNumberView: View {
    let label: String
    let color: Color
    var showLeadingDigitSlot: Bool = true
    var layout: Layout = .compact

    @Environment(\.colorScheme) private var colorScheme

    public enum Layout: Equatable {
        case compact
        case fillContainer
    }

    public init(
        label: String,
        color: Color,
        showLeadingDigitSlot: Bool = true,
        layout: Layout = .compact
    ) {
        self.label = label
        self.color = color
        self.showLeadingDigitSlot = showLeadingDigitSlot
        self.layout = layout
    }

    private var resolved: ResolvedDigits {
        if label == "Ad" {
            return ResolvedDigits(left: "A", right: "d")
        }
        let chars = Array(label)
        if chars.count == 1 {
            let leftChar: Character? = showLeadingDigitSlot ? "0" : nil
            return ResolvedDigits(left: leftChar, right: chars[0])
        }
        if chars.count >= 2 {
            return ResolvedDigits(left: chars[chars.count - 2], right: chars[chars.count - 1])
        }
        return ResolvedDigits(left: nil, right: nil)
    }

    public var body: some View {
        switch layout {
        case .compact:
            compactBody
        case .fillContainer:
            fillContainerBody
        }
    }

    private var compactBody: some View {
        let h: CGFloat = 60
        let pixelSize: CGFloat = h / 8.0
        let digitWidth = pixelSize * CGFloat(PixelDigit.glyphWidth)
        let digitGap = pixelSize
        let totalWidth = digitWidth * 2 + digitGap

        return HStack(spacing: digitGap) {
            pixelSlot(char: resolved.left, width: digitWidth, pixelSize: pixelSize)
            pixelSlot(char: resolved.right, width: digitWidth, pixelSize: pixelSize)
        }
        .frame(width: totalWidth, height: h)
        .overlay(scanlineOverlay())
    }

    private var fillContainerBody: some View {
        GeometryReader { geo in
            let verticalInset: CGFloat = 9
            let trailingInset: CGFloat = 10
            let h = max(20, geo.size.height - 2 * verticalInset)
            let pixelSize = h / 8.0
            let digitWidth = pixelSize * CGFloat(PixelDigit.glyphWidth)
            let digitGap = pixelSize
            let totalWidth = digitWidth * 2 + digitGap

            HStack(spacing: digitGap) {
                pixelSlot(char: resolved.left, width: digitWidth, pixelSize: pixelSize)
                pixelSlot(char: resolved.right, width: digitWidth, pixelSize: pixelSize)
            }
            .frame(width: totalWidth, height: h)
            .overlay(scanlineOverlay())
            .position(
                x: geo.size.width - totalWidth / 2 - trailingInset,
                y: geo.size.height / 2
            )
        }
    }

    @ViewBuilder
    private func pixelSlot(char: Character?, width: CGFloat, pixelSize: CGFloat) -> some View {
        if let char {
            PixelDigit(char: char, color: color, pixelSize: pixelSize)
                .frame(width: width)
        } else {
            Color.clear.frame(width: width)
        }
    }

    private func scanlineOverlay() -> some View {
        GeometryReader { geo in
            // Every other 1pt row darkened — classic CRT raster look.
            VStack(spacing: 1) {
                ForEach(0..<Int(geo.size.height / 2), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(colorScheme == .light ? 0.08 : 0.32))
                        .frame(height: 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .allowsHitTesting(false)
    }

    struct ResolvedDigits {
        var left: Character?
        var right: Character?
    }
}

// MARK: - Pixel digit

private struct PixelDigit: View {
    let char: Character
    let color: Color
    let pixelSize: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    static let glyphWidth = 5
    static let glyphHeight = 7

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<Self.glyphHeight, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<Self.glyphWidth, id: \.self) { col in
                        pixelView(row: row, col: col)
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.10), value: char)
    }

    @ViewBuilder
    private func pixelView(row: Int, col: Int) -> some View {
        let isLit = isPixelLit(char: char, row: row, col: col)
        let isLight = colorScheme == .light
        Rectangle()
            .fill(color)
            .opacity(isLit ? 1.0 : 0)
            .brightness(isLit ? (isLight ? -0.12 : 0.20) : 0)
            .shadow(color: color.opacity(isLit && !isLight ? 0.7 : 0), radius: isLit && !isLight ? 1.2 : 0)
            .frame(width: pixelSize, height: pixelSize)
    }

    private func isPixelLit(char: Character, row: Int, col: Int) -> Bool {
        guard let glyph = Self.glyphs[char] else { return false }
        guard row < glyph.count else { return false }
        let chars = Array(glyph[row])
        guard col < chars.count else { return false }
        return chars[col] == "#"
    }

    /// 5-wide × 7-tall pixel font for digits, plus tennis "A" and "d".
    private static let glyphs: [Character: [String]] = [
        "0": [
            ".###.",
            "#...#",
            "#..##",
            "#.#.#",
            "##..#",
            "#...#",
            ".###.",
        ],
        "1": [
            "..#..",
            ".##..",
            "..#..",
            "..#..",
            "..#..",
            "..#..",
            ".###.",
        ],
        "2": [
            ".###.",
            "#...#",
            "....#",
            "...#.",
            "..#..",
            ".#...",
            "#####",
        ],
        "3": [
            ".###.",
            "#...#",
            "....#",
            "..##.",
            "....#",
            "#...#",
            ".###.",
        ],
        "4": [
            "...#.",
            "..##.",
            ".#.#.",
            "#..#.",
            "#####",
            "...#.",
            "...#.",
        ],
        "5": [
            "#####",
            "#....",
            "####.",
            "....#",
            "....#",
            "#...#",
            ".###.",
        ],
        "6": [
            "..##.",
            ".#...",
            "#....",
            "####.",
            "#...#",
            "#...#",
            ".###.",
        ],
        "7": [
            "#####",
            "....#",
            "...#.",
            "..#..",
            ".#...",
            ".#...",
            ".#...",
        ],
        "8": [
            ".###.",
            "#...#",
            "#...#",
            ".###.",
            "#...#",
            "#...#",
            ".###.",
        ],
        "9": [
            ".###.",
            "#...#",
            "#...#",
            ".####",
            "....#",
            "...#.",
            ".##..",
        ],
        "A": [
            "..#..",
            ".#.#.",
            "#...#",
            "#...#",
            "#####",
            "#...#",
            "#...#",
        ],
        "d": [
            "....#",
            "....#",
            ".####",
            "#...#",
            "#...#",
            "#...#",
            ".####",
        ],
    ]
}

// MARK: - Previews

#Preview("Pixel — counting up") {
    struct Cycler: View {
        @State var value: Int = 0
        var body: some View {
            PixelArcadeScoreNumberView(
                label: "\(value)",
                color: ScoreKeepBrand.iconPurple
            )
            .padding()
            .background(Color.black)
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(900))
                    value = (value + 1) % 22
                }
            }
        }
    }
    return Cycler()
}
