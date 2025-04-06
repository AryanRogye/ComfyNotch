import AppKit
import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

struct AIChatWidget : View, SwiftUIWidget {

    var name: String = "AIChatWidget"

    @StateObject var settings : SettingsModel = SettingsModel.shared

    @State private var inputText: String = ""
    @State private var outputText: String = "Response will appear here."
    @State private var messages: [ChatMessage] = []

    var body : some View {
        ScrollView{
            // VStack {
            //     HStack {
            //         Picker("", selection: $settings.selectedProvider) {
            //             ForEach(AIProvider.allCases, id: \.self) { provider in
            //                 Text(provider.rawValue).tag(provider)
            //             }
            //         }
            //         showModels()
            //     }
            //     ForEach(messages) { message in
            //         HStack {
            //             if message.isUser {
            //                 Spacer()
            //                 Text(message.content)
            //                     .padding(10)
            //                     .background(Color.blue)
            //                     .foregroundColor(.white)
            //                     .cornerRadius(15)
            //                     .frame(maxWidth: 250, alignment: .trailing)
            //             } else {
            //                 Text(message.content)
            //                     .padding(10)
            //                     .background(Color.gray.opacity(0.2))
            //                     .cornerRadius(15)
            //                     .frame(maxWidth: 250, alignment: .leading)
            //                 Spacer()
            //             }
            //         }
            //     }
            //     HStack {
            //         TextField("Enter your prompt...", text: $inputText)
            //             .textFieldStyle(RoundedBorderTextFieldStyle())
                
            //         Button(action: sendMessage) {
            //             Text("Send")
            //                 .background(Color.blue)
            //                 .foregroundColor(.white)
            //         }
            //     }
            //     Text(outputText)
            //         .background(Color.black.opacity(0.1))
            // }
        }
        .padding(3)
    }

    @ViewBuilder
    func idkYet() -> some View {
        VStack {
            ScrollView {
                VStack(spacing: 10) {
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            
            HStack {
                TextField("Enter your prompt...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    sendMessage()
                }) {
                    Text("Send")
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .padding(3)
    }

    func sendMessage() {
        // let userMessage = ChatMessage(content: inputText, isUser: true)
        // messages.append(userMessage)
        
        // let requestBody: [String: Any] = [
        //     "model": "gpt-3.5-turbo",
        //     "messages": [
        //         ["role": "system", "content": "You are a helpful assistant."],
        //         ["role": "user", "content": inputText]
        //     ],
        //     "temperature": 0.7
        // ]
        
        // do {
        //     let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        //     let client = OpenAIClient(apiKey: settings.ai_api_key, body: jsonData)
            
        //     client.performRequest { result in
        //         DispatchQueue.main.async {
        //             switch result {
        //             case .success(let responseText):
        //                 let aiMessage = ChatMessage(content: responseText, isUser: false)
        //                 messages.append(aiMessage)
        //                 inputText = ""
        //             case .failure(let error):
        //                 let errorMessage = ChatMessage(content: "Error: \(error.localizedDescription)", isUser: false)
        //                 messages.append(errorMessage)
        //             }
        //         }
        //     }
        // } catch {
        //     let errorMessage = ChatMessage(content: "Failed to create JSON request body.", isUser: false)
        //     messages.append(errorMessage)
        // }
    }

    @ViewBuilder
    func showModels() -> some View {
        // if settings.selectedProvider == .openAI {
        //     Picker("", selection: $settings.selectedOpenAIModel) {
        //         ForEach(OpenAIModel.allCases, id: \.self) { model in
        //             Text(model.rawValue).tag(model)
        //         }
        //     }
        // } else if settings.selectedProvider == .anthropic {
        //     Picker("", selection: $settings.selectedAnthropicModel) {
        //         ForEach(AnthropicModel.allCases, id: \.self) { model in
        //             Text(model.rawValue).tag(model)
        //         }
        //     }
        // } else if settings.selectedProvider == .google {
        //     Picker("", selection: $settings.selectedGoogleModel) {
        //         ForEach(GoogleModel.allCases, id: \.self) { model in
        //             Text(model.rawValue).tag(model)
        //         }
        //     }
        // } else {
        //     Text("No models available")
        // }
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}

// class AIChatWidget : Widget {
//     var name: String = "AIChatWidget"
//     var view: NSView

//     private var hostingController: NSHostingController<AIChatWidgetView>

//     init() {
//         view = NSView()
//         hostingController = NSHostingController(rootView: AIChatWidgetView(settings: SettingsModel.shared))

//         view = hostingController.view
//         view.wantsLayer = true
//         view.isHidden = true
//     }

//     func update() {
    
//     }

//     func show() {
//         view.isHidden = false
//     }

//     func hide() {
//         view.isHidden = true
//     }
// }