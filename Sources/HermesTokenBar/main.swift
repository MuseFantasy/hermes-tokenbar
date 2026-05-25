import AppKit
import HermesTokenCore

enum MenuTone {
    case normal
    case today
    case input
    case output
    case month
    case secondary
}

@MainActor
final class HermesTokenBarController: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let defaultDatabasePath = NSHomeDirectory() + "/.hermes/state.db"
    private lazy var databasePath: String = {
        ProcessInfo.processInfo.environment["HERMES_TOKENBAR_DB"] ?? defaultDatabasePath
    }()
    private var databasePathDisplay: String {
        if databasePath == defaultDatabasePath {
            return "~/.hermes/state.db"
        }
        return databasePath.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        log("applicationDidFinishLaunching")
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "0.0M"
        statusItem.button?.toolTip = "Hermes Token Bar"
        statusItem.menu = menu
        rebuildMenu(message: "Loading…")
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        log("statusItem initialized")
    }

    @objc private func refresh() {
        do {
            let stats = try HermesTokenStatsReader(databasePath: databasePath).read()
            update(with: stats)
        } catch {
            statusItem.button?.title = "!"
            rebuildMenu(message: "读取失败: \(error)")
            log("refresh failed: \(error)")
        }
    }

    private func update(with stats: HermesTokenStats) {
        statusItem.button?.title = "D \(formatMillions(stats.today.totalTokens))"
        log("updated: D \(formatMillions(stats.today.totalTokens))")
        menu.removeAllItems()

        addDisabled("Hermes Token Bar")
        addDisabled("Date: \(formatDay(stats.refreshedAt))", tone: .today)
        addDisabled("Since: 00:00 local", tone: .secondary)
        addDisabled("Today total: \(formatMillions(stats.today.totalTokens)) tokens", tone: .today)
        addDisabled("  Input: \(formatDetailTokens(stats.today.llmInputTokens)) tokens", tone: .input)
        addDisabled("  Output: \(formatDetailTokens(stats.today.llmOutputTokens)) tokens", tone: .output)
        addDisabled("Month total: \(formatMillions(stats.month.totalTokens)) tokens", tone: .month)
        addDisabled("  Input: \(formatDetailTokens(stats.month.llmInputTokens)) tokens", tone: .input)
        addDisabled("  Output: \(formatDetailTokens(stats.month.llmOutputTokens)) tokens", tone: .output)
        menu.addItem(.separator())

        if stats.topModels.isEmpty {
            addDisabled("Top models: no data", tone: .secondary)
        } else {
            addDisabled("Top models this month", tone: .secondary)
            for item in stats.topModels {
                addDisabled("  \(item.model): \(formatMillions(item.totalTokens))")
            }
        }

        menu.addItem(.separator())
        addDisabled("DB: \(databasePathDisplay)", tone: .secondary)
        addDisabled("Read-only · no hooks", tone: .secondary)
        addDisabled("Updated: \(formatDate(stats.refreshedAt))", tone: .secondary)
        menu.addItem(.separator())
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        let quitItem = NSMenuItem(title: "Quit HermesTokenBar", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func rebuildMenu(message: String) {
        menu.removeAllItems()
        addDisabled("Hermes Token Bar")
        addDisabled(message)
        menu.addItem(.separator())
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        let quitItem = NSMenuItem(title: "Quit HermesTokenBar", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func addDisabled(_ title: String, tone: MenuTone = .normal) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.attributedTitle = attributedMenuTitle(title, tone: tone)
        menu.addItem(item)
    }

    private func attributedMenuTitle(_ title: String, tone: MenuTone) -> NSAttributedString {
        let color: NSColor
        switch tone {
        case .normal:
            color = NSColor.labelColor
        case .today:
            color = NSColor.systemBlue
        case .input:
            color = NSColor.systemGreen
        case .output:
            color = NSColor.systemOrange
        case .month:
            color = NSColor.systemPurple
        case .secondary:
            color = NSColor.secondaryLabelColor
        }
        return NSAttributedString(
            string: title,
            attributes: [
                NSAttributedString.Key.foregroundColor: color,
                NSAttributedString.Key.font: NSFont.menuFont(ofSize: 0),
            ]
        )
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func formatMillions(_ value: Int64) -> String {
        let millions = Double(value) / 1_000_000
        let grouped = groupedNumber(millions, fractionDigits: 1)
        return "\(grouped)M"
    }

    private func formatDetailTokens(_ value: Int64) -> String {
        if value >= 1_000_000 {
            let grouped = groupedNumber(Double(value) / 1_000_000, fractionDigits: 1)
            return "\(grouped)M"
        }
        if value >= 1_000 {
            let grouped = groupedNumber(Double(value) / 1_000, fractionDigits: 1)
            return "\(grouped)K"
        }
        return groupedNumber(Double(value), fractionDigits: 0)
    }

    private func groupedNumber(_ value: Double, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.*f", fractionDigits, value)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func log(_ message: String) {
        let path = NSHomeDirectory() + "/Library/Logs/HermesTokenBar.log"
        let line = "\(Date()) \(message)\n"
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: path), let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: path)) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
            } else {
                try? data.write(to: URL(fileURLWithPath: path))
            }
        }
    }
}

@main
struct HermesTokenBarMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = HermesTokenBarController()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
        _ = delegate
    }
}
