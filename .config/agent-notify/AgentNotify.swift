import AppKit
import UserNotifications

// URLs carry only random IDs; navigation targets stay in a private local directory.
struct Target: Codable {
    let socket: String
    let pane: String
    let tmux: String
    let title: String
    let body: String
}
let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/share/agent-notify/requests")
func loadTarget(_ id: String) -> Target? {
    guard UUID(uuidString: id) != nil,
          let data = try? Data(contentsOf: root.appendingPathComponent(id + ".json")),
          let target = try? JSONDecoder().decode(Target.self, from: data),
          target.pane.range(of: "^%[0-9]+$", options: .regularExpression) != nil else { return nil }
    return target
}
@discardableResult
func run(_ path: String, _ args: [String]) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: path)
    process.arguments = args
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    do {
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines)
    } catch { return nil }
}
func focus(_ id: String, activate: Bool = true) -> Bool {
    guard let target = loadTarget(id) else { return false }
    let base = ["-S", target.socket]
    guard let session = run(target.tmux, base + ["display-message", "-p", "-t", target.pane, "#{session_id}"]),
          run(target.tmux, base + ["select-window", "-t", target.pane]) != nil,
          run(target.tmux, base + ["select-pane", "-t", target.pane]) != nil else { return false }
    // Prefer the most recently used client; do not redirect every attached terminal.
    let clients = run(target.tmux, base + ["list-clients", "-F", "#{client_activity}\t#{client_name}"]) ?? ""
    let rows = clients.split(separator: "\n").map { $0.split(separator: "\t", maxSplits: 1).map(String.init) }
    if let client = rows.filter({ $0.count == 2 }).max(by: { (Int($0[0]) ?? 0) < (Int($1[0]) ?? 0) }) {
        guard run(target.tmux, base + ["switch-client", "-c", client[1], "-t", session]) != nil else { return false }
    } else { return false }
    if activate {
        _ = run("/usr/bin/osascript", ["-e", "tell application \"Ghostty\" to activate"])
    }
    return true
}

final class Delegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    let center = UNUserNotificationCenter.current()
    func applicationDidFinishLaunching(_ notification: Notification) {
        center.delegate = self
    }
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard url.scheme == "local-agent-notify", url.host == "notify" else { continue }
            let id = url.lastPathComponent
            guard let target = loadTarget(id) else { continue }
            center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                guard granted else {
                    NSLog("Agent Notify: notifications not permitted: %@", String(describing: error))
                    return
                }
                let content = UNMutableNotificationContent()
                content.title = target.title
                content.body = target.body
                content.sound = .default
                content.userInfo = ["target": id]
                let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
                self.center.add(request) { error in
                    if let error = error { NSLog("Agent Notify: delivery failed: %@", error.localizedDescription) }
                }
            }
        }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
           let id = response.notification.request.content.userInfo["target"] as? String {
            if !focus(id) { NSLog("Agent Notify: target no longer available or no tmux client attached") }
        }
        completionHandler()
    }
}
if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "--select-pane" {
    exit(focus(CommandLine.arguments[2], activate: false) ? 0 : 1)
}
if CommandLine.arguments.contains("--status") {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
        center.getDeliveredNotifications { notifications in
            print("authorization=\(settings.authorizationStatus.rawValue) delivered=\(notifications.count)")
            exit(0)
        }
    }
    RunLoop.main.run()
}
let app = NSApplication.shared
let delegate = Delegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
