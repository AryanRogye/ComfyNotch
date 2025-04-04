import AppKit


protocol APIClient {
    var baseURL : String { get }
    var headers : [String : String] { get }
    var parameters : [String : String]? { get }
    var body: Data? { get }
    var method : HTTPMethod { get }

    func performRequest(completion: @escaping (Result<String, Error>) -> Void)
}

enum HTTPMethod : String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum AIProvider: String, CaseIterable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case google = "Google"
}

enum OpenAIModel: String, CaseIterable {
    case gpt3 = "gpt-3.5-turbo"
    case gpt4 = "gpt-4"
}

enum AnthropicModel: String, CaseIterable {
    case claudeV1 = "claude-v1"
    case claudeV2 = "claude-v2"
}

enum GoogleModel: String, CaseIterable {
    case palm = "PaLM"
    case bard = "Bard"
}

extension APIClient {
    var parameters: [String : String]? { nil }
    var body: Data? { nil }
}