import AppKit

struct GitHubRelease: Decodable {
    let tagName: String
    let htmlUrl: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
        case assets
    }
}

struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadUrl: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
    }
}

@MainActor
class UpdateChecker: ObservableObject {
    @Published var isUpdateAvailable = false
    @Published var latestVersion: String?
    @Published var downloadURL: URL?

    private let repo = "jkinject/MacCoin"
    private var timer: Timer?
    private let checkInterval: TimeInterval = 3600 // 1시간

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    init() {
        Task { await checkForUpdate() }
        startPeriodicCheck()
    }

    func checkForUpdate() async {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else { return }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let remoteVersion = release.tagName.replacingOccurrences(of: "v", with: "")

            if isNewerVersion(remoteVersion, than: currentVersion) {
                self.isUpdateAvailable = true
                self.latestVersion = remoteVersion

                if let zipAsset = release.assets.first(where: { $0.name.hasSuffix(".zip") }),
                   let assetURL = URL(string: zipAsset.browserDownloadUrl) {
                    self.downloadURL = assetURL
                } else {
                    self.downloadURL = URL(string: release.htmlUrl)
                }
            } else {
                self.isUpdateAvailable = false
                self.latestVersion = nil
                self.downloadURL = nil
            }
        } catch {
            // 네트워크 오류 시 조용히 무시 (업데이트 체크 실패는 치명적이지 않음)
        }
    }

    func openDownloadPage() {
        guard let url = downloadURL else { return }
        NSWorkspace.shared.open(url)
    }

    private func isNewerVersion(_ remote: String, than local: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0) }
        let localParts = local.split(separator: ".").compactMap { Int($0) }

        let maxCount = max(remoteParts.count, localParts.count)
        for i in 0..<maxCount {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let l = i < localParts.count ? localParts[i] : 0
            if r > l { return true }
            if r < l { return false }
        }
        return false
    }

    private func startPeriodicCheck() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.checkForUpdate()
            }
        }
    }
}
