import AppKit
import SwiftUI

@main
struct MacVitalsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var monitor = SystemMonitor()
    @State private var didStart = false
    @State private var showingSettings = false
    @State private var showingOnboarding = false

    private let onboardingStore = OnboardingStore()

    var body: some Scene {
        WindowGroup("MacVitals") {
            DashboardView {
                showingSettings = true
            }
            .environmentObject(monitor)
            .frame(minWidth: 380, minHeight: 560)
            .onAppear {
                startIfNeeded()
                NSApp.activate(ignoringOtherApps: true)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView {
                    showingOnboarding = true
                }
                .environmentObject(monitor)
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView {
                    onboardingStore.markCompleted()
                    showingOnboarding = false
                }
            }
        }
        .windowResizability(.contentSize)
    }

    private func startIfNeeded() {
        guard !didStart else { return }
        didStart = true
        NSApp.setActivationPolicy(.regular)
        monitor.start()
        appDelegate.configure(monitor: monitor)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private weak var monitor: SystemMonitor?

    func configure(monitor: SystemMonitor) {
        guard statusItem == nil else { return }
        self.monitor = monitor

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        item.button?.target = self
        item.button?.action = #selector(togglePopover)
        item.button?.image = NSImage(systemSymbolName: "memorychip", accessibilityDescription: "MacVitals")
        item.button?.image?.isTemplate = true
        item.button?.imagePosition = .imageLeading
        item.button?.toolTip = "MacVitals"

        let contentView = DashboardView(openSettings: {})
            .environmentObject(monitor)
            .frame(width: 380, height: 560)
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 560)
        popover.contentViewController = NSHostingController(rootView: contentView)

        monitor.onStatsChanged = { [weak self] stats in
            self?.updateStatusItem(with: stats)
        }
        updateStatusItem(with: monitor.stats)
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor?.stop()
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let monitor else { return }

        if popover.isShown {
            monitor.setFocused(false)
            popover.performClose(nil)
        } else {
            monitor.setFocused(true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func updateStatusItem(with stats: SystemStats) {
        guard let monitor else { return }
        let title = stats.menuBarTitle(for: monitor.settings.menuBarDisplayMode)
        statusItem?.button?.title = title
        statusItem?.button?.toolTip = "MacVitals - \(title)"
    }
}
