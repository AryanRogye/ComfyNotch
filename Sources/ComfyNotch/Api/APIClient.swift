import AppKit

protocol APIClient {
    var baseURL: String { get }
    var headers: [String: String] { get }
    var parameters: [String: String]? { get }
    var body: Data? { get }
    var method: HTTPMethod { get }

    func performRequest(completion: @escaping (Result<String, Error>) -> Void)
}

enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}
extension APIClient {
    var parameters: [String: String]? { nil }
    var body: Data? { nil }
}
