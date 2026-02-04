import SwiftUI

struct BinanceTickerResponse: Decodable {
    let symbol: String
    let price: String
}

@MainActor
class BinanceService: ObservableObject {
    @Published var price: Double?
    @Published var errorMessage: String?
    @AppStorage("pollingInterval") var pollingInterval: Double = 60

    private var timer: Timer?
    private let url = URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT")!

    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    var formattedPrice: String {
        guard let price else { return "---" }
        return (Self.priceFormatter.string(from: NSNumber(value: price)) ?? "---")
    }

    var menuBarTitle: String {
        guard price != nil else { return "?" }
        return formattedPrice
    }

    init() {
        startPolling()
        Task { await fetchPrice() }
    }

    func fetchPrice() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let ticker = try JSONDecoder().decode(BinanceTickerResponse.self, from: data)
            if let value = Double(ticker.price) {
                self.price = value
                self.errorMessage = nil
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func startPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.fetchPrice()
            }
        }
    }

    func updatePollingInterval(_ interval: Double) {
        pollingInterval = interval
        startPolling()
    }
}
