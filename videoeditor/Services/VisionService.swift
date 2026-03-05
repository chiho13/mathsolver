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

struct GroqVisionResponse: Codable {
    let responseText: String
}

struct GroqVisionErrorResponse: Codable {
    let error: String
}

struct MathpixOCRRequest: Codable {
    let imageBase64: String
    let mimeType: String
    let formats: [String]
    let mathInlineDelimiters: [String]
    let rmSpaces: Bool

    enum CodingKeys: String, CodingKey {
        case imageBase64
        case mimeType
        case formats
        case mathInlineDelimiters = "math_inline_delimiters"
        case rmSpaces = "rm_spaces"
    }
}

struct MathpixErrorInfo: Codable {
    let id: String?
    let message: String?
}

struct MathpixOCRResponse: Codable {
    let text: String?
    let latexStyled: String?
    let error: String?
    let errorInfo: MathpixErrorInfo?

    enum CodingKeys: String, CodingKey {
        case text
        case latexStyled = "latex_styled"
        case error
        case errorInfo = "error_info"
    }
}

struct OpenAITextRequest: Codable {
    let prompt: String
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
        3. For complex problems: compute and verify first, then show the final answer first, then detailed step-by-step solutions.
        4. Use proper mathematical notation and formatting.
        5. If NO mathematical content is found, respond with exactly: NOMATH.
        6. If the input is an integral, derivative, equation, or algebraic expression, verify your final result before responding.
        7. Never provide two different final answers. Return exactly one final answer.
        8. Do not reveal corrections, retries, or internal checking. Output only the final polished solution.
        
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
        - Then use ## Step 1, ## Step 2, etc. for step-by-step solutions
        - Bold answer introductions: "**Answer:**"
        - Do NOT use \\boxed{} command
        - Do NOT use colons to introduce formulas
        - Do NOT include an "Alternative answer" section
        - Do NOT include a second "Final Answer"

        ACCURACY CHECK (MANDATORY BEFORE FINAL OUTPUT):
        - Compute the result
        - Verify it:
          - For integrals: differentiate your antiderivative and confirm it matches the original integrand exactly
          - For derivatives: optionally integrate/check algebraic consistency
          - For equations: substitute back into the original equation
        - If verification fails, correct the solution before producing the final answer
        - Perform all checks silently before writing the first line of your response

        REQUIRED RESPONSE FORMAT (ANSWER FIRST, THEN STEPS):

        **Answer:** $$\\frac{4}{5} x^{5/2} + x^{1/2} + C$$
        
        ## Step 1
        
        Rewrite the integral by distributing $x^{-1/2}$ inside:
        
        $$\\int \\frac{4x^2 + 1}{2\\sqrt{x}} dx = \\frac{1}{2} \\int (4x^{3/2} + x^{-1/2}) dx$$
        
        ## Step 2
        
        Integrate each term. For $4x^{3/2}$:
        
        $$\\int 4x^{3/2} dx = \\frac{8}{5} x^{5/2}$$
        
        Remember: ALWAYS show one verified Final Answer section first, then step-by-step explanation. NEVER show contradictory answers. ONLY use $ and $$ for math. Never use \\( or \\[.
        
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

        // Convert UIImage to base64 string and determine MIME type.
        // Using JPEG with optimized compression for math problems
        guard let imageData = optimizeImageForOCR(image) else {
            throw VisionError.imageConversionError
        }
        
        let imageBase64 = imageData.base64EncodedString()
        
        // Mathpix JSON requests support up to 2MB base64 payloads for image data.
        let maxImageSize = 2 * 1024 * 1024
        if imageBase64.count > maxImageSize {
            throw VisionError.imageTooLarge
        }

        do {
            let mimeType = "image/jpeg"
            let ocrStart = Date()
            let extractedText = try await extractMathTextWithMathpix(imageBase64: imageBase64, mimeType: mimeType)
#if DEBUG
            print(String(format: "[Timing] Image->LaTeX: %.2fs", Date().timeIntervalSince(ocrStart)))
#endif
            guard !extractedText.isEmpty else {
                throw VisionError.noMathFound
            }
            let solveStart = Date()
            let solved = try await solveWithOpenAI(prompt: prompt, extractedText: extractedText)
#if DEBUG
            print(String(format: "[Timing] Solve from LaTeX: %.2fs", Date().timeIntervalSince(solveStart)))
#endif
            return solved
        } catch let error as VisionError {
            throw error // Re-throw our custom errors
        } catch {
            throw VisionError.networkError(error)
        }
    }

    private func extractMathTextWithMathpix(imageBase64: String, mimeType: String) async throws -> String {
        guard let url = URL(string: baseURL + "/mathpix-ocr") else {
            throw VisionError.invalidURL
        }

        let requestBody = MathpixOCRRequest(
            imageBase64: imageBase64,
            mimeType: mimeType,
            formats: ["text", "latex_styled"],
            mathInlineDelimiters: ["$", "$"],
            rmSpaces: true
        )
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

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VisionError.invalidResponse
        }
        logJSONResponse(data, label: "Mathpix OCR", statusCode: httpResponse.statusCode)

        if !(200...299).contains(httpResponse.statusCode) {
            if let errorResponse = try? JSONDecoder().decode(GroqVisionErrorResponse.self, from: data) {
                throw VisionError.serverError(errorResponse.error)
            }
            if let ocrErrorResponse = try? JSONDecoder().decode(MathpixOCRResponse.self, from: data),
               let error = ocrErrorResponse.error {
                throw VisionError.serverError(error)
            }
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw VisionError.serverError("Server returned status code \(httpResponse.statusCode). \(errorText)")
        }

        do {
            let result = try JSONDecoder().decode(MathpixOCRResponse.self, from: data)
            if let error = result.error, !error.isEmpty {
                let errorId = result.errorInfo?.id ?? "unknown"
                throw VisionError.serverError("Mathpix API error (\(errorId)): \(error)")
            }

            let latex = (result.latexStyled ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !latex.isEmpty {
                return latex
            }

            return (result.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        } catch let decodingError {
            let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response as UTF-8"
            print("Failed to decode Mathpix OCR response. Raw response: \(rawResponse)")
            print("Decoding error: \(decodingError)")
            throw VisionError.invalidResponse
        }
    }

    private func solveWithOpenAI(prompt: String, extractedText: String) async throws -> String {
        guard let url = URL(string: baseURL + "/prompt-groq") else {
            throw VisionError.invalidURL
        }

        let combinedPrompt = "\(prompt)\n\nLaTeX from OCR:\n\(extractedText)"
        let requestBody = OpenAITextRequest(prompt: combinedPrompt)
        let jsonData: Data
        do {
            jsonData = try JSONEncoder().encode(requestBody)
        } catch {
            throw VisionError.jsonEncodingError(error)
        }

#if DEBUG
        let preview = extractedText.prefix(200)
        print("[Prompt Solve] request: prompt_len=\(combinedPrompt.count), text_len=\(extractedText.count), text_preview=\(preview)")
#endif

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = requestTimeout

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VisionError.invalidResponse
        }
        logJSONResponse(data, label: "Prompt Solve", statusCode: httpResponse.statusCode)

        if !(200...299).contains(httpResponse.statusCode) {
            if let errorResponse = try? JSONDecoder().decode(GroqVisionErrorResponse.self, from: data) {
                throw VisionError.serverError(errorResponse.error)
            }
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw VisionError.serverError("Server returned status code \(httpResponse.statusCode). \(errorText)")
        }

        if let decoded = try? JSONDecoder().decode(GroqVisionResponse.self, from: data) {
            let responseText = decoded.responseText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !responseText.isEmpty else {
                throw VisionError.invalidResponse
            }
            return responseText
        }

        // Fallback for alternative response keys from /prompt
        if
            let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let text = (jsonObject["response"] as? String) ??
                (jsonObject["answer"] as? String) ??
                (jsonObject["text"] as? String) ??
                (jsonObject["responseText"] as? String) ??
                (jsonObject["result"] as? String) ??
                ((jsonObject["data"] as? [String: Any])?["response"] as? String) ??
                ((jsonObject["data"] as? [String: Any])?["text"] as? String)
        {
            let responseText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !responseText.isEmpty else {
                throw VisionError.invalidResponse
            }
            return responseText
        }

        let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response as UTF-8"
        print("Failed to decode OpenAI response. Raw response: \(rawResponse)")
        throw VisionError.invalidResponse
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
                // Keep JPEG comfortably below the Mathpix 2MB base64 JSON limit.
                if data.count < 1_400_000 {
                    break
                }
            }
            
            compressionQuality -= 0.1
        }
        
        return imageData
    }

    private func logJSONResponse(_ data: Data, label: String, statusCode: Int) {

        if
            let object = try? JSONSerialization.jsonObject(with: data),
            let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let prettyString = String(data: prettyData, encoding: .utf8)
        {
            print("[\(label)] status=\(statusCode)\n\(prettyString)")
            return
        }

        let raw = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
        print("[\(label)] status=\(statusCode)\n\(raw)")

    }
}
