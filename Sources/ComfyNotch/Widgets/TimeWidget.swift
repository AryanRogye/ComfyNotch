import AppKit
import SwiftUI

struct TimeWidget : View, SwiftUIWidget {
    var name: String = "TimeWidget"

    @ObservedObject var model: TimeWidgetModel = TimeWidgetModel()

    var body: some View {
        Text(model.currentTime)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.leading, 10)
            .onAppear(perform: startTimer)
    }

    private static func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"
        return formatter.string(from: Date())
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            model.currentTime = TimeWidgetModel.getCurrentTime()
        }
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}

class TimeWidgetModel : ObservableObject {
    @Published var currentTime: String = TimeWidgetModel.getCurrentTime()

    private var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTime = TimeWidgetModel.getCurrentTime()
        }

    }

    static func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"
        return formatter.string(from: Date())
    }
}

// class TimeWidget : Widget {

//     var name: String = "TimeWidget"
//     var view: NSView

//     private var timeLabel: NSTextField
//     private var timer: Timer?


//     init() {
//         view = NSView()
//         view.isHidden = true

//         timeLabel = NSTextField(labelWithString: TimeWidget.getCurrentTime())
//         timeLabel.translatesAutoresizingMaskIntoConstraints = false
//         timeLabel.font = NSFont.boldSystemFont(ofSize: 14)
//         timeLabel.textColor = .white

//         view.addSubview(timeLabel)

//         // Add constraints to define the timeLabel's size and position
//         NSLayoutConstraint.activate([
//             timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//             timeLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
//             // Add optional padding if needed
//             timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 10),
//             timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -10),
//             timeLabel.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 10),
//             timeLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -10)
//         ])

//         view.translatesAutoresizingMaskIntoConstraints = false
//         view.wantsLayer = true

//         startTimer()
//     }

//     static func getCurrentTime() -> String {
//         let formatter = DateFormatter()
//         formatter.dateFormat = "h:mm:ss a"
//         return formatter.string(from: Date())
//     }
    
//     func startTimer() {
//         timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
//             self?.timeLabel.stringValue = TimeWidget.getCurrentTime()
//         }
//     }
    
//     func show() {
//         view.isHidden = false
//     }
    
//     func hide() {
//         view.isHidden = true
//     }
    
//     func update() {
//         timeLabel.stringValue = TimeWidget.getCurrentTime()
//     }
// }