import AppKit
import SwiftUI

public typealias GivenWidgetSpace = (w: CGFloat, h: CGFloat)
/**
 * `ExpandedWidgetsStore` is a class that manages a collection of widgets for a "big panel" UI component.
 * It provides functionality to add, remove, show, hide, and clear widgets, while maintaining their visibility state.
 * The class is designed to work with SwiftUI and uses the `@Published` property wrapper to notify observers of changes.
 */
class ExpandedWidgetsStore: PanelManager, ObservableObject {
    @Published var widgets: [WidgetEntry] = []
    @Published var layoutGroup: LayoutGroup = .empty
    internal var lastLayoutGroup: LayoutGroup?
    
    func applyLayout(for group: LayoutGroup) {
        
        guard group != lastLayoutGroup else { return }
        lastLayoutGroup = group
        
        debugLog("(Expanded-Store) Layout For \(group.rawValue)", from: .panels)
        
        switch group {
            /// This means we wanna show NOTHING
        case .empty:
            self.hideWidget(named: "MusicPlayerWidget")
            self.hideWidget(named: "TimeWidget")
            self.hideWidget(named: "NotesWidget")
            self.hideWidget(named: "CameraWidget")
            self.hideWidget(named: "EventWidget")
            /// Music for expanded means that the notch is closed
            /// this means we dont need to show the shit in the notch
        case .music:
            self.hideWidget(named: "MusicPlayerWidget")
            self.hideWidget(named: "TimeWidget")
            self.hideWidget(named: "NotesWidget")
            self.hideWidget(named: "CameraWidget")
            self.hideWidget(named: "EventWidget")
            /// This means We Show All the Widgets, the showWidget
            /// function will manage if its not found, so its ok
        case .expanded:
            self.showWidget(named: "MusicPlayerWidget")
            self.showWidget(named: "TimeWidget")
            self.showWidget(named: "NotesWidget")
            self.showWidget(named: "CameraWidget")
            self.showWidget(named: "EventWidget")
            /// At the time of making this nothing in default
            /// but I want to add other things and it may be useful
        default:
            break
        }
        
    }
    
    public func determineWidthAndHeightForOneWidget() -> GivenWidgetSpace {
        let fullWidth = SettingsModel.shared.notchMaxWidth
        let numberOfWidgets = 1
        
        let w = fullWidth / CGFloat(numberOfWidgets) - 30
        let h = (ScrollManager.shared.getMaxPanelHeight() - ScrollManager.shared.getNotchHeight()) - 10
        
        return (w: w, h: h)
    }
    public func determineWidthAndHeight() -> GivenWidgetSpace {
        /// Settings Model Has the Full Width
        let fullWidth = SettingsModel.shared.notchMaxWidth
        let numberOfWidgets = SettingsModel.shared.selectedWidgets.count
        
        /// Now In This we can determine the width because it will be fullWidth / numberOfWidgets
        /// 10 Padding
        let w = fullWidth / CGFloat(numberOfWidgets) - 30
        let h = (ScrollManager.shared.getMaxPanelHeight() - ScrollManager.shared.getNotchHeight()) - 10
        
        return (w: w, h: h)
    }
    
    /// Adds a widget to the big panel "store"
    /// -   widget: The widget to add
    func addWidget(_ widget: Widget) {
        let widgetEntry = WidgetEntry(widget: widget, isVisible: false)
        // if widgets.count >= 4 {
        //     return
        // }
        widgets.append(widgetEntry)
    }
    
    /// Removes a widget from the big panel "store"
    /// This should be used by anything related to the "settings"
    /// -   name: name of the widget to remove
    func removeWidget(named name: String) {
        if widgets.isEmpty {
            return
        }
        withAnimation(Anim.spring) {
            if let index = widgets.firstIndex(where: { $0.widget.name == name }) {
                widgets.remove(at: index)
            }
        }
    }
    
    /**
     *  Hides a widget from the big panel "store"
     *  This is really the best way to "hide" or not show the widget
     *  when the panel is closed
     *  -  name: name of the widget to hide
     ***/
    func hideWidget(named name: String) {
        if let index = widgets.firstIndex(where: { $0.widget.name == name }) {
            widgets[index].isVisible = false
        }
    }
    
    /**
     *  Shows a widget from the big panel "store"
     *  This changes the visibility of the widget
     *  when the panel is open
     *  -  name: name of the widget to show
     ***/
    func showWidget(named name: String) {
        // Show from the hidden list if it exists
        if let index = widgets.firstIndex(where: { $0.widget.name == name }) {
            widgets[index].isVisible = true // Make the widget visible
            widgets[index] = WidgetEntry(
                widget: widgets[index].widget,
                isVisible: true
            )
        }
    }
    
    /// Function to remove all widgets from the big panel
    func clearWidgets() {
        debugLog("🗑️ Clearing all widgets from the big panel.", from: .panels)
        widgets.removeAll()
    }
}



/**
 * CompactWidgetsStore manages the widgets displayed in the notch panel area when the notch is closed and opened.
 * It handles the organization and visibility state of widgets, separating them into
 * left and right aligned sections.
 *
 * The store maintains four arrays:
 * - leftWidgetsHidden: Widgets aligned to the left that are currently hidden
 * - leftWidgetsShown: Widgets aligned to the left that are currently visible
 * - rightWidgetsHidden: Widgets aligned to the right that are currently hidden
 * - rightWidgetsShown: Widgets aligned to the right that are currently visible
 */

class CompactWidgetsStore: PanelManager, ObservableObject {
    @Published var leftWidgetsHidden: [WidgetEntry] = []
    @Published var leftWidgetsShown: [WidgetEntry] = []
    @Published var rightWidgetsHidden: [WidgetEntry] = []
    @Published var rightWidgetsShown: [WidgetEntry] = []
    
    @Published var layoutGroup: LayoutGroup = .empty
    internal var lastLayoutGroup: LayoutGroup?
    
    public struct layoutPresets {
        /// Defining The Music Layout
        static let music: ([() -> Widget], [() -> Widget]) = (
            [{ CompactAlbumWidget() }],
            [{ FancyMovingBars() }]
        )
        
        /// Defining the Open Layout
        static let expanded: ([() -> Widget], [() -> Widget]) = (
            [{SettingsButtonWidget()}],
            [{QuickAccessWidget()}]
        )
    }
    
    
    public func loadWidgets() {
        let (leftPresets, rightPresets) = (
            layoutPresets.music.0 + layoutPresets.expanded.0,
            layoutPresets.music.1 + layoutPresets.expanded.1
        )
        
        let allPresets = leftPresets + rightPresets
        
        var index = 0
        
        func loadNextWidget() {
            guard index < allPresets.count else { return }
            
            let creator = allPresets[index]
            index += 1
            
            DispatchQueue.global(qos: .utility).async {
                let widget = creator()
                
                DispatchQueue.main.async {
                    self.addWidget(widget)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        loadNextWidget()
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            loadNextWidget()
        }
    }
    
    func applyLayout(for group: LayoutGroup) {
        
        guard group != lastLayoutGroup else { return }
        lastLayoutGroup = group
        
        debugLog("(Compact-Store) Layout For \(group.rawValue)", from: .panels)
        
        switch group {
        case .empty:
            self.hideWidget(named: "QuickAccessWidget")
            self.hideWidget(named: "AlbumWidget")
            self.hideWidget(named: "MovingDotsWidget")
            self.hideWidget(named: "MovingBars")
            self.hideWidget(named: "Settings")
            self.hideWidget(named: "Volume Icon")
            self.hideWidget(named: "Volume Number")
            self.hideWidget(named: "Brightness Icon")
            self.hideWidget(named: "Brightness Number")
        case .music:
            self.hideWidget(named: "Settings")
            self.hideWidget(named: "QuickAccessWidget")
            self.hideWidget(named: "Volume Icon")
            self.hideWidget(named: "Volume Number")
            self.hideWidget(named: "Brightness Icon")
            self.hideWidget(named: "Brightness Number")

            self.showWidget(named: "AlbumWidget")
            self.showWidget(named: "MovingDotsWidget")
            self.showWidget(named: "MovingBars")
        case .expanded:
            self.hideWidget(named: "AlbumWidget")
            self.hideWidget(named: "MovingDotsWidget")
            self.hideWidget(named: "MovingBars")
            self.hideWidget(named: "Volume Icon")
            self.hideWidget(named: "Volume Number")
            self.hideWidget(named: "Brightness Icon")
            self.hideWidget(named: "Brightness Number")

            self.showWidget(named: "Settings")
            self.showWidget(named: "QuickAccessWidget")
        case .volume:
            /// handle volume
            self.hideWidget(named: "AlbumWidget")
            self.hideWidget(named: "MovingDotsWidget")
            self.hideWidget(named: "MovingBars")
            self.hideWidget(named: "QuickAccessWidget")
            self.hideWidget(named: "Settings")
            self.hideWidget(named: "Brightness Icon")
            self.hideWidget(named: "Brightness Number")

            self.showWidget(named: "Volume Icon")
            self.showWidget(named: "Volume Number")
        case .brightness:
            self.hideWidget(named: "AlbumWidget")
            self.hideWidget(named: "MovingDotsWidget")
            self.hideWidget(named: "MovingBars")
            self.hideWidget(named: "QuickAccessWidget")
            self.hideWidget(named: "Settings")
            self.hideWidget(named: "Volume Icon")
            self.hideWidget(named: "Volume Number")
            
            self.showWidget(named: "Brightness Icon")
            self.showWidget(named: "Brightness Number")
        }
    }
    
    public func setVolumeWidgets(icon: VolumeIcon, number: VolumeNumber) {
        debugLog("Assigned Volume Widgets", from: .panels)
        addWidget(icon)
        addWidget(number)
    }
    
    public func setBrightnessWidgets(icon: BrightnessIcon, number: BrightnessNumber) {
        debugLog("Assigned Brightness Widgets", from: .panels)
        addWidget(icon)
        addWidget(number)
    }
    
    public func removeVolumeWidgets() {
        debugLog("Removed Volume Widgets", from: .panels)
        removeWidget(named: "Volume Icon")
        removeWidget(named: "Volume Number")
    }
    
    public func removeBrightnessWidgets() {
        debugLog("Removed Brightness Widgets", from: .panels)
        removeWidget(named: "Brightness Icon")
        removeWidget(named: "Brightness Number")
    }

    /**
     * Adds a new widget to the appropriate hidden array based on its alignment.
     * If no alignment is specified, the widget defaults to left alignment.
     *
     * - Parameter widget: The Widget to be added
     */
    func addWidget(_ widget: Widget) {
        let widgetEntry = WidgetEntry(widget: widget, isVisible: false)
        
        if let alignment = widget.alignment {
            switch alignment {
            case .left:
                leftWidgetsHidden.append(widgetEntry)
            case .right:
                rightWidgetsHidden.append(widgetEntry)
            }
        } else {
            leftWidgetsHidden.append(widgetEntry)
        }
    }
    
    /**
     * Hides a widget by moving it from the shown array to the hidden array.
     * The widget's visibility state is updated to false.
     *
     * - Parameter name: The name of the widget to hide
     */
    func hideWidget(named name: String) {
        if let index = leftWidgetsShown.firstIndex(where: { $0.widget.name == name }) {
            leftWidgetsShown[index].isVisible = false
            let widgetEntry = leftWidgetsShown.remove(at: index)
            leftWidgetsHidden.append(widgetEntry)
        }
        if let index = rightWidgetsShown.firstIndex(where: { $0.widget.name == name }) {
            rightWidgetsShown[index].isVisible = false
            let widgetEntry = rightWidgetsShown.remove(at: index)
            rightWidgetsHidden.append(widgetEntry)
        }
    }
    
    /**
     * Shows a widget by moving it from the hidden array to the shown array.
     * The widget's visibility state is updated to true.
     *
     * - Parameter name: The name of the widget to show
     */
    func showWidget(named name: String) {
        // Show from the hidden list if it exists
        if let index = leftWidgetsHidden.firstIndex(where: { $0.widget.name == name }) {
            leftWidgetsHidden[index].isVisible = true
            let widgetEntry = leftWidgetsHidden.remove(at: index)
            leftWidgetsShown.append(widgetEntry)
        }
        if let index = rightWidgetsHidden.firstIndex(where: { $0.widget.name == name }) {
            rightWidgetsHidden[index].isVisible = true
            let widgetEntry = rightWidgetsHidden.remove(at: index)
            rightWidgetsShown.append(widgetEntry)
        }
    }
    
    /**
     * Removes a widget from the store completely.
     * Currently not implemented.
     *
     * - Parameter name: The name of the widget to remove
     */
    func removeWidget(named name: String) {
        // No Implementation Needed
    }
    
    /**
     * Removes all widgets from the store.
     * Currently not implemented.
     */
    func clearWidgets() {
        // No Implementation Needed
    }
}


/// Extension for Compact Widget Store to show the items
extension CompactWidgetsStore {
    var leftWidgets: some View {
        HStack(spacing: 0) {
            ForEach(leftWidgetsShown.indices, id: \.self) { index in
                let widgetEntry = self.leftWidgetsShown[index]
                if widgetEntry.isVisible {
                    widgetEntry.widget.swiftUIView
                }
            }
        }
    }
    
    var rightWidgets: some View {
        HStack(spacing: 0) {
            ForEach(rightWidgetsShown.indices, id: \.self) { index in
                let widgetEntry = self.rightWidgetsShown[index]
                if widgetEntry.isVisible {
                    widgetEntry.widget.swiftUIView
                }
            }
        }
    }
}
