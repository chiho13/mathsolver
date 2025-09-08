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
    case noMathFound
    case imageContentNotSuitable
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
    private let maxRetries = 3
    private let requestTimeout: TimeInterval = 60.0 // 60 seconds
    
    func solveMathProblem(image: UIImage) async throws -> String {
        let mathPrompt = """
        You are a mathematics expert. Analyze this image carefully and solve any mathematical problems you find.
        
        INSTRUCTIONS:
        1. If you find mathematical content, solve it completely.
        2. For simple arithmetic: provide only the final answer.
        3. For complex problems: show detailed step-by-step solutions.
        4. Use proper mathematical notation and formatting.
        5. If NO mathematical content is found, respond with exactly: NOMATH.
        
        CRITICAL LATEX FORMATTING REQUIREMENTS - READ THIS CAREFULLY:
        
        ⚠️ MATH DELIMITERS - ONLY USE THESE TWO FORMATS:
        • For inline math: $math goes here$
        • For block math: $$math goes here$$
        
        ❌ NEVER USE THESE (THEY BREAK THE APP):
        • \\(math\\) - FORBIDDEN
        • \\[math\\] - FORBIDDEN 
        • Any other delimiters - FORBIDDEN
        
        ✅ CORRECT EXAMPLES:
        • "The variable $x$ represents..." (inline)
        • "We solve: $$x^2 + 2x + 1 = 0$$" (block)
        
        ❌ WRONG EXAMPLES (DO NOT USE):
        • "The variable \\(x\\) represents..." 
        • "We solve: \\[x^2 + 2x + 1 = 0\\]"
        
        FORMATTING RULES:
        - Use Markdown formatting for text structure
        - Use ## Step 1, ## Step 2, etc. for step-by-step solutions
        - Bold final answer introductions: "**Final Answer:**"
        - Do NOT use \\boxed{} command
        - Do NOT use colons to introduce formulas
        
        EXAMPLE RESPONSE FORMAT:
        ## Step 1
        
        Rewrite the integral by distributing $x^{-1/2}$ inside:
        
        $$\\int \\frac{4x^2 + 1}{2\\sqrt{x}} dx = \\frac{1}{2} \\int (4x^{3/2} + x^{-1/2}) dx$$
        
        ## Step 2
        
        Integrate each term. For $4x^{3/2}$:
        
        $$\\int 4x^{3/2} dx = \\frac{8}{5} x^{5/2}$$
        
        **Final Answer:**
        The integral equals $$\\frac{4}{5} x^{5/2} + x^{1/2} + C$$
        
        Remember: ONLY use $ and $$ for math. Never use \\( or \\[.
        
        Analyze the image now:
        """
        
        let response = try await performVisionRequestWithRetry(prompt: mathPrompt, image: image)
        
        if response.trimmingCharacters(in: .whitespacesAndNewlines) == "NOMATH" {
            throw VisionError.noMathFound
        }
        
        return response
    }
    
    /// Performs a vision request with retry logic and exponential backoff
    private func performVisionRequestWithRetry(prompt: String, image: UIImage) async throws -> String {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await performVisionRequest(prompt: prompt, image: image)
            } catch let error as VisionError {
                lastError = error
                
                // Don't retry for certain errors
                switch error {
                case .invalidURL, .promptTooLong, .imageTooLarge, .imageConversionError, .jsonEncodingError, .noMathFound:
                    throw error
                default:
                    // Retry for network errors, server errors, etc.
                    if attempt < maxRetries - 1 {
                        let delay = pow(2.0, Double(attempt)) // Exponential backoff: 1s, 2s, 4s
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
            } catch {
                lastError = error
                if attempt < maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            }
        }
        
        throw lastError ?? VisionError.networkError(NSError(domain: "VisionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Max retries exceeded"]))
    }

    func performVisionRequest(prompt: String, image: UIImage) async throws -> String {
        if prompt.count > 4000 {
            throw VisionError.promptTooLong
        }

        guard let url = URL(string: baseURL + "/gpt-vision") else {
            throw VisionError.invalidURL
        }

        // Convert UIImage to base64 string and determine MIME type.
        // Using JPEG with optimized compression for math problems
        guard let imageData = optimizeImageForOCR(image) else {
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
        request.timeoutInterval = requestTimeout

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
                let responseText = result.responseText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Validate response is not empty
                guard !responseText.isEmpty else {
                    throw VisionError.invalidResponse
                }
                
                return responseText
            } catch let decodingError {
                // Log the raw response for debugging
                let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response as UTF-8"
                print("Failed to decode response. Raw response: \(rawResponse)")
                print("Decoding error: \(decodingError)")
                throw VisionError.invalidResponse
            }

        } catch let error as VisionError {
            throw error // Re-throw our custom errors
        } catch {
            throw VisionError.networkError(error)
        }
    }
    
    /// Optimizes image for better OCR performance
    private func optimizeImageForOCR(_ image: UIImage) -> Data? {
        // Start with high quality for mathematical content
        var compressionQuality: CGFloat = 0.9
        var imageData: Data?
        
        // Try different compression levels until we get a reasonable size
        while compressionQuality > 0.3 {
            imageData = image.jpegData(compressionQuality: compressionQuality)
            
            if let data = imageData {
                // If image is under 5MB, use it
                if data.count < 5 * 1024 * 1024 {
                    break
                }
            }
            
            compressionQuality -= 0.1
        }
        
        return imageData
    }
}

