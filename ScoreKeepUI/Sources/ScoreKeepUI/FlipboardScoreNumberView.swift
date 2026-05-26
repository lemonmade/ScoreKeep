//
//  FlipboardScoreNumberView.swift
//  ScoreKeepUI
//
//  Solari-style "flipboard" score display — each digit is a rounded card with
//  a horizontal seam through the middle. On change, the old card flips
//  forward around its center axis while the new card unfolds in from behind,
//  evoking the volleyball / train-station split-flap feel.
//

import SwiftUI

public struct FlipboardScoreNumberView: View {
    let label: String
    let color: Color
    /// When true, always render a left-hand "tens" card — for single-digit
    /// labels it shows "0" so the panel reads as a complete two-card display.
    /// Used for any game whose score can reach 10+, plus tennis (whose
    /// "15"/"30"/"40"/"Ad" labels are already two characters and look weird
    /// when "0" / love is rendered as a single card next to them).
    var showLeadingDigitSlot: Bool = true
    var layout: Layout = .compact

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

    // MARK: - Compact

    private var compactBody: some View {
        let h: CGFloat = 60
        let w: CGFloat = h * 0.66
        let spacing: CGFloat = 4
        return HStack(spacing: spacing) {
            digitCard(char: resolved.left, width: w, height: h)
            digitCard(char: resolved.right, width: w, height: h)
        }
    }

    // MARK: - Fill container (active match panel)

    private var fillContainerBody: some View {
        GeometryReader { geo in
            let verticalInset: CGFloat = 9
            let trailingInset: CGFloat = 10
            let h = max(20, geo.size.height - 2 * verticalInset)
            let w = h * 0.66
            let spacing: CGFloat = 4
            let totalWidth = w * 2 + spacing

            HStack(spacing: spacing) {
                digitCard(char: resolved.left, width: w, height: h)
                digitCard(char: resolved.right, width: w, height: h)
            }
            .frame(width: totalWidth, height: h)
            .position(
                x: geo.size.width - totalWidth / 2 - trailingInset,
                y: geo.size.height / 2
            )
        }
    }

    @ViewBuilder
    private func digitCard(char: Character?, width: CGFloat, height: CGFloat) -> some View {
        if let char {
            FlippingDigitCard(char: char, color: color)
                .frame(width: width, height: height)
        } else {
            Color.clear.frame(width: width, height: height)
        }
    }

    struct ResolvedDigits {
        var left: Character?
        var right: Character?
    }
}

// MARK: - Flipping wrapper

/// Re-creates the card whenever `char` changes (via `.id(char)`) so the
/// asymmetric flip transition runs. The `.animation(value: char)` on the
/// container drives the implicit animation context the transition needs.
private struct FlippingDigitCard: View {
    let char: Character
    let color: Color

    var body: some View {
        ZStack {
            DigitCardContent(char: char, color: color)
                .id(char)
                .transition(.flipboardFlip)
        }
        .animation(.easeInOut(duration: 0.34), value: char)
    }
}

// MARK: - Card content

private struct DigitCardContent: View {
    let char: Character
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            let cornerRadius: CGFloat = min(w, h) * 0.13
            let seamHeight: CGFloat = max(1, h * 0.022)
            let isLight = colorScheme == .light

            // Light mode flips the card to a pale "Solari" tile with a darker
            // colored digit and a faint seam; dark mode keeps the glowing
            // digit on a black tile.
            let cardColors: [Color] = isLight
                ? [Color(white: 0.97), Color(white: 0.89)]
                : [Color.black.opacity(0.62), Color.black.opacity(0.42)]
            let seamColor = Color.black.opacity(isLight ? 0.12 : 0.7)

            ZStack {
                // Card body — gradient base with a faint colored border so it
                // reads as a physical panel rather than a flat fill.
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: cardColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(color.opacity(isLight ? 0.35 : 0.45), lineWidth: 0.8)
                    )

                // The digit itself.
                Text(String(char))
                    .font(.system(size: h * 0.78, weight: .heavy, design: .rounded))
                    .foregroundStyle(color)
                    .brightness(isLight ? -0.1 : 0.18)
                    .shadow(color: color.opacity(isLight ? 0 : 0.6), radius: isLight ? 0 : 3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                // Middle seam — the visual cue that this is a hinged card.
                Rectangle()
                    .fill(seamColor)
                    .frame(height: seamHeight)
                    .frame(maxWidth: .infinity)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

// MARK: - Flip transition

extension AnyTransition {
    static var flipboardFlip: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: FlipboardCardModifier(rotation: -90, opacity: 0),
                identity: FlipboardCardModifier(rotation: 0, opacity: 1)
            ),
            removal: .modifier(
                active: FlipboardCardModifier(rotation: 90, opacity: 0),
                identity: FlipboardCardModifier(rotation: 0, opacity: 1)
            )
        )
    }
}

private struct FlipboardCardModifier: ViewModifier {
    let rotation: Double
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(rotation),
                axis: (1, 0, 0),
                anchor: .center,
                perspective: 0.5
            )
            .opacity(opacity)
    }
}

// MARK: - Previews

#Preview("Flipboard — single digits") {
    HStack(spacing: 12) {
        FlipboardScoreNumberView(label: "0", color: ScoreKeepBrand.iconPurple)
        FlipboardScoreNumberView(label: "7", color: ScoreKeepBrand.iconPurple)
        FlipboardScoreNumberView(label: "Ad", color: ScoreKeepBrand.iconPurple)
    }
    .padding()
    .background(Color.black)
}

#Preview("Flipboard — counting up") {
    struct Cycler: View {
        @State var value: Int = 0
        var body: some View {
            FlipboardScoreNumberView(
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
