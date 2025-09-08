//
//  AdvancedCameraView.swift
//  videoeditor
//
//  Created by Gemini on 07/07/2024.
//

import SwiftUI
import UIKit
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var originalImage: UIImage?
    @Binding var captureRect: CGRect
    @ObservedObject var viewModel: VisionViewModel
    @Binding var triggerCapture: Bool
    @Binding var freezeImage: UIImage?
    
    class Coordinator: NSObject {
        var parent: CameraView
        var photoOutput: AVCapturePhotoOutput?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var captureSession: AVCaptureSession?
        var captureDevice: AVCaptureDevice?
        var initialZoomFactor: CGFloat = 1.0
        var currentZoomFactor: CGFloat = 1.0
        var snapshotView: UIImageView?
        var viewControllerView: UIView?
        
        init(parent: CameraView) {
            self.parent = parent
            super.init()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(toggleFlash(_:)),
                name: NSNotification.Name("ToggleFlash"),
                object: nil
            )
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
            // CRITICAL: Stop the capture session when the coordinator is deallocated
            if let session = captureSession, session.isRunning {
                session.stopRunning()
                print("AVCaptureSession stopped.")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
   func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> UIViewController {
    let viewController = UIViewController()
    context.coordinator.viewControllerView = viewController.view
    
    // Initialize the session
    let session = AVCaptureSession()
    session.sessionPreset = .photo
    
    guard let device = AVCaptureDevice.default(for: .video),
          let input = try? AVCaptureDeviceInput(device: device) else {
        DispatchQueue.main.async {
            self.viewModel.errorMessage = "Failed to access camera. Please check your device settings."
        }
        return viewController
    }
    
    // Store the session and device in the coordinator
    context.coordinator.captureSession = session
    context.coordinator.captureDevice = device
    
    let output = AVCapturePhotoOutput()
    context.coordinator.photoOutput = output
    
    // Configure the session
    session.beginConfiguration()
    if session.canAddInput(input) {
        session.addInput(input)
    }
    if session.canAddOutput(output) {
        session.addOutput(output)
    }
    session.commitConfiguration()
    
    // Start the session on the main thread
    DispatchQueue.main.async {
        if !session.isRunning {
            session.startRunning()
            print("AVCaptureSession started.")
        }
    }
    
    // Set up the preview layer
    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = viewController.view.bounds
    context.coordinator.previewLayer = previewLayer
    
    viewController.view.layer.addSublayer(previewLayer)
    
    // Setup the overlay for the capture rect
    let overlayView = UIView(frame: viewController.view.bounds)
    overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    
    let cornerRadius: CGFloat = 8.0
    let path = UIBezierPath(roundedRect: captureRect, cornerRadius: cornerRadius)
    let maskLayer = CAShapeLayer()
    let fullPath = UIBezierPath(rect: viewController.view.bounds)
    fullPath.append(path)
    maskLayer.path = fullPath.cgPath
    maskLayer.fillRule = .evenOdd
    overlayView.layer.mask = maskLayer
    
    viewController.view.addSubview(overlayView)
    overlayView.tag = 999
    maskLayer.name = "captureMask"
    
    // Setup the snapshot view for freezing the camera view
    let snapshotView = UIImageView(frame: viewController.view.bounds)
    snapshotView.contentMode = .scaleAspectFill
    snapshotView.clipsToBounds = true
    snapshotView.isHidden = true
    viewController.view.addSubview(snapshotView)
    context.coordinator.snapshotView = snapshotView
    
    let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinchGesture(_:)))
    viewController.view.addGestureRecognizer(pinchGesture)
    
    let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTapGesture(_:)))
    viewController.view.addGestureRecognizer(tapGesture)
    
    return viewController
}
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<CameraView>) {
        if triggerCapture {
            context.coordinator.capturePhoto()
            DispatchQueue.main.async {
                self.triggerCapture = false
            }
        }
        
        // Update the capture rect overlay
        if let overlayView = uiViewController.view.subviews.first(where: { $0.tag == 999 }),
           let maskLayer = overlayView.layer.mask as? CAShapeLayer {
            let overlayBounds = overlayView.bounds
            let cornerRadius: CGFloat = 8.0
            
            let cutoutPath = UIBezierPath(roundedRect: captureRect, cornerRadius: cornerRadius)
            let fullPath = UIBezierPath(rect: overlayBounds)
            fullPath.append(cutoutPath)
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            maskLayer.path = fullPath.cgPath
            maskLayer.fillRule = .evenOdd
            CATransaction.commit()
        }
        
        // This is the core logic for freezing the image.
        // We use the `freezeImage` binding to control the state of the camera view.
        if let freezeImage = freezeImage {
            context.coordinator.snapshotView?.image = freezeImage
            context.coordinator.snapshotView?.isHidden = false
            context.coordinator.previewLayer?.isHidden = true
        } else {
            context.coordinator.snapshotView?.isHidden = true
            context.coordinator.previewLayer?.isHidden = false
        }
        
        // Update the frame of the preview layer to match the view controller's view
        uiViewController.view.frame = UIScreen.main.bounds
        context.coordinator.previewLayer?.frame = uiViewController.view.bounds
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraView.Coordinator: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard let imageData = photo.fileDataRepresentation(),
          let image = UIImage(data: imageData) else {
        DispatchQueue.main.async {
            self.parent.viewModel.isAnimatingShutter = false
            self.parent.viewModel.errorMessage = "Failed to capture image. Please try again."
        }
        return
    }
    
    // Add haptic feedback for a successful capture
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
    
    let captureRect = self.parent.captureRect
    
    // Convert the on-screen capture rect to the photo's coordinate space
    let metadataOutputRect = previewLayer?.metadataOutputRectConverted(fromLayerRect: captureRect) ?? .zero
    let croppedImage = self.cropImage(image, to: metadataOutputRect)
    
    // Set the frozen image to the full, uncropped image
    let frozenImage = image
    
    DispatchQueue.main.async {
        self.parent.freezeImage = frozenImage
        self.parent.originalImage = image
        self.parent.capturedImage = croppedImage ?? image
        
        self.parent.viewModel.isAnimatingShutter = false
        self.parent.viewModel.isAnimatingCroppedArea = true
        
        // Send the cropped image to the backend
        if let croppedImage = croppedImage {
            self.parent.viewModel.selectedImage = croppedImage
            Task {
                await self.parent.viewModel.solveMathProblem(deductCredit: false)
            }
        } else {
            self.parent.viewModel.errorMessage = "Failed to crop the image. Please try again."
            self.parent.viewModel.isAnimatingCroppedArea = false
        }
    }
    
    reapplyZoomFactor()
}
}

// MARK: - Gesture Handling
extension CameraView.Coordinator {
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let device = captureDevice else { return }
        
        if gesture.state == .began {
            initialZoomFactor = device.videoZoomFactor
        }
        
        if gesture.state == .changed {
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            let desiredZoomFactor = initialZoomFactor * gesture.scale
            
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = max(1.0, min(desiredZoomFactor, maxZoomFactor))
                currentZoomFactor = device.videoZoomFactor
            } catch {
                print("Error locking device for configuration: \(error)")
            }
        }
    }
    
    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        guard let device = captureDevice, let previewLayer = self.previewLayer else { return }
        
        let touchPoint = gesture.location(in: gesture.view)
        let convertedPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: touchPoint)
        
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = convertedPoint
                device.focusMode = .autoFocus
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                    device.exposurePointOfInterest = convertedPoint
                    device.exposureMode = .autoExpose
                }
                
                device.unlockForConfiguration()
                
                // Add haptic feedback for focus
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                showFocusIndicator(at: touchPoint, in: gesture.view)
            } catch {
                print("Error setting focus point: \(error)")
            }
        }
    }
}

// MARK: - Helper Methods
extension CameraView.Coordinator {
    private func reapplyZoomFactor() {
        guard let device = captureDevice else { return }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            device.videoZoomFactor = max(1.0, min(currentZoomFactor, maxZoomFactor))
        } catch {
            print("Error reapplying zoom factor: \(error)")
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
    
    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    private func showFocusIndicator(at point: CGPoint, in view: UIView?) {
        guard let view = view else { return }
        
        view.layer.sublayers?.filter { $0.name == "focusIndicator" }.forEach { $0.removeFromSuperlayer() }
        
        let indicatorLayer = CAShapeLayer()
        indicatorLayer.name = "focusIndicator"
        let indicatorSize: CGFloat = 35
        let indicatorRect = CGRect(
            x: point.x - indicatorSize / 2,
            y: point.y - indicatorSize / 2,
            width: indicatorSize,
            height: indicatorSize
        )
        indicatorLayer.path = UIBezierPath(ovalIn: indicatorRect).cgPath
        indicatorLayer.fillColor = UIColor.clear.cgColor
        indicatorLayer.strokeColor = UIColor.white.cgColor
        indicatorLayer.lineWidth = 2
        indicatorLayer.opacity = 0.0
        view.layer.addSublayer(indicatorLayer)
        
        let fadeIn = CABasicAnimation(keyPath: "opacity")
        fadeIn.fromValue = 0
        fadeIn.toValue = 1
        fadeIn.duration = 0.3
        
        let scaleInPath = CABasicAnimation(keyPath: "path")
        scaleInPath.fromValue = UIBezierPath(
            ovalIn: indicatorRect.insetBy(dx: indicatorSize*0.05, dy: indicatorSize*0.05)
        ).cgPath
        scaleInPath.toValue = UIBezierPath(ovalIn: indicatorRect).cgPath
        scaleInPath.duration = 0.3
        scaleInPath.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let appearGroup = CAAnimationGroup()
        appearGroup.animations = [fadeIn, scaleInPath]
        appearGroup.duration = 0.3
        appearGroup.beginTime = 0
        
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1
        pulse.toValue = 0.4
        pulse.duration = 0.1
        pulse.autoreverses = true
        pulse.repeatCount = 2
        pulse.beginTime = appearGroup.beginTime + appearGroup.duration
        
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 1
        fadeOut.toValue = 0
        fadeOut.duration = 0.5
        
        let scaleOutPath = CABasicAnimation(keyPath: "path")
        scaleOutPath.fromValue = UIBezierPath(ovalIn: indicatorRect).cgPath
        scaleOutPath.toValue = UIBezierPath(
            ovalIn: indicatorRect.insetBy(dx: indicatorSize*0.05, dy: indicatorSize*0.05)
        ).cgPath
        scaleOutPath.duration = 0.3
        scaleOutPath.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let disappearGroup = CAAnimationGroup()
        disappearGroup.animations = [fadeOut, scaleOutPath]
        disappearGroup.duration = 0.2
        disappearGroup.beginTime = pulse.beginTime + (pulse.duration * Double(pulse.repeatCount) * 2.0)
        
        let masterGroup = CAAnimationGroup()
        masterGroup.animations = [appearGroup, pulse, disappearGroup]
        masterGroup.duration = disappearGroup.beginTime + disappearGroup.duration
        masterGroup.fillMode = .forwards
        masterGroup.isRemovedOnCompletion = false
        
        indicatorLayer.add(masterGroup, forKey: "focusAnimation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + masterGroup.duration) {
            indicatorLayer.removeFromSuperlayer()
        }
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
