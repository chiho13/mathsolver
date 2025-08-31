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



struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraView
        var photoOutput: AVCapturePhotoOutput?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var captureRect: CGRect?
        
        init(parent: CameraView) {
            self.parent = parent
            super.init()
            
            // Listen for capture photo notification
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(capturePhoto),
                name: NSNotification.Name("CapturePhoto"),
                object: nil
            )
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else { return }

            guard let previewLayer = self.previewLayer, let captureRect = self.captureRect else {
                DispatchQueue.main.async {
                    self.parent.capturedImage = image
                }
                return
            }

            let metadataOutputRect = previewLayer.metadataOutputRectConverted(fromLayerRect: captureRect)
            let croppedImage = self.cropImage(image, to: metadataOutputRect)

            DispatchQueue.main.async {
                self.parent.capturedImage = croppedImage ?? image
            }
        }

        private func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage? {
            guard let cgImage = image.cgImage else { return nil }

            let imageWidth = CGFloat(cgImage.width)
            let imageHeight = CGFloat(cgImage.height)

            let cropRect = CGRect(
                x: rect.origin.x * imageWidth,
                y: rect.origin.y * imageHeight,
                width: rect.size.width * imageWidth,
                height: rect.size.height * imageHeight
            )

            if let croppedCGImage = cgImage.cropping(to: cropRect) {
                return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
            }

            return nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return viewController
        }
        
        let output = AVCapturePhotoOutput()
        context.coordinator.photoOutput = output
        session.addInput(input)
        session.addOutput(output)
        session.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = viewController.view.bounds
        context.coordinator.previewLayer = previewLayer
        
        viewController.view.layer.addSublayer(previewLayer)
        
        // Add rectangular overlay with fade effect
        let overlayView = UIView(frame: viewController.view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        // Define the rectangular capture area using device screen dimensions
        let cornerRadius: CGFloat = 8.0
        let screenBounds = UIScreen.main.bounds
        let screenWidth = screenBounds.width
        let screenHeight = screenBounds.height
        
        let rectWidth = screenWidth * 0.85  // 85% of screen width
        let rectHeight: CGFloat = 120.0
        
        // Center horizontally on screen
        let rectX = (screenWidth - rectWidth) / 2.0
        
        // Center vertically in the screen, then move up 50px
        let rectY = (screenHeight - rectHeight) / 2.0 - 50.0
        
        let captureRect = CGRect(x: rectX, y: rectY, width: rectWidth, height: rectHeight)
        context.coordinator.captureRect = captureRect
        
        let path = UIBezierPath(roundedRect: captureRect, cornerRadius: cornerRadius)
        let maskLayer = CAShapeLayer()
        let fullPath = UIBezierPath(rect: viewController.view.bounds)
        fullPath.append(path)
        maskLayer.path = fullPath.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer
        
        viewController.view.addSubview(overlayView)
        
        // Add corner brackets for the cutout
        let bracketLength: CGFloat = 20.0
        let bracketWidth: CGFloat = 3.0
        
        // Top-left bracket
        let topLeftBracket = CAShapeLayer()
        let topLeftPath = UIBezierPath()
        topLeftPath.move(to: CGPoint(x: rectX + bracketLength, y: rectY))
        topLeftPath.addLine(to: CGPoint(x: rectX, y: rectY))
        topLeftPath.addLine(to: CGPoint(x: rectX, y: rectY + bracketLength))
        topLeftBracket.path = topLeftPath.cgPath
        topLeftBracket.lineWidth = bracketWidth
        topLeftBracket.strokeColor = UIColor.white.cgColor
        topLeftBracket.fillColor = UIColor.clear.cgColor
        viewController.view.layer.addSublayer(topLeftBracket)
        
        // Top-right bracket
        let topRightBracket = CAShapeLayer()
        let topRightPath = UIBezierPath()
        topRightPath.move(to: CGPoint(x: rectX + rectWidth - bracketLength, y: rectY))
        topRightPath.addLine(to: CGPoint(x: rectX + rectWidth, y: rectY))
        topRightPath.addLine(to: CGPoint(x: rectX + rectWidth, y: rectY + bracketLength))
        topRightBracket.path = topRightPath.cgPath
        topRightBracket.lineWidth = bracketWidth
        topRightBracket.strokeColor = UIColor.white.cgColor
        topRightBracket.fillColor = UIColor.clear.cgColor
        viewController.view.layer.addSublayer(topRightBracket)
        
        // Bottom-left bracket
        let bottomLeftBracket = CAShapeLayer()
        let bottomLeftPath = UIBezierPath()
        bottomLeftPath.move(to: CGPoint(x: rectX, y: rectY + rectHeight - bracketLength))
        bottomLeftPath.addLine(to: CGPoint(x: rectX, y: rectY + rectHeight))
        bottomLeftPath.addLine(to: CGPoint(x: rectX + bracketLength, y: rectY + rectHeight))
        bottomLeftBracket.path = bottomLeftPath.cgPath
        bottomLeftBracket.lineWidth = bracketWidth
        bottomLeftBracket.strokeColor = UIColor.white.cgColor
        bottomLeftBracket.fillColor = UIColor.clear.cgColor
        viewController.view.layer.addSublayer(bottomLeftBracket)
        
        // Bottom-right bracket
        let bottomRightBracket = CAShapeLayer()
        let bottomRightPath = UIBezierPath()
        bottomRightPath.move(to: CGPoint(x: rectX + rectWidth - bracketLength, y: rectY + rectHeight))
        bottomRightPath.addLine(to: CGPoint(x: rectX + rectWidth, y: rectY + rectHeight))
        bottomRightPath.addLine(to: CGPoint(x: rectX + rectWidth, y: rectY + rectHeight - bracketLength))
        bottomRightBracket.path = bottomRightPath.cgPath
        bottomRightBracket.lineWidth = bracketWidth
        bottomRightBracket.strokeColor = UIColor.white.cgColor
        bottomRightBracket.fillColor = UIColor.clear.cgColor
        viewController.view.layer.addSublayer(bottomRightBracket)
        
        // Note: Capture button is now handled by SwiftUI overlay
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

protocol CameraViewControllerDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage)
    func didFailWithError(_ error: Error)
}

extension CameraView.Coordinator {
    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
}


class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        NotificationCenter.default.addObserver(self, selector: #selector(capturePhoto), name: NSNotification.Name("CapturePhoto"), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("CapturePhoto"), object: nil)
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo

        guard let captureDevice = AVCaptureDevice.default(for: .video),
              let captureSession = captureSession else {
            delegate?.didFailWithError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to set up camera"]))
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput!) {
                captureSession.addOutput(photoOutput!)
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.bounds
            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }

            captureSession.startRunning()
        } catch {
            delegate?.didFailWithError(error)
        }
    }

    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            delegate?.didFailWithError(error)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            delegate?.didFailWithError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to process captured image"]))
            return
        }

        delegate?.didCaptureImage(image)
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
