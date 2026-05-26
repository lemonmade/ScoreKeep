//
//  LEDScoreNumberView.swift
//  ScoreKeepUI
//

import SwiftUI

public struct LEDScoreNumberView: View {
    let label: String
    let color: Color
    var layout: Layout = .compact

    @Environment(\.colorScheme) private var colorScheme

    public enum Layout: Equatable {
        /// Fixed-size grid centered around the digits, all four corners cut for
        /// a "rounded panel" feel. Used in the Settings preview and anywhere
        /// the LED display is intrinsically sized.
        case compact

        /// Fills the parent container — used as the active match button's
        /// score panel. Digits are right-aligned with `rightPadding` columns
        /// of decoration to the right; the left edge fades to transparent so
        /// the team chip on top stays readable; the top/bottom right corner
        /// dots are skipped to suggest a rounded corner.
        case fillContainer(rightPadding: Int)
    }

    public init(label: String, color: Color, layout: Layout = .compact) {
        self.label = label
        self.color = color
        self.layout = layout
    }

    private let dotSize: CGFloat = 7
    private let dotSpacing: CGFloat = 2

    private static let glyphCols = 3
    private static let glyphRows = 7
    private static let glyphGap = 1

    public var body: some View {
        switch layout {
        case .compact:
            compactGrid
        case .fillContainer(let rightPadding):
            fillContainerGrid(rightPadding: rightPadding)
        }
    }

    // MARK: - Layout variants

    private var compactGrid: some View {
        let cols = Self.glyphCols * 2 + Self.glyphGap + 2 // 9
        let rows = Self.glyphRows + 2 // 9
        return gridView(
            cols: cols,
            rows: rows,
            digitRightOffset: 1,
            cornerSkips: [.topLeft, .topRight, .bottomLeft, .bottomRight],
            leftFade: false
        )
    }

    private func fillContainerGrid(rightPadding: Int) -> some View {
        GeometryReader { geo in
            let cellSize = dotSize + dotSpacing
            let availableWidth = max(0, geo.size.width)
            let availableHeight = max(0, geo.size.height)

            let computedCols = Int((availableWidth + dotSpacing) / cellSize)
            let maxRows = Int((availableHeight + dotSpacing) / cellSize)

            // Always pad the digit symmetrically with full rows of ambient
            // dots — the "gutter" between the digit and the button edge is
            // unlit pixels, not empty space. Pick the largest
            // glyphRows + 2N that fits in the container.
            let extraPerSide = max(0, (maxRows - Self.glyphRows) / 2)
            let rows = Self.glyphRows + extraPerSide * 2

            let minCols = Self.glyphCols * 2 + Self.glyphGap + rightPadding + 1
            let cols = max(minCols, computedCols)

            let totalWidth = CGFloat(cols) * cellSize - dotSpacing
            let totalHeight = CGFloat(rows) * cellSize - dotSpacing

            gridView(
                cols: cols,
                rows: rows,
                digitRightOffset: rightPadding,
                cornerSkips: [.topRight, .bottomRight],
                leftFade: true
            )
            .frame(width: totalWidth, height: totalHeight)
            // Right-aligned horizontally, centered vertically.
            .position(
                x: geo.size.width - totalWidth / 2,
                y: geo.size.height / 2
            )
        }
    }

    // MARK: - Grid

    private func gridView(
        cols: Int,
        rows: Int,
        digitRightOffset: Int,
        cornerSkips: Set<Corner>,
        leftFade: Bool
    ) -> some View {
        let resolved = resolveDigits()
        let info = makeLayoutInfo(cols: cols, rows: rows, digitRightOffset: digitRightOffset)

        return VStack(spacing: dotSpacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: dotSpacing) {
                    ForEach(0..<cols, id: \.self) { col in
                        dotView(
                            row: row,
                            col: col,
                            cols: cols,
                            rows: rows,
                            cornerSkips: cornerSkips,
                            resolved: resolved,
                            info: info
                        )
                    }
                }
            }
        }
        .modifier(LeftFadeModifier(enabled: leftFade))
    }

    @ViewBuilder
    private func dotView(
        row: Int,
        col: Int,
        cols: Int,
        rows: Int,
        cornerSkips: Set<Corner>,
        resolved: ResolvedDigits,
        info: LayoutInfo
    ) -> some View {
        if isCornerSkipped(row: row, col: col, cols: cols, rows: rows, skips: cornerSkips) {
            Color.clear
                .frame(width: dotSize, height: dotSize)
        } else {
            let state = dotState(row: row, col: col, resolved: resolved, info: info)
            Circle()
                .fill(color)
                .saturation(state.saturation)
                .brightness(state.brightness)
                .opacity(state.opacity)
                .shadow(color: color.opacity(state.glow), radius: state.glow > 0 ? 4 : 0)
                .shadow(color: color.opacity(state.glow * 0.55), radius: state.glow > 0 ? 9 : 0)
                .frame(width: dotSize, height: dotSize)
                .animation(
                    .easeInOut(duration: 0.20).delay(Double(row) * 0.022),
                    value: label
                )
        }
    }

    // MARK: - Dot state

    private struct DotState {
        var opacity: Double
        var saturation: Double
        var brightness: Double
        var glow: Double
    }

    private func dotState(
        row: Int,
        col: Int,
        resolved: ResolvedDigits,
        info: LayoutInfo
    ) -> DotState {
        if isActiveDot(row: row, col: col, resolved: resolved, info: info) {
            if colorScheme == .light {
                // Reflective look: solid, slightly darkened color, no glow — so
                // lit dots read with strong contrast against a light surface.
                return DotState(opacity: 1.0, saturation: 1.08, brightness: -0.12, glow: 0)
            }
            return DotState(opacity: 1.0, saturation: 1.0, brightness: 0.22, glow: 0.95)
        }
        return ambientState(row: row, col: col)
    }

    private func isActiveDot(
        row: Int,
        col: Int,
        resolved: ResolvedDigits,
        info: LayoutInfo
    ) -> Bool {
        guard row >= info.digitRowStart, row <= info.digitRowEnd else { return false }
        let glyphRow = row - info.digitRowStart

        if let leftChar = resolved.left,
           col >= info.leftDigitColStart, col <= info.leftDigitColEnd {
            let glyphCol = col - info.leftDigitColStart
            if isGlyphPixelOn(char: leftChar, row: glyphRow, col: glyphCol) {
                return true
            }
        }

        if let rightChar = resolved.right,
           col >= info.rightDigitColStart, col <= info.rightDigitColEnd {
            let glyphCol = col - info.rightDigitColStart
            if isGlyphPixelOn(char: rightChar, row: glyphRow, col: glyphCol) {
                return true
            }
        }

        return false
    }

    /// Deterministic, low-variability ambient pattern. Three opacity buckets in
    /// a tight range plus a bit of saturation jitter so the off-dots feel like
    /// a real LED panel without competing with the lit digits.
    private func ambientState(row: Int, col: Int) -> DotState {
        let h = (row &* 31 &+ col &* 7) & 0xFF
        if colorScheme == .light {
            // Off dots become a desaturated neutral gray that's clearly visible
            // on a light surface, so the contrast between lit and unlit pixels
            // stays high (the dark-mode 0.07–0.13 color dots wash out on white).
            let buckets: [DotState] = [
                DotState(opacity: 0.16, saturation: 0, brightness: -0.1, glow: 0),
                DotState(opacity: 0.19, saturation: 0, brightness: -0.1, glow: 0),
                DotState(opacity: 0.22, saturation: 0, brightness: -0.1, glow: 0),
            ]
            return buckets[h % buckets.count]
        }
        let buckets: [DotState] = [
            DotState(opacity: 0.07, saturation: 0.65, brightness: 0, glow: 0),
            DotState(opacity: 0.10, saturation: 0.80, brightness: 0, glow: 0),
            DotState(opacity: 0.13, saturation: 0.90, brightness: 0, glow: 0),
        ]
        return buckets[h % buckets.count]
    }

    // MARK: - Label / glyph

    private struct ResolvedDigits {
        var left: Character?
        var right: Character?
    }

    private func resolveDigits() -> ResolvedDigits {
        if label == "Ad" {
            return ResolvedDigits(left: "A", right: "d")
        }
        let chars = Array(label)
        if chars.count == 1 {
            return ResolvedDigits(left: nil, right: chars[0])
        }
        if chars.count >= 2 {
            return ResolvedDigits(left: chars[chars.count - 2], right: chars[chars.count - 1])
        }
        return ResolvedDigits(left: nil, right: nil)
    }

    private func isGlyphPixelOn(char: Character, row: Int, col: Int) -> Bool {
        guard let rows = LEDScoreNumberView.glyphs[char] else { return false }
        guard row >= 0, row < rows.count else { return false }
        let rowChars = Array(rows[row])
        guard col >= 0, col < rowChars.count else { return false }
        return rowChars[col] == "#"
    }

    private static let glyphs: [Character: [String]] = [
        "0": [
            "###",
            "#.#",
            "#.#",
            "#.#",
            "#.#",
            "#.#",
            "###",
        ],
        "1": [
            ".#.",
            "##.",
            ".#.",
            ".#.",
            ".#.",
            ".#.",
            "###",
        ],
        "2": [
            "###",
            "..#",
            "..#",
            "###",
            "#..",
            "#..",
            "###",
        ],
        "3": [
            "###",
            "..#",
            "..#",
            "###",
            "..#",
            "..#",
            "###",
        ],
        "4": [
            "#.#",
            "#.#",
            "#.#",
            "###",
            "..#",
            "..#",
            "..#",
        ],
        "5": [
            "###",
            "#..",
            "#..",
            "###",
            "..#",
            "..#",
            "###",
        ],
        "6": [
            "###",
            "#..",
            "#..",
            "###",
            "#.#",
            "#.#",
            "###",
        ],
        "7": [
            "###",
            "..#",
            "..#",
            ".#.",
            ".#.",
            ".#.",
            ".#.",
        ],
        "8": [
            "###",
            "#.#",
            "#.#",
            "###",
            "#.#",
            "#.#",
            "###",
        ],
        "9": [
            "###",
            "#.#",
            "#.#",
            "###",
            "..#",
            "..#",
            "###",
        ],
        "A": [
            ".#.",
            "#.#",
            "#.#",
            "###",
            "#.#",
            "#.#",
            "#.#",
        ],
        "d": [
            "..#",
            "..#",
            "..#",
            "###",
            "#.#",
            "#.#",
            "###",
        ],
    ]

    // MARK: - Layout helpers

    private struct LayoutInfo {
        let leftDigitColStart: Int
        let leftDigitColEnd: Int
        let rightDigitColStart: Int
        let rightDigitColEnd: Int
        let digitRowStart: Int
        let digitRowEnd: Int
    }

    private func makeLayoutInfo(cols: Int, rows: Int, digitRightOffset: Int) -> LayoutInfo {
        let rightDigitColEnd = cols - 1 - digitRightOffset
        let rightDigitColStart = rightDigitColEnd - Self.glyphCols + 1
        let leftDigitColEnd = rightDigitColStart - 1 - Self.glyphGap
        let leftDigitColStart = leftDigitColEnd - Self.glyphCols + 1
        let digitRowStart = max(0, (rows - Self.glyphRows) / 2)
        let digitRowEnd = digitRowStart + Self.glyphRows - 1
        return LayoutInfo(
            leftDigitColStart: leftDigitColStart,
            leftDigitColEnd: leftDigitColEnd,
            rightDigitColStart: rightDigitColStart,
            rightDigitColEnd: rightDigitColEnd,
            digitRowStart: digitRowStart,
            digitRowEnd: digitRowEnd
        )
    }

    enum Corner: Hashable { case topLeft, topRight, bottomLeft, bottomRight }

    private func isCornerSkipped(
        row: Int,
        col: Int,
        cols: Int,
        rows: Int,
        skips: Set<Corner>
    ) -> Bool {
        if skips.contains(.topLeft), row == 0, col == 0 { return true }
        if skips.contains(.topRight), row == 0, col == cols - 1 { return true }
        if skips.contains(.bottomLeft), row == rows - 1, col == 0 { return true }
        if skips.contains(.bottomRight), row == rows - 1, col == cols - 1 { return true }
        return false
    }
}

private struct LeftFadeModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.65), location: 0.18),
                        .init(color: .black, location: 0.32),
                        .init(color: .black, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        LEDScoreNumberView(label: "0", color: ScoreKeepBrand.iconPurple)
        LEDScoreNumberView(label: "21", color: ScoreKeepBrand.iconPurple)
        LEDScoreNumberView(label: "Ad", color: ScoreKeepBrand.iconPurple)
    }
    .padding()
    .background(Color.black)
}
