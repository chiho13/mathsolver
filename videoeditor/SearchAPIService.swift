import Foundation

enum SearchError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(String)
}

class SearchAPIService: ObservableObject {
    private let baseURL = "https://render-proxy-psbm.onrender.com" // Placeholder for your API
    
    func search(query: String) async throws -> String {
        guard let url = URL(string: baseURL + "/search") else {
            throw SearchError.invalidURL
        }
        let body = ["input": "include links as source. output as markdown: \(query)"]
        let jsonData = try JSONEncoder().encode(body)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SearchError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorResponse = try? JSONDecoder().decode(SearchErrorResponse.self, from: data) {
                    throw SearchError.serverError(errorResponse.error)
                }
                throw SearchError.serverError("Server error: \(httpResponse.statusCode)")
            }
            let result = try JSONDecoder().decode(SearchOutputResponse.self, from: data)
            return result.output
        } catch {
            throw SearchError.networkError(error)
        }
    }
}

struct SearchOutputResponse: Codable {
    let output: String
}

struct SearchErrorResponse: Codable {
    let error: String
} 
