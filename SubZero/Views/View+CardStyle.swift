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
