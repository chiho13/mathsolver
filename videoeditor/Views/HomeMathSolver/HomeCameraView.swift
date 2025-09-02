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
    @Binding var originalImage: UIImage?
    @Binding var captureRect: CGRect
    @ObservedObject var viewModel: VisionViewModel
    @Binding var triggerCapture: Bool
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraView
        var photoOutput: AVCapturePhotoOutput?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var captureDevice: AVCaptureDevice?
        var initialZoomFactor: CGFloat = 1.0
        
        init(parent: CameraView) {
            self.parent = parent
            super.init()
            
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
                self.parent.originalImage = image
                self.parent.capturedImage = image
                self.parent.viewModel.isAnimatingCroppedArea = false
            }
            return
        }

        let captureRect = self.parent.captureRect
        let metadataOutputRect = previewLayer.metadataOutputRectConverted(fromLayerRect: captureRect)
            let croppedImage = self.cropImage(image, to: metadataOutputRect)

            DispatchQueue.main.async {
                self.parent.originalImage = image
                self.parent.capturedImage = croppedImage ?? image
                self.parent.viewModel.isAnimatingCroppedArea = false
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
        
        // Add gesture recognizers for zoom and focus
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinchGesture(_:)))
        viewController.view.addGestureRecognizer(pinchGesture)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTapGesture(_:)))
        viewController.view.addGestureRecognizer(tapGesture)
        
        // Note: Capture button is now handled by SwiftUI overlay
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if triggerCapture {
            context.coordinator.capturePhoto()
            DispatchQueue.main.async {
                self.triggerCapture = false
            }
        }
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
            
            // Animation is now handled in SwiftUI layer above this view
        }
    }
    
    private func addPulsingAnimation(to view: UIView) {
        // Remove any existing animation first
        removePulsingAnimation(from: view)
        
        // Create a container view that will be clipped by the mask
        let animationContainer = UIView(frame: view.bounds)
        animationContainer.backgroundColor = .clear
        animationContainer.tag = 1001 // Tag to identify the animation container
        
        // Add the container to the view and bring it to front so it appears above everything
        view.addSubview(animationContainer)
        view.bringSubviewToFront(animationContainer)
        
        // Create 12 white pulsing dots at random positions within the capture rect
        let dotSize: CGFloat = 6.0
        let numberOfDots = 12
        
        // Calculate usable area (leave some margin from edges)
        let margin: CGFloat = 20.0
        let usableRect = CGRect(
            x: captureRect.origin.x + margin,
            y: captureRect.origin.y + margin,
            width: captureRect.width - (margin * 2),
            height: captureRect.height - (margin * 2)
        )
        
        for i in 0..<numberOfDots {
            // Generate random position within the usable area
            let randomX = usableRect.origin.x + CGFloat.random(in: 0...usableRect.width - dotSize)
            let randomY = usableRect.origin.y + CGFloat.random(in: 0...usableRect.height - dotSize)
            
            // Create white dot
            let dot = UIView(frame: CGRect(x: randomX, y: randomY, width: dotSize, height: dotSize))
            dot.backgroundColor = UIColor.white
            dot.layer.cornerRadius = dotSize / 2
            dot.tag = 1000 + i // Tag to identify dots (1000-1011)
            
            // Add subtle shadow for better visibility
            dot.layer.shadowColor = UIColor.white.cgColor
            dot.layer.shadowOffset = CGSize(width: 0, height: 0)
            dot.layer.shadowRadius = 3.0
            dot.layer.shadowOpacity = 0.8
            
            animationContainer.addSubview(dot)
            
            // Create random pulsing animation for each dot
            let pulseAnimation = CABasicAnimation(keyPath: "opacity")
            pulseAnimation.fromValue = 1.0
            pulseAnimation.toValue = 0.2
            
            // Random duration between 0.8 and 2.0 seconds
            let randomDuration = Double.random(in: 0.8...2.0)
            pulseAnimation.duration = randomDuration
            
            // Random delay to stagger the animations
            let randomDelay = Double.random(in: 0...1.0)
            pulseAnimation.beginTime = CACurrentMediaTime() + randomDelay
            
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = .infinity
            
            // Add scale animation for more dynamic effect
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = 1.0
            scaleAnimation.toValue = 1.5
            scaleAnimation.duration = randomDuration
            scaleAnimation.beginTime = CACurrentMediaTime() + randomDelay
            scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            scaleAnimation.autoreverses = true
            scaleAnimation.repeatCount = .infinity
            
            // Group the animations
            let animationGroup = CAAnimationGroup()
            animationGroup.animations = [pulseAnimation, scaleAnimation]
            animationGroup.duration = randomDuration
            animationGroup.beginTime = CACurrentMediaTime() + randomDelay
            animationGroup.repeatCount = .infinity
            
            dot.layer.add(animationGroup, forKey: "pulsingDot\(i)")
        }
        
        print("Added \(numberOfDots) pulsing dots in capture area")
    }
    
    private func removePulsingAnimation(from view: UIView) {
        // Remove the animation container which contains all animation elements
        if let animationContainer = view.subviews.first(where: { $0.tag == 1001 }) {
            print("Removing animation container with dots")
            animationContainer.removeFromSuperview()
        }
        
        // Fallback: remove individual dots if container doesn't exist
        for tag in 1000...1011 {
            if let dot = view.subviews.first(where: { $0.tag == tag }) {
                dot.removeFromSuperview()
            }
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

                // Optionally, show a focus indicator
                showFocusIndicator(at: touchPoint, in: gesture.view)

            } catch {
                print("Error setting focus point: \(error)")
            }
        }
    }

   
   private func showFocusIndicator(at point: CGPoint, in view: UIView?) {
    guard let view = view else { return }

    // Remove existing indicators
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

    // Fade-in
    let fadeIn = CABasicAnimation(keyPath: "opacity")
    fadeIn.fromValue = 0
    fadeIn.toValue = 1
    fadeIn.duration = 0.3

    // Scale-in path (105% → 100%)
    let scaleInPath = CABasicAnimation(keyPath: "path")
    scaleInPath.fromValue = UIBezierPath(
        ovalIn: indicatorRect.insetBy(dx: indicatorSize*0.05, dy: indicatorSize*0.05) // slightly bigger
    ).cgPath
    scaleInPath.toValue = UIBezierPath(ovalIn: indicatorRect).cgPath
    scaleInPath.duration = 0.3
    scaleInPath.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

    let appearGroup = CAAnimationGroup()
    appearGroup.animations = [fadeIn, scaleInPath]
    appearGroup.duration = 0.3
    appearGroup.beginTime = 0

    // Pulse
    let pulse = CABasicAnimation(keyPath: "opacity")
    pulse.fromValue = 1
    pulse.toValue = 0.4
    pulse.duration = 0.1
    pulse.autoreverses = true
    pulse.repeatCount = 2
    pulse.beginTime = appearGroup.beginTime + appearGroup.duration

    // Fade-out
    let fadeOut = CABasicAnimation(keyPath: "opacity")
    fadeOut.fromValue = 1
    fadeOut.toValue = 0
    fadeOut.duration = 0.5

    // Scale-out path (100% → 96%)
    let scaleOutPath = CABasicAnimation(keyPath: "path")
    scaleOutPath.fromValue = UIBezierPath(ovalIn: indicatorRect).cgPath
    scaleOutPath.toValue = UIBezierPath(
        ovalIn: indicatorRect.insetBy(dx: indicatorSize*0.05, dy: indicatorSize*0.05) // slightly smaller
    ).cgPath
    scaleOutPath.duration = 0.3
    scaleOutPath.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

    let disappearGroup = CAAnimationGroup()
    disappearGroup.animations = [fadeOut, scaleOutPath]
    disappearGroup.duration = 0.2
    disappearGroup.beginTime = pulse.beginTime + (pulse.duration * Double(pulse.repeatCount) * 2.0)

    // Master group
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
