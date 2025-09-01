//
//  VisionViewModel.swift
//  videoeditor
//
//  Created by Gemini on 07/07/2024.
//

import SwiftUI
import UIKit

/// A view model to manage the state and logic for the Vision feature.
/// It acts as the bridge between the View (ContentView) and the Model (VisionService).
class VisionViewModel: ObservableObject {
    // MARK: - Published Properties

    /// The image selected by the user.
    @Published var selectedImage: UIImage? = nil
    
    /// The text prompt entered by the user.
    @Published var prompt: String = ""
    
    /// The response text received from the Vision API.
    @Published var visionResponse: String = ""
    
    /// A boolean to indicate if an API request is in progress.
    @Published var isLoading: Bool = false
    
    /// An optional error message to display to the user.
    @Published var errorMessage: String? = nil
    
    /// A boolean to control the visibility of the image picker.
    @Published var isShowingImagePicker: Bool = false
    
    /// A boolean to control cropped area animation while solving
    @Published var isAnimatingCroppedArea: Bool = false
    
    // MARK: - Private Properties
    
    private let visionService = VisionService()
    
    // MARK: - Public Methods
    
    /// Performs an asynchronous vision request to the backend.
    @MainActor
    func performVisionRequest() async {
        guard let image = selectedImage else {
            errorMessage = "Please select an image first."
            return
        }
        
        guard !prompt.isEmpty else {
            errorMessage = "Please enter a prompt."
            return
        }
        
        // Reset state for a new request
        isLoading = true
        errorMessage = nil
        visionResponse = ""
        
        do {
            let response = try await visionService.performVisionRequest(prompt: prompt, image: image)
            self.visionResponse = response
        } catch let error as VisionError {
            self.errorMessage = self.handleVisionError(error)
        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Performs math problem solving with automatic detection
    @MainActor
    func solveMathProblem() async {
        guard let image = selectedImage else {
            errorMessage = "Please select an image first."
            return
        }
        
        // Reset state for a new request
        isLoading = true
        isAnimatingCroppedArea = true
        errorMessage = nil
        visionResponse = ""
        
        do {
            let response = try await visionService.solveMathProblem(image: image)
            self.visionResponse = response
        } catch let error as VisionError {
            self.errorMessage = self.handleVisionError(error)
        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        isLoading = false
        isAnimatingCroppedArea = false
    }
    
    // MARK: - Private Methods
    
    /// Handles the VisionError and returns a user-friendly message.
    private func handleVisionError(_ error: VisionError) -> String {
        switch error {
        case .invalidURL:
            return "Invalid server URL. Please check the configuration."
        case .networkError(let networkError):
            return "Network error: \(networkError.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from the server."
        case .serverError(let message):
            return "Server error: \(message)"
        case .imageConversionError:
            return "Could not process the selected image."
        case .promptTooLong:
            return "The prompt is too long. Please shorten it."
        case .imageTooLarge:
            return "The selected image is too large. Please choose a smaller one."
        case .jsonEncodingError(let jsonError):
            return "Failed to encode request data: \(jsonError.localizedDescription)"
        case .noMathFound:
            return "📷 No math problems detected in this image. Please try taking a photo that contains mathematical equations, formulas, or problems to solve."
        case .imageContentNotSuitable:
            return "🔍 This image doesn't appear to contain mathematical content suitable for solving. Please capture an image with clear math problems."
        }
    }
}
