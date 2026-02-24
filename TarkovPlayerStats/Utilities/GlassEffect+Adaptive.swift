import SwiftUI

extension View {
    @ViewBuilder
    func adaptiveGlass(in shape: some Shape = .rect(cornerRadius: 16)) -> some View {
        self.background(shape.fill(.ultraThinMaterial))
    }

    @ViewBuilder
    func adaptiveGlassInteractive(in shape: some Shape = .rect(cornerRadius: 16)) -> some View {
        self.background(shape.fill(.ultraThinMaterial))
    }

    @ViewBuilder
    func adaptiveGlassTinted(_ color: Color, in shape: some Shape = .rect(cornerRadius: 16)) -> some View {
        self.background(shape.fill(.ultraThinMaterial))
                .overlay { shape.fill(color.opacity(0.15)) }
    }
}
