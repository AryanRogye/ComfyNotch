import AppKit
import SwiftUI

struct TimeWidget: View, Widget {
    var name: String = "TimeWidget"
    
    @ObservedObject var model: TimeWidgetModel = TimeWidgetModel()
    @State private var givenSpace : GivenWidgetSpace = (w: 0, h: 0)
    
    var body: some View {
        HStack {
            Text(model.currentTime)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .onAppear(perform: startTimer)
        }
        .frame(width: givenSpace.w, height: givenSpace.h)
        .onAppear {
            givenSpace = UIManager.shared.expandedWidgetStore.determineWidthAndHeight()
        }

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

class TimeWidgetModel: ObservableObject {
    @Published var currentTime: String = TimeWidgetModel.getCurrentTime()
    
    private var timer: Timer?
    
    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTime = TimeWidgetModel.getCurrentTime()
        }
    }
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"
        return formatter
    }()
    
    static func getCurrentTime() -> String {
        return timeFormatter.string(from: Date())
    }
}
