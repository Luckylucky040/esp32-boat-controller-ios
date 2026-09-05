import SwiftUI

/// Top-down view of a boat with an animated rudder.
/// `rudderPosition` is normalized: -1 = full left, 0 = center, +1 = full right.
struct BoatView: View {

    let rudderPosition: Double
    var steeringDirection: SteeringCommand? = nil

    private var clampedPosition: Double {
        min(1, max(-1, rudderPosition))
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                water(in: size)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                BoatHullShape()
                    .fill(hullGradient)
                    .frame(width: size * 0.62, height: size * 0.9)
                    .overlay {
                        BoatHullShape()
                            .stroke(Color.white.opacity(0.85), lineWidth: 2)
                            .frame(width: size * 0.62, height: size * 0.9)
                    }

                deck(size: size)
                rudder(size: size)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(0.78, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Boat rudder indicator")
        .accessibilityValue(rudderAccessibilityText)
    }

    // MARK: - Layers

    private func water(in size: CGFloat) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.32, blue: 0.46),
                         Color(red: 0.08, green: 0.48, blue: 0.62)],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: size * 0.9)
                .offset(x: -size * 0.3, y: -size * 0.35)

            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: size * 0.7)
                .offset(x: size * 0.32, y: size * 0.3)
        }
    }

    private var hullGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.92, green: 0.94, blue: 0.96),
                     Color(red: 0.78, green: 0.82, blue: 0.87)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func deck(size: CGFloat) -> some View {
        Capsule()
            .fill(Color(red: 0.22, green: 0.27, blue: 0.33))
            .frame(width: size * 0.3, height: size * 0.48)
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                    .frame(width: size * 0.3, height: size * 0.48)
            }
            .offset(y: -size * 0.08)
    }

    private func rudder(size: CGFloat) -> some View {
        let bladeWidth = size * 0.07
        let bladeHeight = size * 0.16
        let pivotY = size * 0.36

        return ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.05, height: size * 0.05)

            RoundedRectangle(cornerRadius: bladeWidth / 3, style: .continuous)
                .fill(rudderColor)
                .frame(width: bladeWidth, height: bladeHeight)
                .overlay {
                    RoundedRectangle(cornerRadius: bladeWidth / 3, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        .frame(width: bladeWidth, height: bladeHeight)
                }
                .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                .offset(y: bladeHeight / 2)
        }
        .rotationEffect(.degrees(clampedPosition * 45))
        .offset(y: pivotY)
    }

    private var rudderColor: Color {
        switch steeringDirection {
        case .left: return Color(red: 0.96, green: 0.45, blue: 0.32)
        case .right: return Color(red: 0.35, green: 0.78, blue: 0.46)
        case .center, nil: return Color(red: 0.25, green: 0.55, blue: 0.85)
        }
    }

    private var rudderAccessibilityText: String {
        let offset = Int((clampedPosition * 45).rounded())
        switch offset {
        case ..<0: return "Rudder \(abs(offset)) degrees left"
        case 0: return "Rudder centered"
        default: return "Rudder \(offset) degrees right"
        }
    }
}

/// Simple top-down boat hull: rounded bow tapering to a flat stern.
struct BoatHullShape: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.42),
            control1: CGPoint(x: width * 0.98, y: height * 0.05),
            control2: CGPoint(x: width, y: height * 0.2)
        )
        path.addLine(to: CGPoint(x: width, y: height * 0.9))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: height * 0.9),
            control: CGPoint(x: width * 0.5, y: height)
        )
        path.addLine(to: CGPoint(x: 0, y: height * 0.42))
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: 0, y: height * 0.2),
            control2: CGPoint(x: width * 0.02, y: height * 0.05)
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 24) {
        BoatView(rudderPosition: -1, steeringDirection: .left)
        BoatView(rudderPosition: 0)
        BoatView(rudderPosition: 1, steeringDirection: .right)
    }
    .padding()
    .background(Color.black)
}
