//
//  AddListingViewController.swift
//  Bookworm
//
//  Created by Mohammed Haque on 2/28/21.
//

import Foundation
import UIKit
import AVFoundation
import Vision
import VisionKit

class ScannerViewController: UIViewController, AddPostListingViewControllerDelegate, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, VNDocumentCameraViewControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
//    var recognizeTextRequest = VNRecognizeTextRequest()
//    var recognizedText = ""
//    var captureTimer = Timer()
//    var timePassed = false
    var animate = Animate()

    override func viewDidLoad() {
        super.viewDidLoad()
        popUpView.layer.cornerRadius = 10
        
//        captureTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.timerCalled), userInfo: nil, repeats: true)
        
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print(error)
            return
        }

        if captureSession?.canAddInput(videoInput) != nil {
            captureSession?.addInput(videoInput)
        } else {
            captureFailed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession?.canAddOutput(metadataOutput) != nil {
            captureSession?.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417]
        }
        else {
            captureFailed()
            return
        }
        
//        let videoDataOutput = AVCaptureVideoDataOutput()
//
//        if captureSession?.canAddOutput(videoDataOutput) != nil {
//            captureSession?.addOutput(videoDataOutput)
//
//            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
//            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
//        }
//        else {
//            captureFailed()
//            return
//        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession ?? AVCaptureSession())
        previewLayer?.frame = imageView.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        imageView.layer.addSublayer(previewLayer ?? AVCaptureVideoPreviewLayer())

        view.bringSubviewToFront(activityIndicator)
        activityIndicator.stopAnimating()
        
        captureSession?.startRunning()
//        recognizeTextHandler()
    }

    func captureFailed() {
        let ac = UIAlertController(title: "Camera not supported", message: "Your device does not support a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
//    @IBAction func scanButtonPressed() {
//        let documentCameraViewController = VNDocumentCameraViewController()
//        documentCameraViewController.delegate = self
//        self.present(documentCameraViewController, animated: true, completion: nil)
//    }
//
//    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
//        let image = scan.imageOfPage(at: 0)
//        let handler = VNImageRequestHandler(cgImage: image.cgImage?, options: [:])
//        do {
//            try handler.perform([recognizeTextRequest])
//        } catch {
//            print(error)
//        }
//
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        guard let vc = storyboard.instantiateViewController(withIdentifier: "addPostVC") as? AddPostViewController  else { assertionFailure("couldn't find vc"); return }
//        vc.inputSearch = recognizedText
//        let addPostVC = [vc]
//        self.navigationController?.setViewControllers(addPostVC, animated: true)
//
//        controller.dismiss(animated: true)
//    }
    
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        if timePassed {
//            let imageRequestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .down)
//
//            do {
//                try imageRequestHandler.perform([recognizeTextRequest])
//            } catch {
//                print(error)
//                return
//            }
//            timePassed = false
//        }
//    }
//
//    func recognizeTextHandler() {
//        recognizeTextRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in
//            if let results = request.results, !results.isEmpty {
//                if let requestResults = request.results as? [VNRecognizedTextObservation] {
//                    self.recognizedText = ""
//                    for observation in requestResults {
//                        guard let candidiate = observation.topCandidates(1).first else { return }
////                        print(candidiate.string)
//                        self.recognizedText += candidiate.string
//                        self.recognizedText += " "
//                    }
//                }
//            }
//        })
//        recognizeTextRequest.recognitionLevel = .accurate
//        recognizeTextRequest.usesLanguageCorrection = true
//    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession?.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            self.wait()
            
            OpenLibraryAPI.getAllInfoForISBN(stringValue, bookCoverSize: .M) { (response, error) in
                if response != nil {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(identifier: "addPostListingVC")
                    guard let addPostListingVC = vc as? AddPostListingViewController else {
                        assertionFailure("couldn't find vc")
                        return
                    }
                    
                    if let bookInfo = response {
                        if bookInfo["title"] != nil || bookInfo["publishDate"] != nil || bookInfo["authors"] != nil {
                            addPostListingVC.bookTitle = bookInfo["title"] as? String ?? ""
                            addPostListingVC.bookPublishDate = bookInfo["publishDate"] as? String ?? ""
        //                    addPostListingVC.bookAuthor = bookInfo["author"] as? String ?? ""
                            addPostListingVC.bookAuthors = bookInfo["authors"] as? [String] ?? []
                            addPostListingVC.bookISBN = bookInfo["isbn"] as? String ?? ""
                            addPostListingVC.bookCoverImageM = bookInfo["imageData"] as? Data
                            addPostListingVC.delegate = self
                            self.present(addPostListingVC, animated: true, completion: nil)
                        }
                        else {
                            self.errorLabel.text = "Invalid barcode."
                            self.animate.animateLabelInOut(self.errorLabel, 0.5, 0.5, 0.0, 2)
                            self.viewDidAppear(true)
                        }
                    }
                    self.start()
                }
                else if error != nil {
                    self.errorLabel.text = "Book couldn't be found."
                    self.animate.animateLabelInOut(self.errorLabel, 0.5, 0.5, 0.0, 2)
                }
            }
        }
    }
    
    func addPostListingVCDismissed() {
        if captureSession?.isRunning == false {
            captureSession?.startRunning()
//            captureTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.timerCalled), userInfo: nil, repeats: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if captureSession?.isRunning == false {
            captureSession?.startRunning()
//            captureTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.timerCalled), userInfo: nil, repeats: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
//            captureTimer.invalidate()
        }
    }
    
    @IBAction func didPressX(_ sender: Any) {
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
        self.dismiss(animated: true, completion: nil)
    }
    
//    @objc func timerCalled() {
//        timePassed = true
//    }
    
    //following two functions taken from hw solutions
    func wait() {
        self.activityIndicator.startAnimating()
        self.view.alpha = 0.2
        self.view.isUserInteractionEnabled = false
    }
    func start() {
        self.activityIndicator.stopAnimating()
        self.view.alpha = 1
        self.view.isUserInteractionEnabled = true
    }
}
