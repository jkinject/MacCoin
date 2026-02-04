import SwiftUI

enum CoinSymbol: String, CaseIterable, Identifiable, Codable {
    case btc = "BTC", eth = "ETH", xrp = "XRP", sol = "SOL", doge = "DOGE"
    var id: String { rawValue }
    var tradingPair: String { "\(rawValue)USDT" }
    var displayName: String { "\(rawValue)/USDT" }
}

struct BinanceTickerResponse: Decodable {
    let symbol: String
    let price: String
}

@MainActor
class BinanceService: ObservableObject {
    @Published var prices: [CoinSymbol: Double] = [:]
    @Published var errorMessage: String?
    @Published var selectedCoins: Set<CoinSymbol> = [.btc] {
        didSet { saveSelectedCoins() }
    }
    @Published var menuBarCoin: CoinSymbol = .btc {
        didSet { UserDefaults.standard.set(menuBarCoin.rawValue, forKey: "menuBarCoin") }
    }
    @Published var hideSymbol: Bool = false {
        didSet { UserDefaults.standard.set(hideSymbol, forKey: "hideSymbol") }
    }
    @Published var pollingInterval: Double = 60 {
        didSet { UserDefaults.standard.set(pollingInterval, forKey: "pollingInterval") }
    }

    private var timer: Timer?

    private static let integerFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 4
        return f
    }()

    static func formattedPrice(for coin: CoinSymbol, price: Double) -> String {
        let formatter = (price >= 10) ? integerFormatter : decimalFormatter
        return formatter.string(from: NSNumber(value: price)) ?? "---"
    }

    var menuBarTitle: String {
        guard let price = prices[menuBarCoin] else { return "?" }
        let formatted = Self.formattedPrice(for: menuBarCoin, price: price)
        return hideSymbol ? formatted : "\(menuBarCoin.rawValue) \(formatted)"
    }

    init() {
        loadSelectedCoins()
        loadMenuBarCoin()
        hideSymbol = UserDefaults.standard.bool(forKey: "hideSymbol")
        pollingInterval = UserDefaults.standard.object(forKey: "pollingInterval") as? Double ?? 60
        startPolling()
        Task { await fetchPrices() }
    }

    func fetchPrices() async {
        let coins = selectedCoins
        guard !coins.isEmpty else { return }

        let symbols = coins.map { "\"\($0.tradingPair)\"" }.joined(separator: ",")
        let urlString = "https://api.binance.com/api/v3/ticker/price?symbols=[\(symbols)]"
        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let tickers = try JSONDecoder().decode([BinanceTickerResponse].self, from: data)
            for ticker in tickers {
                if let coin = CoinSymbol.allCases.first(where: { $0.tradingPair == ticker.symbol }),
                   let value = Double(ticker.price) {
                    prices[coin] = value
                }
            }
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func startPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.fetchPrices()
            }
        }
    }

    func updatePollingInterval(_ interval: Double) {
        pollingInterval = interval
        startPolling()
    }

    func toggleCoin(_ coin: CoinSymbol) {
        if coin == .btc { return }
        if selectedCoins.contains(coin) {
            selectedCoins.remove(coin)
            if menuBarCoin == coin {
                menuBarCoin = .btc
            }
            prices.removeValue(forKey: coin)
        } else {
            selectedCoins.insert(coin)
            Task { await fetchPrices() }
        }
    }

    // MARK: - Persistence

    private func saveSelectedCoins() {
        let rawValues = selectedCoins.map { $0.rawValue }
        UserDefaults.standard.set(rawValues, forKey: "selectedCoins")
    }

    private func loadSelectedCoins() {
        if let rawValues = UserDefaults.standard.stringArray(forKey: "selectedCoins") {
            let coins = Set(rawValues.compactMap { CoinSymbol(rawValue: $0) })
            selectedCoins = coins.isEmpty ? [.btc] : coins
        }
    }

    private func loadMenuBarCoin() {
        if let raw = UserDefaults.standard.string(forKey: "menuBarCoin"),
           let coin = CoinSymbol(rawValue: raw),
           selectedCoins.contains(coin) {
            menuBarCoin = coin
        }
    }
}
