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
    @EnvironmentObject private var creditManager: CreditManager
    @State private var isCameraAuthorized: Bool = false
    @State private var croppedImage: UIImage? = nil
    @State private var originalImage: UIImage? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoImage: UIImage? = nil
    @State private var showCropView: Bool = false
    @State private var  isCaptureButtonPressed: Bool = false
    @State private var isTorchOn: Bool = false
    @State private var triggerCapture: Bool = false
    @State private var showSolutionSheet: Bool = false
    @State private var captureRect: CGRect = {
        let screenBounds = UIScreen.main.bounds
        let screenWidth = screenBounds.width
        let screenHeight = screenBounds.height
        
        let rectWidth = screenWidth * 0.85  // 85% of screen width
        let rectHeight: CGFloat = 120.0
        
        // Center horizontally on screen
        let rectX = (screenWidth - rectWidth) / 2.0
        
        // Center vertically in the screen, then move up 50px
        let rectY = (screenHeight - rectHeight) / 2.0 - 40.0
        
        return CGRect(x: rectX, y: rectY, width: rectWidth, height: rectHeight)
    }()
    @State private var freezeImage: UIImage? = nil
    @State private var imageOffset: CGSize = .zero 
    @State private var isImageAtTop: Bool = false
    @State private var dragOffsetY: CGFloat = 0
    @State private var selectedDetent = PresentationDetent.fraction(0.6)
    @State private var shouldAnimateImagePosition: Bool = false
    // Predefined prompt for math solving
    private let mathPrompt = "Solve the math problem in the image"

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.10)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
                
                VStack(spacing: 20) {
                    if isCameraAuthorized {

                        if let image = selectedPhotoImage {
                          VStack { // Wrap in a VStack to control vertical positioning
                              
                            ImageWithBracketView(
                                image: image,
                                captureRect: $captureRect,
                                isAnimatingCroppedArea: viewModel.isAnimatingCroppedArea,
                                currentImageOffset: $imageOffset
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .offset(y: (isImageAtTop && shouldAnimateImagePosition) ? -((UIScreen.main.bounds.height / 3) - 120.0) + dragOffsetY : dragOffsetY)
                            .animation(.easeInOut(duration: 0.5), value: isImageAtTop)
                        }
                        .ignoresSafeArea(.all)
                        .transition(.identity)

                        } else {
                            ZStack {
                                CameraWithBracketsView(capturedImage: $croppedImage, originalImage: $originalImage, viewModel: viewModel, triggerCapture: $triggerCapture, captureRect: $captureRect, freezeImage: $freezeImage, isImageAtTop: $isImageAtTop)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .ignoresSafeArea(.all)
                                    .transition(.identity)
                              
                            }
                        }

                // ZStack {
                //                 CameraWithBracketsView(capturedImage: $croppedImage, originalImage: $originalImage, viewModel: viewModel, triggerCapture: $triggerCapture, captureRect: $captureRect, freezeImage: $freezeImage)
                //                     .frame(maxWidth: .infinity, maxHeight: .infinity)
                //                     .ignoresSafeArea(.all)
                //                     .transition(.identity)
                              
                        
                            
                //             }
                            
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
                                    
                                    if isCameraAuthorized && originalImage == nil && selectedPhotoImage == nil {
                                        Text("Take photo of a math question")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(Color.fromHex("#222222").opacity(0.8))
                                            )
                                            .padding(.bottom, 32)
                                        
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
                                                if viewModel.isAnimatingShutter || viewModel.isAnimatingCroppedArea {
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
                                // Step 1: Check if user is premium first, then credits
                                if !viewModel.isAnimatingShutter && !viewModel.isAnimatingCroppedArea {
                                    if iap.isPremium || creditManager.canUseMathSolver() {
                                        // Deduct credit here since user is initiating the solve action
                                        if !iap.isPremium {
                                            let _ = creditManager.useCredit()
                                        }
                                        viewModel.isAnimatingShutter = true
                                        // Step 2: Show spinner, trigger capture
                                        triggerCapture = true
                                    } else {
                                        // No credits left and not premium, show premium view
                                        showPremiumView = true
                                    }
                                }
                            }
                            .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
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
                                        .padding(.bottom, 60) // Add bottom padding for safe area
                                        
                                        // Test animation button (only show when camera is active)
                                       
                                        // Button(action: {
                                        //     if viewModel.isAnimatingCroppedArea {
                                        //         viewModel.isAnimatingCroppedArea = false
                                        //     } else {
                                        //         viewModel.isAnimatingCroppedArea = true
                                        //         // Auto-stop after 3 seconds for demo
                                        //         DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                                        //             viewModel.isAnimatingCroppedArea = false
                                        //         }
                                        //     }
                                        // }) {
                                        //     Text(viewModel.isAnimatingCroppedArea ? "Stop Animation" : "Test Animation")
                                        //         .font(.system(size: 14, weight: .medium))
                                        //         .foregroundColor(.white)
                                        //         .padding(.horizontal, 16)
                                        //         .padding(.vertical, 8)
                                        //         .background(
                                        //             Capsule()
                                        //                 .fill(viewModel.isAnimatingCroppedArea ? Color.red.opacity(0.8) : Color.blue.opacity(0.8))
                                        //         )
                                        // }
                                        // .padding(.bottom, 30)
                                    }

                               if selectedPhotoImage != nil && !viewModel.isAnimatingCroppedArea {
                            // Buttons for cropping the selected photo
                           HStack(spacing: 32) {
    Button(action: {
        // Reset the photo view and go back to camera
        selectedPhotoImage = nil
        imageOffset = .zero // Reset offset for next use
    }) {
        Text("Back")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 100, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.gray.opacity(0.2))
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
            )
    }
    
            Button(action: {
            // Check if user is premium first, then credits before processing
            if iap.isPremium || creditManager.canUseMathSolver() {
                // Deduct credit here since user is initiating the solve action
                if !iap.isPremium {
                    let _ = creditManager.useCredit()
                }
                
                // Crop the image and process it
                if let image = selectedPhotoImage {
                    let _croppedImage = cropImage(image: image, rect: captureRect, offset: imageOffset)
                    if let croppedImage = _croppedImage {
                        viewModel.selectedImage = croppedImage
                        viewModel.isAnimatingCroppedArea = true // Trigger dot animation

                        
                        Task {
                            await viewModel.solveMathProblem(deductCredit: false) // Send to backend
                        }
                    }
                }
            } else {
                // No credits left and not premium, show premium view
                showPremiumView = true
            }
            // Reset photo and go back to camera
    //         withAnimation(.easeInOut(duration: 0.3)) {
    //     imageOffset = .zero
    // }
        }) {
            Text("Solve")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 100, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.green.opacity(0.9))
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                )
        }
}
.padding(.bottom, 32)
.padding(.horizontal, 16)
                        } 
                                }
                
            }
            .onAppear {
                checkCameraAuthorization()
                checkTorchStatus()
                // Set credit manager reference in view model
                viewModel.creditManager = creditManager
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
            // .fullScreenCover(isPresented: $showCropView) {
            //     if let image = selectedPhotoImage {
            //         MantisCropViewRepresentable(
            //             image: image,
            //             onCrop: { croppedImage in
            //                 self.croppedImage = croppedImage
            //                 self.originalImage = croppedImage
            //                 selectedPhotoImage = nil
            //                 showCropView = false
            //             },
            //             onCancel: {
            //                 selectedPhotoImage = nil
            //                 showCropView = false
            //             }
            //         )
            //         .ignoresSafeArea(.all)
            //     }
            // }
            // .onChange(of: croppedImage) { _, newCroppedImage in
            //     if let imageToSolve = newCroppedImage {
            //         Task {
            //             viewModel.selectedImage = imageToSolve
            //             await viewModel.solveMathProblem()
            //         }
            //     }
            // }
            .onChange(of: viewModel.visionResponse) { _, newResponse in
                if !newResponse.isEmpty {
                    // Start solution sheet and stop animation
                     withAnimation(.easeInOut(duration: 0.5)) {
                            isImageAtTop = true
                        }

                    showSolutionSheet = true
                    viewModel.isAnimatingCroppedArea = false
                }
            }
            .onChange(of: viewModel.errorMessage) { _, newError in
                if newError != nil {
                    // Start solution sheet and stop animation
                     withAnimation(.easeInOut(duration: 0.5)) {
                            isImageAtTop = true
                        }
                    showSolutionSheet = true
                    viewModel.isAnimatingCroppedArea = false
                }
            }
            .sheet(isPresented: $showSolutionSheet, onDismiss: {
                // All state cleanup now happens here, when the user is truly done
                originalImage = nil
                croppedImage = nil
                freezeImage = nil
                viewModel.errorMessage = nil
                 isImageAtTop = false
                 dragOffsetY = 0
                shouldAnimateImagePosition = false
                selectedDetent = .fraction(0.6)
                selectedPhotoImage = nil
                imageOffset = .zero
                
                // Reset captureRect to its initial state
                let screenBounds = UIScreen.main.bounds
                let screenWidth = screenBounds.width
                let screenHeight = screenBounds.height
                let rectWidth = screenWidth * 0.85
                let rectHeight: CGFloat = 120.0
                let rectX = (screenWidth - rectWidth) / 2.0
                let rectY = (screenHeight - rectHeight) / 2.0 - 40.0
                captureRect = CGRect(x: rectX, y: rectY, width: rectWidth, height: rectHeight)
            }) {
                SolutionSheetView(showSolutionSheet: $showSolutionSheet, visionResponse: viewModel.visionResponse, errorMessage: viewModel.errorMessage, selectedDetent: $selectedDetent, dragOffset: $dragOffsetY)
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
                                    shouldAnimateImagePosition = true
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
                        HStack(spacing: 8) {
                            // Credit counter next to upgrade button
                            Text(creditManager.creditDisplayText())
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(creditManager.hasCredits ? 
                                              LinearGradient(colors: [Color.green.opacity(0.9), Color.green.opacity(0.7)], startPoint: .top, endPoint: .bottom) : 
                                              LinearGradient(colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                )
                            
                            // Upgrade button
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
    
    // Function to perform the actual cropping
       private func cropImage(image: UIImage, rect: CGRect, offset: CGSize) -> UIImage? {
           guard let cgImage = image.cgImage else { return nil }
           
           let viewSize = UIScreen.main.bounds.size
           let imageSize = image.size
           
           let initialScale = viewSize.width / imageSize.width
           
           // Calculate the scaled image size
           let scaledImageWidth = imageSize.width * initialScale
           let scaledImageHeight = imageSize.height * initialScale
           
           // Calculate the origin of the scaled image on the screen
           let originX = (viewSize.width - scaledImageWidth) / 2.0
           let originY = (viewSize.height - scaledImageHeight) / 2.0
           
           // Convert the on-screen captureRect to the original image's coordinate space
           let cropRectX = (rect.minX - originX - offset.width) / initialScale
           let cropRectY = (rect.minY - originY - offset.height) / initialScale
           let cropRectWidth = rect.width / initialScale
           let cropRectHeight = rect.height / initialScale
           
           let cropRect = CGRect(x: cropRectX, y: cropRectY, width: cropRectWidth, height: cropRectHeight)
           
           guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
               return nil
           }
           
           return UIImage(cgImage: croppedCGImage)
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

//struct MantisCropViewRepresentable: UIViewControllerRepresentable {
//    typealias UIViewControllerType = CropViewController
//
//    let image: UIImage
//    let onCrop: (UIImage) -> Void
//    let onCancel: () -> Void
//
//    func makeUIViewController(context: Context) -> CropViewController {
//        let cropViewController = Mantis.cropViewController(image: image)
//        cropViewController.delegate = context.coordinator
//        cropViewController.modalPresentationStyle = .fullScreen
//        return cropViewController
//    }
//
//    func updateUIViewController(_ uiViewController: CropViewController, context: Context) {}
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject, CropViewControllerDelegate {
//        var parent: MantisCropViewRepresentable
//
//        init(_ parent: MantisCropViewRepresentable) {
//            self.parent = parent
//        }
//
//        func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
//            parent.onCrop(cropped)
//        }
//
//        func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
//            parent.onCancel()
//        }
//        
//        func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {
//            parent.onCancel()
//        }
//        
//        func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {
//            // Optional method - no action needed
//        }
//        
//        func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo) {
//            // Optional method - no action needed
//        }
//    }
//}

extension UserDefaults {
    static func resetDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
}
