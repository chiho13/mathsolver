import SwiftUI
import UIKit
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

struct ContentView: View {
    @StateObject private var viewModel = VisionViewModel()
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showPremiumView: Bool = false
    @EnvironmentObject private var iap: IAPManager
    @State private var isCameraAuthorized: Bool = false
    @State private var capturedImage: UIImage? = nil

    // Predefined prompt for math solving
    private let mathPrompt = "Solve the math problem in the image"

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.10)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
                
                VStack(spacing: 20) {
                    if isCameraAuthorized {
                        if let image = capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(10)
                                .padding()
                        } else {
                            CameraView(capturedImage: $capturedImage)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .ignoresSafeArea(.all)
                        }
                    } else {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.largeTitle)
                                .padding(.bottom)
                            Text("Camera access is required to solve math problems")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding()
                    }

                    if isCameraAuthorized && capturedImage == nil {
                        Button(action: {
                            // Trigger capture in CameraView
                            NotificationCenter.default.post(name: NSNotification.Name("CapturePhoto"), object: nil)
                        }) {
                            Label("Capture Photo", systemImage: "camera")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                    }

                    if let image = capturedImage {
                        Button(action: {
                            Task {
                                viewModel.selectedImage = image
                                viewModel.prompt = mathPrompt
                                await viewModel.performVisionRequest()
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(height: 20)
                            } else {
                                Text("Solve Math Problem")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal)

                        // Button to retake photo
                        Button(action: {
                            capturedImage = nil
                            viewModel.visionResponse = ""
                            viewModel.errorMessage = nil
                        }) {
                            Text("Retake Photo")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .padding(.horizontal)
                    }

                    if viewModel.isLoading {
                        ProgressView("Solving...")
                    .padding()
                    }

                    if !viewModel.visionResponse.isEmpty {
                        ScrollView {
                            Text(viewModel.visionResponse)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                        .padding()
                    }

                    if let errorMessage = viewModel.errorMessage ?? errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }

                    Spacer()
                }

                 VStack {
                                    // Top gradient with multiple stops
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color.white.opacity(0.2), location: 0.0),
                                            .init(color: Color.white.opacity(0.16), location: 0.15),
                                            .init(color: Color.white.opacity(0.12), location: 0.3),
                                            .init(color: Color.white.opacity(0.08), location: 0.45),
                                            .init(color: Color.white.opacity(0.05), location: 0.6),
                                            .init(color: Color.white.opacity(0.03), location: 0.75),
                                            .init(color: Color.white.opacity(0.01), location: 0.9),
                                            .init(color: Color.white.opacity(0.0), location: 1.0)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: 200)
                                    
                                    Spacer()
                                    
                                    // Bottom gradient with multiple stops
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color.white.opacity(0.0), location: 0.0),
                                            .init(color: Color.white.opacity(0.015), location: 0.1),
                                            .init(color: Color.white.opacity(0.045), location: 0.25),
                                            .init(color: Color.white.opacity(0.075), location: 0.4),
                                            .init(color: Color.white.opacity(0.12), location: 0.55),
                                            .init(color: Color.white.opacity(0.18), location: 0.7),
                                            .init(color: Color.white.opacity(0.22), location: 0.85),
                                            .init(color: Color.white.opacity(0.25), location: 1.0)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: 300)
                                }
                                .ignoresSafeArea(.all)
            }
            .onAppear {
                checkCameraAuthorization()
                NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowPremiumView"), object: nil, queue: .main) { _ in
                    showPremiumView = true
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ShowPremiumView"), object: nil)
            }
            .fullScreenCover(isPresented: $showPremiumView) {
                PremiumView(headline: "paywall-title")
            }
            .toolbar {
                if iap.didCheckPremium && !iap.isPremium {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                showPremiumView = true
                            }
                        }) {
                            Text("Upgrade")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        .opacity(showPremiumView ? 0 : 1)
                    }
                }
            }
        }
    }

    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    isCameraAuthorized = granted
                    if !granted {
                        errorMessage = "Please enable camera access in Settings to use the math solver."
                    }
                }
            }
        case .denied, .restricted:
            isCameraAuthorized = false
            errorMessage = "Please enable camera access in Settings to use the math solver."
        @unknown default:
            isCameraAuthorized = false
            errorMessage = "Unknown camera authorization status."
        }
    }
}



extension UserDefaults {
    static func resetDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
}
