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