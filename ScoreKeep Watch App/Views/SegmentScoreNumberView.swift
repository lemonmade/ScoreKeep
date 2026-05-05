//
//  SegmentScoreNumberView.swift
//  ScoreKeep Watch App
//
//  Classic 7-segment ("calculator / clock") and 14-segment ("alphanumeric"
//  with diagonals) score display styles. Both variants render the same digit
//  shapes — the visible difference is that the 14-segment variant always
//  shows a faint set of unlit center / diagonal segments behind the digit,
//  giving it that richer alphanumeric panel feel.
//

import SwiftUI

enum SegmentScoreVariant: Equatable {
    case seven
    case fourteen
}

struct SegmentScoreNumberView: View {
    let label: String
    let color: Color
    let variant: SegmentScoreVariant
    /// When true, single-digit labels are padded with a left-hand slot whose
    /// segments are all rendered as unlit "ghost" outlines — the digit's
    /// frame is visible but no segments are lit. Distinct from a leading
    /// "0" (which would light up a/b/c/d/e/f), this preserves the
    /// empty-display look real LED scoreboards use before the tens place
    /// has activated. Used for any game whose score can reach 10+, plus
    /// tennis (whose 15/30/40/Ad labels are already two-char).
    var showLeadingDigitSlot: Bool = true
    var layout: Layout = .compact

    enum Layout: Equatable {
        case compact
        case fillContainer
    }

    /// Sentinel character that doesn't match any glyph in the lit-table —
    /// passing it as the slot's char causes every segment to render as
    /// unlit (ghost) and leaves the slot looking like an empty digit frame.
    private static let emptyFrameChar: Character = " "

    private var resolved: ResolvedDigits {
        if label == "Ad" {
            return ResolvedDigits(left: "A", right: "d")
        }
        let chars = Array(label)
        if chars.count == 1 {
            let leftChar: Character? = showLeadingDigitSlot ? Self.emptyFrameChar : nil
            return ResolvedDigits(left: leftChar, right: chars[0])
        }
        if chars.count >= 2 {
            return ResolvedDigits(left: chars[chars.count - 2], right: chars[chars.count - 1])
        }
        return ResolvedDigits(left: nil, right: nil)
    }

    var body: some View {
        switch layout {
        case .compact:
            compactBody
        case .fillContainer:
            fillContainerBody
        }
    }

    // MARK: - Compact

    private var compactBody: some View {
        let digitHeight: CGFloat = 60
        let digitWidth: CGFloat = digitHeight * 0.58
        let spacing: CGFloat = digitWidth * 0.22

        return HStack(spacing: spacing) {
            digitView(char: resolved.left, width: digitWidth, height: digitHeight)
            digitView(char: resolved.right, width: digitWidth, height: digitHeight)
        }
    }

    // MARK: - Fill container (active match button background)

    private var fillContainerBody: some View {
        GeometryReader { geo in
            let verticalInset: CGFloat = 9
            let trailingInset: CGFloat = 12
            let digitHeight = max(20, geo.size.height - 2 * verticalInset)
            let digitWidth = digitHeight * 0.58
            let spacing = digitWidth * 0.22
            let totalWidth = digitWidth * 2 + spacing

            HStack(spacing: spacing) {
                digitView(char: resolved.left, width: digitWidth, height: digitHeight)
                digitView(char: resolved.right, width: digitWidth, height: digitHeight)
            }
            .frame(width: totalWidth, height: digitHeight)
            .position(
                x: geo.size.width - totalWidth / 2 - trailingInset,
                y: geo.size.height / 2
            )
        }
    }

    @ViewBuilder
    private func digitView(char: Character?, width: CGFloat, height: CGFloat) -> some View {
        if let char {
            // A real glyph (digit or A/d) lights up its segments; the empty-
            // frame sentinel falls through to the `default` branch in the
            // lit-table and renders all segments as unlit ghosts.
            SegmentDigitView(char: char, color: color, variant: variant)
                .frame(width: width, height: height)
        } else {
            // Slot suppressed entirely — used when the game can never reach
            // 10+ so a tens slot would just be visual noise.
            Color.clear.frame(width: width, height: height)
        }
    }

    private struct ResolvedDigits {
        var left: Character?
        var right: Character?
    }
}

// MARK: - Single digit

private struct SegmentDigitView: View {
    let char: Character
    let color: Color
    let variant: SegmentScoreVariant

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let thickness = min(w * 0.20, h * 0.12)

            ZStack {
                ForEach(segmentsForVariant, id: \.self) { segment in
                    SegmentShapeView(
                        segment: segment,
                        color: color,
                        thickness: thickness,
                        digitSize: CGSize(width: w, height: h),
                        isLit: SegmentDigitView.isLit(segment, char: char)
                    )
                }
            }
            .animation(.easeInOut(duration: 0.20), value: char)
        }
    }

    private var segmentsForVariant: [Segment] {
        switch variant {
        case .seven:
            return [.a, .b, .c, .d, .e, .f, .g7]
        case .fourteen:
            return [
                .a, .b, .c, .d, .e, .f,
                .g14Left, .g14Right,
                .h, .i, .j, .k, .l, .m,
            ]
        }
    }

    /// Lit-segment table for digits 0–9 plus tennis "Ad" (A, d). Diagonals and
    /// the center vertical (h, i, j, k, l, m) stay unlit for digits — they're
    /// the visual signature of the 14-segment variant when off.
    static func isLit(_ segment: Segment, char: Character) -> Bool {
        switch char {
        case "0":
            return [.a, .b, .c, .d, .e, .f].contains(segment)
        case "1":
            return [.b, .c].contains(segment)
        case "2":
            return [.a, .b, .g7, .g14Left, .g14Right, .e, .d].contains(segment)
        case "3":
            return [.a, .b, .g7, .g14Left, .g14Right, .c, .d].contains(segment)
        case "4":
            return [.f, .g7, .g14Left, .g14Right, .b, .c].contains(segment)
        case "5":
            return [.a, .f, .g7, .g14Left, .g14Right, .c, .d].contains(segment)
        case "6":
            return [.a, .f, .g7, .g14Left, .g14Right, .e, .c, .d].contains(segment)
        case "7":
            return [.a, .b, .c].contains(segment)
        case "8":
            return [.a, .b, .c, .d, .e, .f, .g7, .g14Left, .g14Right].contains(segment)
        case "9":
            return [.a, .b, .c, .d, .f, .g7, .g14Left, .g14Right].contains(segment)
        case "A":
            return [.a, .b, .c, .e, .f, .g7, .g14Left, .g14Right].contains(segment)
        case "d":
            return [.b, .c, .d, .e, .g7, .g14Left, .g14Right].contains(segment)
        default:
            return false
        }
    }
}

// MARK: - Segment shapes

private enum Segment: Hashable {
    /// Outer perimeter (shared between 7- and 14-segment variants).
    case a, b, c, d, e, f
    /// Single-piece middle horizontal — 7-segment only.
    case g7
    /// Split middle horizontal halves — 14-segment only.
    case g14Left, g14Right
    /// 14-segment center vertical and diagonals.
    case h, i, j, k, l, m
}

private struct SegmentShapeView: View {
    let segment: Segment
    let color: Color
    let thickness: CGFloat
    let digitSize: CGSize
    let isLit: Bool

    var body: some View {
        let placement = SegmentLayout.placement(
            for: segment,
            in: digitSize,
            thickness: thickness
        )
        Capsule()
            .fill(color)
            .frame(width: max(thickness, placement.length), height: thickness)
            .saturation(isLit ? 1.0 : 0.85)
            .brightness(isLit ? 0.22 : 0)
            .opacity(isLit ? 1.0 : 0.07)
            .shadow(color: color.opacity(isLit ? 0.85 : 0), radius: isLit ? 3.5 : 0)
            .shadow(color: color.opacity(isLit ? 0.5 : 0), radius: isLit ? 8 : 0)
            .rotationEffect(.radians(placement.rotationRadians))
            .position(placement.center)
    }
}

private struct SegmentPlacement {
    var x1: CGFloat
    var y1: CGFloat
    var x2: CGFloat
    var y2: CGFloat

    var length: CGFloat {
        let dx = x2 - x1
        let dy = y2 - y1
        return (dx * dx + dy * dy).squareRoot()
    }

    var center: CGPoint {
        CGPoint(x: (x1 + x2) / 2, y: (y1 + y2) / 2)
    }

    var rotationRadians: Double {
        atan2(Double(y2 - y1), Double(x2 - x1))
    }
}

private enum SegmentLayout {
    static func placement(
        for segment: Segment,
        in size: CGSize,
        thickness t: CGFloat
    ) -> SegmentPlacement {
        let W = size.width
        let H = size.height
        let gap = t * 0.4

        let leftX = t / 2
        let rightX = W - t / 2
        let topY = t / 2
        let middleY = H / 2
        let bottomY = H - t / 2
        let centerX = W / 2

        let topVertY1 = topY + t / 2 + gap
        let topVertY2 = middleY - t / 2 - gap
        let botVertY1 = middleY + t / 2 + gap
        let botVertY2 = bottomY - t / 2 - gap

        let horizX1 = leftX + t / 2 + gap
        let horizX2 = rightX - t / 2 - gap

        // Half-width of the gap between g14Left and g14Right.
        let halfMidGap = t * 0.6
        // Inset endpoints for diagonals so they don't crash through the
        // perimeter capsules at the corners.
        let diagInset = t * 0.5

        switch segment {
        case .a:
            return SegmentPlacement(x1: horizX1, y1: topY, x2: horizX2, y2: topY)
        case .b:
            return SegmentPlacement(x1: rightX, y1: topVertY1, x2: rightX, y2: topVertY2)
        case .c:
            return SegmentPlacement(x1: rightX, y1: botVertY1, x2: rightX, y2: botVertY2)
        case .d:
            return SegmentPlacement(x1: horizX1, y1: bottomY, x2: horizX2, y2: bottomY)
        case .e:
            return SegmentPlacement(x1: leftX, y1: botVertY1, x2: leftX, y2: botVertY2)
        case .f:
            return SegmentPlacement(x1: leftX, y1: topVertY1, x2: leftX, y2: topVertY2)
        case .g7:
            return SegmentPlacement(x1: horizX1, y1: middleY, x2: horizX2, y2: middleY)
        case .g14Left:
            return SegmentPlacement(
                x1: horizX1,
                y1: middleY,
                x2: centerX - halfMidGap,
                y2: middleY
            )
        case .g14Right:
            return SegmentPlacement(
                x1: centerX + halfMidGap,
                y1: middleY,
                x2: horizX2,
                y2: middleY
            )
        case .i:
            return SegmentPlacement(
                x1: centerX, y1: topVertY1,
                x2: centerX, y2: topVertY2
            )
        case .l:
            return SegmentPlacement(
                x1: centerX, y1: botVertY1,
                x2: centerX, y2: botVertY2
            )
        case .h:
            // Top-left diagonal: from near top of f down-right to middle of g.
            return SegmentPlacement(
                x1: leftX + diagInset,
                y1: topVertY1 + diagInset,
                x2: centerX - halfMidGap - diagInset,
                y2: topVertY2 - diagInset
            )
        case .j:
            // Top-right diagonal: from near top of b down-left to middle of g.
            return SegmentPlacement(
                x1: rightX - diagInset,
                y1: topVertY1 + diagInset,
                x2: centerX + halfMidGap + diagInset,
                y2: topVertY2 - diagInset
            )
        case .m:
            // Bottom-left diagonal: from near bottom of e up-right to middle.
            return SegmentPlacement(
                x1: leftX + diagInset,
                y1: botVertY2 - diagInset,
                x2: centerX - halfMidGap - diagInset,
                y2: botVertY1 + diagInset
            )
        case .k:
            // Bottom-right diagonal: from near bottom of c up-left to middle.
            return SegmentPlacement(
                x1: rightX - diagInset,
                y1: botVertY2 - diagInset,
                x2: centerX + halfMidGap + diagInset,
                y2: botVertY1 + diagInset
            )
        }
    }
}

#Preview("7-Segment") {
    HStack(spacing: 16) {
        SegmentScoreNumberView(label: "0", color: ScoreKeepBrand.iconPurple, variant: .seven)
        SegmentScoreNumberView(label: "21", color: ScoreKeepBrand.iconPurple, variant: .seven)
        SegmentScoreNumberView(label: "Ad", color: ScoreKeepBrand.iconPurple, variant: .seven)
    }
    .padding()
    .background(Color.black)
}

#Preview("14-Segment") {
    HStack(spacing: 16) {
        SegmentScoreNumberView(label: "0", color: ScoreKeepBrand.iconPurple, variant: .fourteen)
        SegmentScoreNumberView(label: "21", color: ScoreKeepBrand.iconPurple, variant: .fourteen)
        SegmentScoreNumberView(label: "Ad", color: ScoreKeepBrand.iconPurple, variant: .fourteen)
    }
    .padding()
    .background(Color.black)
}
