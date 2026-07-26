//
//  View+CardStyle.swift
//  SubZero
//
//  Shared "card" look used for every panel across the app — material
//  background plus a soft elevation shadow — so every screen reads as one
//  consistent, premium visual language.
//

import SwiftUI

extension View {
    func cardBackground(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

extension Animation {
    /// `full` when motion is allowed, or a short crossfade-friendly curve
    /// when the user has Reduce Motion enabled — the one place every
    /// motion-sensitive animation in the app should get this fallback from,
    /// instead of each call site re-deriving its own reduced curve.
    static func motionAware(_ reduceMotion: Bool, full: Animation = .snappy) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : full
    }
}

extension AnyTransition {
    /// `full` when motion is allowed, or a plain crossfade when the user has
    /// Reduce Motion enabled — pairs with `Animation.motionAware(_:full:)`.
    static func motionAware(_ reduceMotion: Bool, full: AnyTransition) -> AnyTransition {
        reduceMotion ? .opacity : full
    }
}

/// Press feedback for card-style rows (`Button`/`NavigationLink` wrapped in
/// `.buttonStyle(.plain)` to suppress the system highlight) — without this,
/// tapping a card gives no visual confirmation the tap registered.
struct CardPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(
                .motionAware(reduceMotion, full: .spring(duration: 0.15, bounce: 0.1)),
                value: configuration.isPressed
            )
    }
}
