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
    @Binding var captureRect: CGRect
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraView
        var photoOutput: AVCapturePhotoOutput?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var captureDevice: AVCaptureDevice?
        
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
            
            // Listen for flash toggle notification
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(toggleFlash(_:)),
                name: NSNotification.Name("ToggleFlash"),
                object: nil
            )
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else { return }

                    guard let previewLayer = self.previewLayer else {
            DispatchQueue.main.async {
                self.parent.capturedImage = image
            }
            return
        }

        let captureRect = self.parent.captureRect
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
        
        context.coordinator.captureDevice = device
        
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
        
        // Create mask for the capture area (will be updated dynamically)
        let cornerRadius: CGFloat = 8.0
        let path = UIBezierPath(roundedRect: captureRect, cornerRadius: cornerRadius)
        let maskLayer = CAShapeLayer()
        let fullPath = UIBezierPath(rect: viewController.view.bounds)
        fullPath.append(path)
        maskLayer.path = fullPath.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer
        
        viewController.view.addSubview(overlayView)
        
        // Store reference to overlay and mask for dynamic updates
        overlayView.tag = 999 // Tag to identify this view for updates
        maskLayer.name = "captureMask"
        
        // Note: Capture button is now handled by SwiftUI overlay
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update the overlay mask when captureRect changes
        if let overlayView = uiViewController.view.subviews.first(where: { $0.tag == 999 }),
           let maskLayer = overlayView.layer.mask as? CAShapeLayer {
            
            // Use the overlay view bounds to ensure proper masking
            let overlayBounds = overlayView.bounds
            let cornerRadius: CGFloat = 8.0
            
            // Create the cutout path - this creates the clear window
            let cutoutPath = UIBezierPath(roundedRect: captureRect, cornerRadius: cornerRadius)
            
            // Create the full overlay path
            let fullPath = UIBezierPath(rect: overlayBounds)
            fullPath.append(cutoutPath)
            
            // Use even-odd fill rule to create the cutout effect
            CATransaction.begin()
            CATransaction.setDisableActions(true) // Disable implicit animations to prevent layout issues
            maskLayer.path = fullPath.cgPath
            maskLayer.fillRule = .evenOdd
            CATransaction.commit()
        }
    }
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
    
    @objc func toggleFlash(_ notification: Notification) {
        guard let isFlashOn = notification.object as? Bool,
              let device = captureDevice,
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = isFlashOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Error toggling flash: \(error)")
        }
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
