//
//  OdometerScoreNumberView.swift
//  ScoreKeep Watch App
//
//  Mechanical odometer / drum-roll style score display. Each digit slot is a
//  vertical drum showing 0–9 stacked; on score change the drum rolls to
//  reveal the new digit, with the wrap from 9 → 0 continuing the upward
//  scroll the way a real odometer does (rather than snapping back).
//

import SwiftUI

struct OdometerScoreNumberView: View {
    let label: String
    let color: Color
    var showLeadingDigitSlot: Bool = true
    var layout: Layout = .compact

    enum Layout: Equatable {
        case compact
        case fillContainer
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

    var body: some View {
        switch layout {
        case .compact:
            compactBody
        case .fillContainer:
            fillContainerBody
        }
    }

    private var compactBody: some View {
        let h: CGFloat = 60
        let w: CGFloat = h * 0.66
        return HStack(spacing: 4) {
            slot(char: resolved.left, width: w, height: h)
            slot(char: resolved.right, width: w, height: h)
        }
    }

    private var fillContainerBody: some View {
        GeometryReader { geo in
            let verticalInset: CGFloat = 9
            let trailingInset: CGFloat = 10
            let h = max(20, geo.size.height - 2 * verticalInset)
            let w = h * 0.66
            let spacing: CGFloat = 4
            let totalWidth = w * 2 + spacing

            HStack(spacing: spacing) {
                slot(char: resolved.left, width: w, height: h)
                slot(char: resolved.right, width: w, height: h)
            }
            .frame(width: totalWidth, height: h)
            .position(
                x: geo.size.width - totalWidth / 2 - trailingInset,
                y: geo.size.height / 2
            )
        }
    }

    @ViewBuilder
    private func slot(char: Character?, width: CGFloat, height: CGFloat) -> some View {
        if let char {
            if let digit = Int(String(char)) {
                OdometerDigitReel(digit: digit, color: color)
                    .frame(width: width, height: height)
            } else {
                StaticOdometerCell(char: char, color: color)
                    .frame(width: width, height: height)
            }
        } else {
            Color.clear.frame(width: width, height: height)
        }
    }

    struct ResolvedDigits {
        var left: Character?
        var right: Character?
    }
}

// MARK: - Rolling drum

private struct OdometerDigitReel: View {
    let digit: Int
    let color: Color

    /// Continuous "rolling" counter — strip is rendered with `stripCells`
    /// repeating cycles of 0–9, and `position` indexes a particular cell.
    /// `position % 10` is always the visible digit. We pick the new
    /// `position` such that going 9→0 increments (continues rolling up) and
    /// 0→9 decrements (rolls back down) — natural odometer behavior.
    @State private var position: Int

    private static let stripCells = 100
    private static let stripCenter = 50

    init(digit: Int, color: Color) {
        self.digit = digit
        self.color = color
        self._position = State(initialValue: Self.stripCenter + digit)
    }

    var body: some View {
        GeometryReader { geo in
            let cellHeight = geo.size.height
            let cellWidth = geo.size.width
            let cornerRadius = min(cellWidth, cellHeight) * 0.13

            ZStack {
                drumBody(cornerRadius: cornerRadius)

                // The digit strip — exactly one cell tall window into a
                // 100-cell strip of repeating 0–9.
                VStack(spacing: 0) {
                    ForEach(0..<Self.stripCells, id: \.self) { i in
                        digitText(i % 10, height: cellHeight)
                            .frame(width: cellWidth, height: cellHeight)
                    }
                }
                .offset(y: -CGFloat(position) * cellHeight)

                // Drum-edge shading at top/bottom suggests the digit rolling
                // away around the drum's curvature.
                drumShading()
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .onChange(of: digit) { _, newDigit in
            advance(to: newDigit)
        }
    }

    private func advance(to newDigit: Int) {
        let currentDigit = ((position % 10) + 10) % 10
        var delta = newDigit - currentDigit
        // Shorter-path heuristic: 9→0 wraps forward by +1, 0→9 wraps
        // backward by -1, etc.
        if delta > 5 { delta -= 10 }
        else if delta < -5 { delta += 10 }

        let newPosition = position + delta

        withAnimation(.easeOut(duration: 0.32)) {
            position = newPosition
        } completion: {
            // If we've drifted near the strip's edges, instantly normalize
            // back toward the center. Same digit before/after (mod 10), so
            // it's invisible.
            if newPosition < 10 || newPosition > Self.stripCells - 10 {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    position = Self.stripCenter + ((newPosition % 10) + 10) % 10
                }
            }
        }
    }

    private func digitText(_ digit: Int, height: CGFloat) -> some View {
        Text("\(digit)")
            .font(.system(size: height * 0.78, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .brightness(0.10)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private func drumBody(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.78),
                        Color.black.opacity(0.55),
                        Color.black.opacity(0.78),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color.opacity(0.4), lineWidth: 0.6)
            )
    }

    private func drumShading() -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.black.opacity(0.55), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .frame(height: 9)

            Spacer(minLength: 0)

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .frame(height: 9)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Static cell (used for tennis "A" and "d")

private struct StaticOdometerCell: View {
    let char: Character
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let cornerRadius = min(geo.size.width, geo.size.height) * 0.13

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.78),
                                Color.black.opacity(0.55),
                                Color.black.opacity(0.78),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(color.opacity(0.4), lineWidth: 0.6)
                    )

                Text(String(char))
                    .font(.system(size: geo.size.height * 0.78, weight: .heavy, design: .rounded))
                    .foregroundStyle(color)
                    .brightness(0.10)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }
}

// MARK: - Previews

#Preview("Odometer — counting up") {
    struct Cycler: View {
        @State var value: Int = 0
        var body: some View {
            OdometerScoreNumberView(
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
