import SwiftUI

/// Main screen of the boat controller.
struct ContentView: View {

    @StateObject private var viewModel = BoatControlViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                VStack(spacing: 20) {
                    ConnectionStatusView(viewModel: viewModel)

                    BoatView(
                        rudderPosition: viewModel.normalizedRudder,
                        steeringDirection: viewModel.steeringInput
                    )
                    .padding(.horizontal, 40)

                    rudderLabel

                    Spacer(minLength: 0)

                    SteeringControlsView(viewModel: viewModel)
                        .padding(.bottom, 8)
                }
                .padding(.top)
            }
            .navigationTitle("Boat Controller")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showConnectionSheet = true
                    } label: {
                        Label("Connect", systemImage: "antenna.radiowaves.left.and.right")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showConnectionSheet) {
                ConnectionSheetView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
            .alert("Bluetooth", isPresented: errorPresented, presenting: viewModel.bleManager.lastErrorMessage) { _ in
                Button("OK", action: viewModel.dismissError)
            } message: { message in
                Text(message)
            }
        }
        .tint(.cyan)
        .preferredColorScheme(.dark)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.05, green: 0.08, blue: 0.13),
                     Color(red: 0.08, green: 0.14, blue: 0.22)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var rudderLabel: some View {
        VStack(spacing: 2) {
            Text(viewModel.rudderAngleText)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text("RUDDER POSITION")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.secondary)
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.bleManager.lastErrorMessage != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )
    }
}

#Preview {
    ContentView()
}
