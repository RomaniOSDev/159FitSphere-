import SwiftUI

struct TrainContainerView: View {
    private enum Segment: String, CaseIterable, Identifiable {
        case routines = "Routines"
        case stats = "Training Stats"

        var id: String { rawValue }
    }

    @State private var segment: Segment = .routines

    var body: some View {
        VStack(spacing: 0) {
            Picker("Train", selection: $segment) {
                ForEach(Segment.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .fitSphereInsetPanel(cornerRadius: 16)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .onChange(of: segment) { _ in
                HapticSound.tapLight()
            }

            Group {
                switch segment {
                case .routines:
                    Feature2View()
                case .stats:
                    Feature3View()
                }
            }
        }
    }
}
