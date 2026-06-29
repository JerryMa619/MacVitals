import AppKit
import SwiftUI

@main
@MainActor
final class MacVitalsApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let monitor = SystemMonitor()
    private let onboardingStore = OnboardingStore()
    private var settingsWindow: NSWindow?
    private var dashboardWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let contentView = DashboardView { [weak self] in
            self?.showSettingsWindow()
        }
            .environmentObject(monitor)
            .frame(width: 380, height: 560)

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 560)
        popover.contentViewController = NSHostingController(rootView: contentView)

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        item.button?.target = self
        item.button?.action = #selector(togglePopover)
        item.button?.image = NSImage(systemSymbolName: "memorychip", accessibilityDescription: "MacVitals")
        item.button?.image?.isTemplate = true
        item.button?.imagePosition = .imageLeading
        item.button?.toolTip = "MacVitals"
        updateStatusItem(with: monitor.stats)

        monitor.onStatsChanged = { [weak self] stats in
            guard let self else { return }
            self.updateStatusItem(with: stats)
        }
        monitor.start()

        if !onboardingStore.hasCompleted {
            showOnboardingWindow()
        } else {
            showDashboardWindow()
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if popover.isShown {
            monitor.setFocused(false)
            popover.performClose(nil)
        } else {
            monitor.setFocused(true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    private func updateStatusItem(with stats: SystemStats) {
        let title = stats.menuBarTitle(for: monitor.settings.menuBarDisplayMode)
        statusItem?.button?.title = title
        statusItem?.button?.toolTip = "MacVitals - \(title)"
    }

    private func showDashboardWindow() {
        if let dashboardWindow {
            dashboardWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = DashboardView { [weak self] in
            self?.showSettingsWindow()
        }
            .environmentObject(monitor)
            .frame(width: 380, height: 560)
        let controller = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: controller)
        window.title = "MacVitals"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        dashboardWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showSettingsWindow() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = NSHostingController(rootView: SettingsView {
            self.showOnboardingWindow()
        }.environmentObject(monitor))
        let window = NSWindow(contentViewController: controller)
        window.title = L.t("action.settings")
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showOnboardingWindow() {
        if let onboardingWindow {
            onboardingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = NSHostingController(rootView: OnboardingView { [weak self] in
            guard let self else { return }
            self.onboardingStore.markCompleted()
            self.onboardingWindow?.close()
        })
        let window = NSWindow(contentViewController: controller)
        window.title = L.t("onboarding.windowTitle")
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        onboardingWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
