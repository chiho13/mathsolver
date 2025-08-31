//
//  HomeCameraView.swift
//  videoeditor
//
//  Created by Anthony Ho on 31/08/2025.
//

import SwiftUI
import UIKit
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation


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
        let cornerRadius: CGFloat = 4.0
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
        let bracketCornerRadius: CGFloat = 4.0
        
        // Top-left bracket
        let topLeftBracket = CAShapeLayer()
        let topLeftPath = UIBezierPath()
        topLeftPath.move(to: CGPoint(x: rectX + bracketLength, y: rectY))
        topLeftPath.addLine(to: CGPoint(x: rectX + bracketCornerRadius, y: rectY))
        topLeftPath.addQuadCurve(to: CGPoint(x: rectX, y: rectY + bracketCornerRadius), 
                                controlPoint: CGPoint(x: rectX, y: rectY))
        topLeftPath.addLine(to: CGPoint(x: rectX, y: rectY + bracketLength))
        topLeftPath.lineCapStyle = .round
        topLeftPath.lineJoinStyle = .round
        topLeftBracket.path = topLeftPath.cgPath
        topLeftBracket.lineWidth = bracketWidth
        topLeftBracket.strokeColor = UIColor.white.cgColor
        topLeftBracket.fillColor = UIColor.clear.cgColor
        topLeftBracket.lineCap = .round
        topLeftBracket.lineJoin = .round
        viewController.view.layer.addSublayer(topLeftBracket)
        
        // Top-right bracket
        let topRightBracket = CAShapeLayer()
        let topRightPath = UIBezierPath()
        topRightPath.move(to: CGPoint(x: rectX + rectWidth - bracketLength, y: rectY))
        topRightPath.addLine(to: CGPoint(x: rectX + rectWidth - bracketCornerRadius, y: rectY))
        topRightPath.addQuadCurve(to: CGPoint(x: rectX + rectWidth, y: rectY + bracketCornerRadius),
                                 controlPoint: CGPoint(x: rectX + rectWidth, y: rectY))
        topRightPath.addLine(to: CGPoint(x: rectX + rectWidth, y: rectY + bracketLength))
        topRightPath.lineCapStyle = .round
        topRightPath.lineJoinStyle = .round
        topRightBracket.path = topRightPath.cgPath
        topRightBracket.lineWidth = bracketWidth
        topRightBracket.strokeColor = UIColor.white.cgColor
        topRightBracket.fillColor = UIColor.clear.cgColor
        topRightBracket.lineCap = .round
        topRightBracket.lineJoin = .round
        viewController.view.layer.addSublayer(topRightBracket)
        
        // Bottom-left bracket
        let bottomLeftBracket = CAShapeLayer()
        let bottomLeftPath = UIBezierPath()
        bottomLeftPath.move(to: CGPoint(x: rectX, y: rectY + rectHeight - bracketLength))
        bottomLeftPath.addLine(to: CGPoint(x: rectX, y: rectY + rectHeight - bracketCornerRadius))
        bottomLeftPath.addQuadCurve(to: CGPoint(x: rectX + bracketCornerRadius, y: rectY + rectHeight),
                                   controlPoint: CGPoint(x: rectX, y: rectY + rectHeight))
        bottomLeftPath.addLine(to: CGPoint(x: rectX + bracketLength, y: rectY + rectHeight))
        bottomLeftPath.lineCapStyle = .round
        bottomLeftPath.lineJoinStyle = .round
        bottomLeftBracket.path = bottomLeftPath.cgPath
        bottomLeftBracket.lineWidth = bracketWidth
        bottomLeftBracket.strokeColor = UIColor.white.cgColor
        bottomLeftBracket.fillColor = UIColor.clear.cgColor
        bottomLeftBracket.lineCap = .round
        bottomLeftBracket.lineJoin = .round
        viewController.view.layer.addSublayer(bottomLeftBracket)
        
        // Bottom-right bracket
        let bottomRightBracket = CAShapeLayer()
        let bottomRightPath = UIBezierPath()
        bottomRightPath.move(to: CGPoint(x: rectX + rectWidth - bracketLength, y: rectY + rectHeight))
        bottomRightPath.addLine(to: CGPoint(x: rectX + rectWidth - bracketCornerRadius, y: rectY + rectHeight))
        bottomRightPath.addQuadCurve(to: CGPoint(x: rectX + rectWidth, y: rectY + rectHeight - bracketCornerRadius),
                                    controlPoint: CGPoint(x: rectX + rectWidth, y: rectY + rectHeight))
        bottomRightPath.addLine(to: CGPoint(x: rectX + rectWidth, y: rectY + rectHeight - bracketLength))
        bottomRightPath.lineCapStyle = .round
        bottomRightPath.lineJoinStyle = .round
        bottomRightBracket.path = bottomRightPath.cgPath
        bottomRightBracket.lineWidth = bracketWidth
        bottomRightBracket.strokeColor = UIColor.white.cgColor
        bottomRightBracket.fillColor = UIColor.clear.cgColor
        bottomRightBracket.lineCap = .round
        bottomRightBracket.lineJoin = .round
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
