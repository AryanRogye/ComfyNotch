import AppKit
import Combine
import SwiftUI

enum HoverState {
    case hovering
    case notHovering
}

class HoverHandlerModel: ObservableObject {
    @Published var isPlaying: Bool = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to changes in the AudioManager's current song text and color.
        AudioManager.shared.$currentSongText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                DispatchQueue.main.async {
                    self?.isPlaying = text != "No Song Playing"
                }
            }
            .store(in: &cancellables)
    }
}

class HoverHandler: NSObject {  // Note: Now inheriting from NSObject
    private weak var panel: NSWindow?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var lastHapticTime: TimeInterval = 0

    private let expansionFactor: CGFloat = 1.5  // How much to grow (e.g., 1.1 = 10% bigger)
    private let animationDuration: TimeInterval = 0.2 // Animation duration

    private var originalFrame: NSRect
    private var originalWidth: CGFloat
    private var originalHeight: CGFloat

    private var expandedWidth: CGFloat
    private var expandedHeight: CGFloat

    private var collapseTimer: Timer?
    private var isUsingHapticFeedback: Bool = false

    private let padding: CGFloat = 10
    private let closingPadding: CGFloat = 50

    @ObservedObject var hoverHandlerModel = HoverHandlerModel()

    // Start with no hover state
    var hoverState: HoverState = .notHovering

    init(panel: NSWindow) {
        self.panel = panel
        // set original frame
        self.originalFrame = panel.frame
        self.originalWidth = originalFrame.width
        self.originalHeight = originalFrame.height

        // claculate the maximum possible width and height for the panel
        self.expandedWidth = originalWidth
        self.expandedHeight = originalHeight * expansionFactor

        super.init() // Important: call super.init() after setting properties but before other setup
        startListeningForMouseMoves()
    }

    deinit {
        stopMonitoring()
    }

    private func startListeningForMouseMoves() {
        // Local monitor for events in our application
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event)
            return event
        }

        // Global monitor for events outside our application
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event)
        }

        // Also add tracking area to the panel's content view
        if let contentView = panel?.contentView {
            let trackingArea = NSTrackingArea(
                rect: contentView.bounds,
                options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways],
                owner: self,
                userInfo: nil
            )
            contentView.addTrackingArea(trackingArea)
        }
    }

    private func stopMonitoring() {
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }

        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }

    private func handleMouseMoved(_ event: NSEvent) {
        guard let panel = panel else { return }

        // We need to convert the screen coordinates properly
        let mouseLocation = NSEvent.mouseLocation

        // 🧠 Padding zone in pixels

        // Get panel's frame in screen coordinates
        let panelFrame = panel.frame.insetBy(dx: -padding, dy: -padding)
        let openedPanelFrameWithPadding = panel.frame.insetBy(dx: -closingPadding, dy: -closingPadding)

        /// Before any check the first check is to make sure the "Hover Hide" and is close to the notch
        if ShortcutHandler.shared.isShortcutActive("Hover Hide") {
            // now we check if its in the pane
            if panelFrame.contains(mouseLocation) {
                // only then do we hide it
                UIManager.shared.smallPanel?.alphaValue = 0
                return
            }
        }
        /// For now just return this bottom part is messed up
        /// TODO: Fix this
        /// if anything was affected
        UIManager.shared.smallPanel?.alphaValue = 1

        /// No HoverHandler if no music is playing
        /// Simple check if the mouse is inside the panel's frame
        if panelFrame.contains(mouseLocation) {
            // Inside padding area

            // Cancel any pending collapse
            collapseTimer?.invalidate()
            collapseTimer = nil

            if UIManager.shared.panelState == .closed {
                if CACurrentMediaTime() - lastHapticTime > 0.2 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration * 0.6) {
                        self.triggerHapticFeedback()
                        self.lastHapticTime = CACurrentMediaTime()
                    }

                    // animatePanel(expand: hoverHandlerModel.isPlaying)
                }
            }

            hoverState = .hovering
        } else if !openedPanelFrameWithPadding.contains(mouseLocation) {
            // 🔴 Mouse is outside padded area
            // Don't double up timers
            if collapseTimer == nil {
                collapseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    guard let self else { return }

                    if UIManager.shared.panelState == .closed || UIManager.shared.panelState == .open {
                        /// Dont animate if the panel is already closed
                        // self.animatePanel(expand: false && self.hoverHandlerModel.isPlaying)
                        self.hoverState = .notHovering
                    }

                    self.collapseTimer = nil
                    // Reset haptic feedback state
                    self.isUsingHapticFeedback = false
                }
            }
        }
    }

    func collapsePanelIfExpanded() {
        guard let panel = self.panel else { return }

        if PanelAnimationState.shared.isExpanded {
            PanelAnimationState.shared.isExpanded = false
            PanelAnimationState.shared.bottomSectionHeight = 0

            let collapsedFrame = NSRect(
                x: self.originalFrame.origin.x,
                y: self.originalFrame.origin.y,
                width: self.originalWidth,
                height: self.originalHeight
            )

            NSAnimationContext.runAnimationGroup { context in
                context.duration = self.animationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(collapsedFrame, display: true)
            }
        }
    }

    private func triggerHapticFeedback() {
        if isUsingHapticFeedback {
            return
        }
        let hapticManager = NSHapticFeedbackManager.defaultPerformer
        hapticManager.perform(.levelChange, performanceTime: .now)
        // hapticManager.perform(.generic, performanceTime: .now)
        self.isUsingHapticFeedback = true
    }

    @objc func mouseEntered(with event: NSEvent) {
        debugLog("Mouse entered view")
        triggerHapticFeedback()
    }

    @objc func mouseExited(with event: NSEvent) {
        debugLog("Mouse exited view")
    }

    private func animatePanel(expand: Bool) {

        guard let panel = self.panel else { return }

        PanelAnimationState.shared.isExpanded = expand
        if expand {
            PanelAnimationState.shared.bottomSectionHeight = self.expandedHeight
        } else {
            PanelAnimationState.shared.bottomSectionHeight = 0

            // 2. Shrink panel a tiny moment later
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                let collapsedFrame = NSRect(
                    x: self.originalFrame.origin.x,
                    y: self.originalFrame.origin.y,
                    width: self.originalWidth,
                    height: self.originalHeight
                )

                NSAnimationContext.runAnimationGroup { context in
                    context.duration = self.animationDuration
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    panel.animator().setFrame(collapsedFrame, display: true)
                }
            }
        }
    }
}
