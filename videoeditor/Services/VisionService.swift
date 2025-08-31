//
//  VisionService.swift
//  videoeditor
//
//  Created by Anthony on 07/07/2024.
//

import UIKit

enum VisionError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    case imageConversionError
    case promptTooLong
    case imageTooLarge
    case jsonEncodingError(Error)
}

struct GroqVisionRequest: Codable {
    let prompt: String
    let imageBase64: String
    let mimeType: String
}

struct GroqVisionResponse: Codable {
    let responseText: String
}

struct GroqVisionErrorResponse: Codable {
    let error: String
}

class VisionService: ObservableObject {
    // Assuming the same base URL as SearchAPIService
    private let baseURL = "https://render-proxy-psbm.onrender.com"

    func performVisionRequest(prompt: String, image: UIImage) async throws -> String {
        if prompt.count > 4000 {
            throw VisionError.promptTooLong
        }

        guard let url = URL(string: baseURL + "/groq-vision") else {
            throw VisionError.invalidURL
        }

        // Convert UIImage to base64 string and determine MIME type.
        // Using JPEG for smaller size. The endpoint supports it.
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw VisionError.imageConversionError
        }
        
        let imageBase64 = imageData.base64EncodedString()
        
        let maxImageSize = 10 * 1024 * 1024 // 10MB
        if imageBase64.count > maxImageSize {
            throw VisionError.imageTooLarge
        }
        
        let mimeType = "image/jpeg"

        let requestBody = GroqVisionRequest(prompt: prompt, imageBase64: imageBase64, mimeType: mimeType)
        
        let jsonData: Data
        do {
            jsonData = try JSONEncoder().encode(requestBody)
        } catch {
            throw VisionError.jsonEncodingError(error)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw VisionError.invalidResponse
            }

            if !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = try? JSONDecoder().decode(GroqVisionErrorResponse.self, from: data) {
                    throw VisionError.serverError(errorResponse.error)
                }
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown server error"
                throw VisionError.serverError("Server returned status code \(httpResponse.statusCode). \(errorText)")
            }
            
            do {
                let result = try JSONDecoder().decode(GroqVisionResponse.self, from: data)
                return result.responseText
            } catch {
                // This could happen if the server returns a 2xx status but the body is not the expected JSON
                throw VisionError.invalidResponse
            }

        } catch let error as VisionError {
            throw error // Re-throw our custom errors
        } catch {
            throw VisionError.networkError(error)
        }
    }
}

