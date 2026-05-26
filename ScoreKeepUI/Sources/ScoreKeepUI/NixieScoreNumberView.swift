//
//  NixieScoreNumberView.swift
//  ScoreKeepUI
//
//  Nixie-tube-style score display. Each digit slot is a "glass tube" that
//  shows all of the cathode glyphs (0–9, plus A/d for tennis Ad) faintly
//  layered together — the active digit glows brightly in front with a heavy
//  halo, while the rest sit behind it as low-opacity ghosts, suggesting the
//  stacked-cathode depth of a real Nixie.
//

import SwiftUI

public struct NixieScoreNumberView: View {
    let label: String
    let color: Color
    /// When true, single-digit labels are padded with a leading "0" tube so
    /// the panel always reads as a complete two-tube display. Same intent as
    /// the flipboard's leading-digit slot.
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
        let w: CGFloat = h * 0.52
        let spacing: CGFloat = 4
        return HStack(spacing: spacing) {
            tube(char: resolved.left, width: w, height: h)
            tube(char: resolved.right, width: w, height: h)
        }
    }

    // MARK: - Fill container (active match panel)

    private var fillContainerBody: some View {
        GeometryReader { geo in
            let verticalInset: CGFloat = 9
            let trailingInset: CGFloat = 12
            let h = max(20, geo.size.height - 2 * verticalInset)
            let w = h * 0.52
            let spacing: CGFloat = 6
            let totalWidth = w * 2 + spacing

            HStack(spacing: spacing) {
                tube(char: resolved.left, width: w, height: h)
                tube(char: resolved.right, width: w, height: h)
            }
            .frame(width: totalWidth, height: h)
            .position(
                x: geo.size.width - totalWidth / 2 - trailingInset,
                y: geo.size.height / 2
            )
        }
    }

    @ViewBuilder
    private func tube(char: Character?, width: CGFloat, height: CGFloat) -> some View {
        if let char {
            NixieDigitTube(char: char, color: color)
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

// MARK: - Single tube

private struct NixieDigitTube: View {
    let char: Character
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    /// All glyphs that can ever appear in this tube (digits + tennis A/d).
    /// Rendering them all at low opacity behind the active digit gives the
    /// "ghost cathodes" depth illusion.
    private static let cathodeGlyphs: [Character] = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "d",
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cornerRadius: CGFloat = w * 0.22
            let isLight = colorScheme == .light

            ZStack {
                tubeHousing(width: w, height: h, cornerRadius: cornerRadius)

                // Inner ambient glow — picks up the team color and bleeds it
                // into the tube interior so the whole tube reads as "lit".
                // Toned down in light mode so the pale tube doesn't muddy.
                RoundedRectangle(cornerRadius: max(0, cornerRadius - 2), style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: isLight
                                ? [color.opacity(0.12), color.opacity(0.04), .clear]
                                : [color.opacity(0.32), color.opacity(0.12), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: w * 0.75
                        )
                    )
                    .padding(2)

                // Ghost cathodes: every glyph rendered at very low opacity
                // with a slight blur. The shapes overlap into a faint, fuzzy
                // suggestion of stacked wires — exactly the Nixie depth feel.
                ForEach(Self.cathodeGlyphs, id: \.self) { glyph in
                    glyphText(glyph, height: h)
                        .foregroundStyle(color)
                        .opacity(isLight ? 0.06 : 0.045)
                        .blur(radius: 0.6)
                }

                // Lit cathode: the active digit. Dark mode gets a brightness
                // boost and stacked color shadows for the warm halo; light
                // mode darkens it slightly and drops the glow for contrast.
                ZStack {
                    glyphText(char, height: h)
                        .foregroundStyle(color)
                        .brightness(isLight ? -0.12 : 0.30)
                        .shadow(color: color.opacity(isLight ? 0 : 0.95), radius: isLight ? 0 : 2.5)
                        .shadow(color: color.opacity(isLight ? 0 : 0.70), radius: isLight ? 0 : 6)
                        .shadow(color: color.opacity(isLight ? 0 : 0.45), radius: isLight ? 0 : 12)
                }
                .id(char)
                .transition(.opacity.combined(with: .scale(scale: 0.88)))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .animation(.easeInOut(duration: 0.20), value: char)
        }
    }

    private func glyphText(_ ch: Character, height: CGFloat) -> some View {
        Text(String(ch))
            .font(.system(size: height * 0.66, weight: .semibold, design: .serif))
            .lineLimit(1)
            .minimumScaleFactor(0.4)
    }

    private func tubeHousing(
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat
    ) -> some View {
        let isLight = colorScheme == .light
        return ZStack {
            // Glass body — slight horizontal gradient hints at the cylindrical
            // curvature of a real tube. Pale glass in light mode, dark in dark.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isLight
                            ? [Color(white: 0.97), Color(white: 0.90), Color(white: 0.97)]
                            : [Color.black.opacity(0.85), Color.black.opacity(0.62), Color.black.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Glass rim — a faint two-tone stroke giving the tube edge a
            // subtle highlight.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: isLight
                            ? [color.opacity(0.35), Color.black.opacity(0.06), color.opacity(0.22)]
                            : [color.opacity(0.45), Color.white.opacity(0.18), color.opacity(0.30)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
    }
}

// MARK: - Previews

#Preview("Nixie — single digits") {
    HStack(spacing: 12) {
        NixieScoreNumberView(label: "0", color: ScoreKeepBrand.iconPurple)
        NixieScoreNumberView(label: "7", color: ScoreKeepBrand.iconPurple)
        NixieScoreNumberView(label: "Ad", color: ScoreKeepBrand.iconPurple)
    }
    .padding()
    .background(Color.black)
}

#Preview("Nixie — counting up") {
    struct Cycler: View {
        @State var value: Int = 0
        var body: some View {
            NixieScoreNumberView(
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
