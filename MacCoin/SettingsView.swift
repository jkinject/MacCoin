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

    private var sortedSelectedCoins: [CoinSymbol] {
        CoinSymbol.allCases.filter { binanceService.selectedCoins.contains($0) }
    }

    var body: some View {
        Form {
            Section("추적할 코인") {
                ForEach(CoinSymbol.allCases) { coin in
                    Toggle(coin.displayName, isOn: Binding(
                        get: { binanceService.selectedCoins.contains(coin) },
                        set: { _ in binanceService.toggleCoin(coin) }
                    ))
                    .disabled(coin == .btc)
                }
            }

            Section("메뉴바 표시") {
                Picker("표시할 코인", selection: $binanceService.menuBarCoin) {
                    ForEach(sortedSelectedCoins) { coin in
                        Text(coin.displayName).tag(coin)
                    }
                }
                Toggle("심볼 숨기기", isOn: $binanceService.hideSymbol)
            }

            Section("폴링 주기") {
                Picker("주기", selection: $selectedInterval) {
                    ForEach(intervals, id: \.1) { label, value in
                        Text(label).tag(value)
                    }
                }
                .onChange(of: selectedInterval) { _, newValue in
                    binanceService.updatePollingInterval(newValue)
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 350, height: 480)
        .onAppear {
            selectedInterval = binanceService.pollingInterval
        }
    }
}
