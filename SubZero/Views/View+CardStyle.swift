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
                reduceMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.15, bounce: 0.1),
                value: configuration.isPressed
            )
    }
}
