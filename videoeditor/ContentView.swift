import SwiftUI
import UIKit
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation
import Mantis

struct ContentView: View {
    @StateObject private var viewModel = VisionViewModel()
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showPremiumView: Bool = false
    @EnvironmentObject private var iap: IAPManager
    @State private var isCameraAuthorized: Bool = false
    @State private var capturedImage: UIImage? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoImage: UIImage? = nil
    @State private var showCropView: Bool = false
    @State private var isCaptureButtonPressed: Bool = false
    @State private var isTorchOn: Bool = false
    @State private var triggerCapture: Bool = false

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
                            CameraWithBracketsView(capturedImage: $capturedImage, viewModel: viewModel, triggerCapture: $triggerCapture)
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

                   



                    if viewModel.isLoading {
                        GradientSpinner()
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
                        VStack(spacing: 12) {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                            
                            // Show helpful tips for no math content errors
                            if errorMessage.contains("No math problems detected") || errorMessage.contains("doesn't appear to contain mathematical content") {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("📝 Tips for better results:")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(alignment: .top) {
                                            Text("•")
                                            Text("Make sure the image contains clear mathematical equations, formulas, or word problems")
                                        }
                                        HStack(alignment: .top) {
                                            Text("•")
                                            Text("Ensure text is readable and not blurry")
                                        }
                                        HStack(alignment: .top) {
                                            Text("•")
                                            Text("Include the full problem, not just parts of it")
                                        }
                                        HStack(alignment: .top) {
                                            Text("•")
                                            Text("Good lighting helps with text recognition")
                                        }
                                    }
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                    }

                    Spacer()
                }

                 VStack {
                                    // Top gradient with multiple stops
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color.white.opacity(0.3), location: 0.0),
                                            .init(color: Color.white.opacity(0.18), location: 0.15),
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
                                    .frame(height: 250)
                                }
                                .ignoresSafeArea(.all)

                                // Photo picker and capture buttons positioned at bottom
                                VStack {
                                    Spacer()
                                    
                                    if isCameraAuthorized && capturedImage == nil {
                                        Text("Take photo of a math question")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(Color.fromHex("#222222").opacity(0.8))
                                            )
                                            .padding(.bottom, 24)
                                        
                                        HStack(spacing: 60) {
                                            // Photo picker button on the left
                                            PhotosPicker(
                                                selection: $selectedPhotoItem,
                                                matching: .images,
                                                photoLibrary: .shared()
                                            ) {
                                                ZStack {
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 2)
                                                        .frame(width: 50, height: 50)
                                                    
                                                    Image(systemName: "photo.on.rectangle")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            
                                            // Camera capture button in the center
                                            ZStack {
                                                // Outer ring (stays same size)
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 4)
                                                    .frame(width: 70, height: 70)
                                                
                                                // Inner solid circle (shrinks on press)
                                                if viewModel.isAnimatingCroppedArea {
                                                    GradientSpinner()
                                                } else {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.white)
                                                        .frame(width: 60, height: 60)
                                                    
                                                    Image("cameramath")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 40, height: 40)
                                                }
                                                .scaleEffect(isCaptureButtonPressed ? 0.93 : 1.0)
                                                .animation(.easeInOut(duration: 0.2), value: isCaptureButtonPressed)
                                                }
                                            }
                                            .onTapGesture {
                                                // Trigger capture in CameraView
                                                if viewModel.isAnimatingCroppedArea {
                                                    viewModel.isAnimatingCroppedArea = false
                                                } else {
                                                    viewModel.isAnimatingCroppedArea = true
                                                    // Auto-stop after 3 seconds for demo
                                                    triggerCapture = true
                                                }
                                            }
                                            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                                                isCaptureButtonPressed = pressing
                                            }, perform: {})
                                            
                                            // Torch button on the right
                                            Button(action: {
                                                // Toggle torch/flashlight
                                                toggleTorch()
                                            }) {
                                                ZStack {
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 2)
                                                        .frame(width: 50, height: 50)
                                                    
                                                    Image(systemName: isTorchOn ? "bolt.fill" : "bolt")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .padding(.bottom, 20) // Add bottom padding for safe area
                                        
                                        // Test animation button (only show when camera is active)
                                       
                                        Button(action: {
                                            if viewModel.isAnimatingCroppedArea {
                                                viewModel.isAnimatingCroppedArea = false
                                            } else {
                                                viewModel.isAnimatingCroppedArea = true
                                                // Auto-stop after 3 seconds for demo
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                                                    viewModel.isAnimatingCroppedArea = false
                                                }
                                            }
                                        }) {
                                            Text(viewModel.isAnimatingCroppedArea ? "Stop Animation" : "Test Animation")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(viewModel.isAnimatingCroppedArea ? Color.red.opacity(0.8) : Color.blue.opacity(0.8))
                                                )
                                        }
                                        .padding(.bottom, 30)
                                    }
                                }
                
                // Buttons overlay - always on top of gradient
                // if let image = capturedImage {
                //     VStack {
                //         Spacer()
                //         VStack(spacing: 16) {
                //             Button(action: {
                //                 Task {
                //                     viewModel.selectedImage = image
                //                     await viewModel.solveMathProblem()
                //                 }
                //             }) {
                //                 if viewModel.isLoading {
                //                     ProgressView()
                //                         .progressViewStyle(CircularProgressViewStyle(tint: .white))
                //                         .frame(height: 20)
                //                 } else {
                //                     Text("Solve Math Problem")
                //                         .font(.headline)
                //                         .padding()
                //                         .frame(maxWidth: .infinity)
                //                 }
                //             }
                //             .buttonStyle(.borderedProminent)
                //             .disabled(viewModel.isLoading)
                            
                //             // Button to retake photo
                //             Button(action: {
                //                 capturedImage = nil
                //                 viewModel.visionResponse = ""
                //                 viewModel.errorMessage = nil
                //             }) {
                //                 Text("Retake Photo")
                //                     .font(.headline)
                //                     .padding()
                //                     .frame(maxWidth: .infinity)
                //             }
                //             .buttonStyle(.bordered)
                //         }
                //         .padding(.horizontal)
                //         .padding(.bottom, 50) // Safe area padding
                //     }
                //     .ignoresSafeArea(.all)
                // }
            }
            .onAppear {
                checkCameraAuthorization()
                checkTorchStatus()
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
            .fullScreenCover(isPresented: $showCropView) {
                if let image = selectedPhotoImage {
                    MantisCropViewRepresentable(
                        image: image,
                        onCrop: { croppedImage in
                            capturedImage = croppedImage
                            selectedPhotoImage = nil
                            showCropView = false
                        },
                        onCancel: {
                            selectedPhotoImage = nil
                            showCropView = false
                        }
                    )
                    .ignoresSafeArea(.all)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let newItem = newItem {
                        print("Photo selected, loading...")
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self) {
                                if let image = UIImage(data: data) {
                                    print("Image loaded successfully, showing crop view")
                                    selectedPhotoImage = image
                                    showCropView = true
                                    // Reset the picker selection
                                    selectedPhotoItem = nil
                                } else {
                                    print("Failed to create UIImage from data")
                                }
                            } else {
                                print("Failed to load data from photo item")
                            }
                        } catch {
                            print("Error loading photo: \(error)")
                        }
                    }
                }
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
                        .padding(.trailing, 8)
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
    
    private func checkTorchStatus() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            isTorchOn = false
            return
        }
        
        isTorchOn = device.torchMode == .on
    }
    
    private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            if device.torchMode == .off {
                device.torchMode = .on
                isTorchOn = true
            } else {
                device.torchMode = .off
                isTorchOn = false
            }
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used: \(error)")
        }
    }
}

struct MantisCropViewRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = CropViewController

    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> CropViewController {
        let cropViewController = Mantis.cropViewController(image: image)
        cropViewController.delegate = context.coordinator
        cropViewController.modalPresentationStyle = .fullScreen
        return cropViewController
    }

    func updateUIViewController(_ uiViewController: CropViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CropViewControllerDelegate {
        var parent: MantisCropViewRepresentable

        init(_ parent: MantisCropViewRepresentable) {
            self.parent = parent
        }

        func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
            parent.onCrop(cropped)
        }

        func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
            parent.onCancel()
        }
        
        func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {
            parent.onCancel()
        }
        
        func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {
            // Optional method - no action needed
        }
        
        func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo) {
            // Optional method - no action needed
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
