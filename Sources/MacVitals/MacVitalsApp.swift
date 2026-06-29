import AppKit
import SwiftUI

@main
@MainActor
final class MacVitalsApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let monitor = SystemMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let contentView = DashboardView()
            .environmentObject(monitor)
            .frame(width: 380, height: 560)

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 560)
        popover.contentViewController = NSHostingController(rootView: contentView)

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        item.button?.target = self
        item.button?.action = #selector(togglePopover)

        monitor.onStatsChanged = { [weak self] stats in
            guard let self else { return }
            self.statusItem?.button?.title = stats.menuBarTitle(for: self.monitor.settings.menuBarDisplayMode)
        }
        monitor.start()
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
}
