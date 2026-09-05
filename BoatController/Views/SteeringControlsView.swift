import SwiftUI

/// Large left/right touch areas that stream steering commands while held.
struct SteeringControlsView: View {

    @ObservedObject var viewModel: BoatControlViewModel

    var body: some View {
        HStack(spacing: 16) {
            SteeringButton(
                title: "LEFT",
                systemImage: "arrow.left.circle.fill",
                tint: Color(red: 0.96, green: 0.45, blue: 0.32),
                command: .left,
                isPressed: viewModel.steeringInput == .left,
                isEnabled: viewModel.isSteeringEnabled,
                onPressChanged: handlePress
            )

            SteeringButton(
                title: "RIGHT",
                systemImage: "arrow.right.circle.fill",
                tint: Color(red: 0.35, green: 0.78, blue: 0.46),
                command: .right,
                isPressed: viewModel.steeringInput == .right,
                isEnabled: viewModel.isSteeringEnabled,
                onPressChanged: handlePress
            )
        }
        .padding(.horizontal)
    }

    private func handlePress(_ command: SteeringCommand, _ isPressed: Bool) {
        if isPressed {
            viewModel.startSteering(command)
        } else {
            viewModel.stopSteering()
        }
    }
}

/// A single hold-to-steer button. Uses a `DragGesture` with zero distance so the
/// press starts immediately on touch-down and ends on release, even if the finger
/// slides slightly.
private struct SteeringButton: View {

    let title: String
    let systemImage: String
    let tint: Color
    let command: SteeringCommand
    let isPressed: Bool
    let isEnabled: Bool
    let onPressChanged: (SteeringCommand, Bool) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .bold))
            Text(title)
                .font(.headline.weight(.bold))
                .tracking(2)
            Text(isPressed ? "Steering…" : "Hold to steer")
                .font(.caption)
                .opacity(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .foregroundStyle(.white)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(tint.gradient)
                .opacity(isEnabled ? (isPressed ? 1.0 : 0.75) : 0.25)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(isPressed ? 0.9 : 0.3), lineWidth: isPressed ? 3 : 1)
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .shadow(color: tint.opacity(isPressed ? 0.6 : 0.25), radius: isPressed ? 12 : 6, y: 4)
        .animation(.spring(duration: 0.2), value: isPressed)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard isEnabled else { return }
                    if !isPressed {
                        onPressChanged(command, true)
                    }
                }
                .onEnded { _ in
                    onPressChanged(command, false)
                }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(title.lowercased()) steering")
        .accessibilityHint("Touch and hold to steer \(title.lowercased())")
    }
}

#Preview {
    SteeringControlsView(viewModel: BoatControlViewModel())
        .padding()
        .background(Color(red: 0.06, green: 0.09, blue: 0.14))
}
