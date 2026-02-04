import SwiftUI

struct SettingsView: View {
    @ObservedObject var binanceService: BinanceService
    @State private var selectedInterval: Double = 60

    private let intervals: [(String, Double)] = [
        ("10초", 10),
        ("30초", 30),
        ("1분", 60),
        ("2분", 120),
        ("5분", 300),
    ]

    var body: some View {
        Form {
            Picker("폴링 주기", selection: $selectedInterval) {
                ForEach(intervals, id: \.1) { label, value in
                    Text(label).tag(value)
                }
            }
            .onChange(of: selectedInterval) { newValue in
                binanceService.updatePollingInterval(newValue)
            }
        }
        .padding(20)
        .frame(width: 300)
        .onAppear {
            selectedInterval = binanceService.pollingInterval
        }
    }
}
