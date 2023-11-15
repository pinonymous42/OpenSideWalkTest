//
//  ViewController.swift
//  EdgeNetsCV
//
//  ViewController for CameraView
//
//  Created by Sachin on 7/2/19.
//  Copyright © 2019 Sachin Mehta. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Vision
import CoreML
import Accelerate
import VideoToolbox


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var AnnotView: UIView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var segView: UIImageView!
    @IBOutlet weak var SmallGrid: UICollectionView!
    
    private var imageTaken = false
    private var requests = [VNRequest]()
    
    //espnet model
    let espnet_model = espnetv2_pascal_256()
    
    //new variables
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil
    
    private let session = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "videoQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private let photoOutput = AVCapturePhotoOutput()
    private let reuseIdentifier = "ChooserCell"
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private var output: AVCapturePhotoOutput?
    
    private var videoDevice: AVCaptureDevice?
    private var deviceInput: AVCaptureDeviceInput!
    
    // define the filter that will convert the grayscale prediction to color image
    let masker = ColorMasker()
    
    // handled by segue
    var classes = [String]();
    var selection = [Int]();
    private var capImage: UIImage!
    private var capSeg: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        setupAVCapture(position: .back)
        
        //setup vision parts
        setupVisionModel()
        
        //start the capture
        startCaptureSession()
        
        print("camera view classes", classes)
        print("camera view selection", selection)
    }
    
    func startCaptureSession(){
        session.startRunning()
    }
    
    func stopCaptureSession(){
        session.stopRunning()
        session.removeInput(_: deviceInput)
        session.removeOutput(_: videoDataOutput)
    }
    
    func getDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices.first
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selection.count
    }
    
    // populate collection view with cells
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SmallCell", for: indexPath) as! CollectionViewCell
        cell.CellLabel.text = classes[selection[indexPath.item]]
        
        cell.backgroundColor = UIColor(
            red: CGFloat((selection[indexPath.item] * selection[indexPath.item] * 7) % 255) / 255.0,
            green: CGFloat(12 * selection[indexPath.item]) / 255.0,
            blue: CGFloat((((selection[indexPath.item] * selection[indexPath.item]) % 21) * 39) % 255) / 255.0, alpha: 1.0);
        return cell
    }
    
    func setupAVCapture(position: AVCaptureDevice.Position){
        
        //select a video device
        videoDevice = getDevice(position: position)
        
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        
        //video format
        session.sessionPreset = .vga640x480
        
        //add video input
        guard session.canAddInput(deviceInput) else{
            print("Could not add video device input to the session2")
            session.commitConfiguration()
            return
        }
        
        session.addInput(deviceInput)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            print("Added video data output to the session")

            //add video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true

            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else{
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            print("Added still image output to the session")
        } else{
            print("Could not add still image output to the session")
            session.commitConfiguration()
            return
        }
        
        let captureConnection = videoDataOutput.connection(with: .video)
        //always process the frames
        captureConnection?.isEnabled = true
        do{
            try videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch{
            print(error)
        }
        
        session.commitConfiguration()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        rootLayer = cameraView.layer
        rootLayer.bounds = cameraView.bounds
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
        
        cameraView.bringSubview(toFront: segView)
    }
    
    func setupVisionModel() {
        guard let visionModel = try? VNCoreMLModel(for: espnet_model.model) else{
            fatalError("Can not load CNN model")
        }
        
        let segmentationRequest = VNCoreMLRequest(model: visionModel, completionHandler: {request, error in
            DispatchQueue.main.async(execute: {
                if let results = request.results {
                    self.processSegmentationRequest(results)
                }
            })
        })
        segmentationRequest.imageCropAndScaleOption = .scaleFill
        self.requests = [segmentationRequest]
    }
    
    func processSegmentationRequest(_ observations: [Any]){
        let obs = observations as! [VNPixelBufferObservation]
        
        if obs.isEmpty{
            print("Empty")
        }
        
        let outPixelBuffer = (obs.first)!
        let segMaskGray = CIImage(cvPixelBuffer: outPixelBuffer.pixelBuffer)
        
        //pass through the filter that converts grayscale image to different shades of red
        self.masker.inputGrayImage = segMaskGray
        
        // add to the image view
        self.segView.image = UIImage(ciImage: self.masker.outputImage!, scale: 1.0, orientation: .right)
    }
    
    
    // this function notifies AVCaptureDelegate everytime a new frame is received
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        var imageRequestHandler: VNImageRequestHandler
        
        if (videoDevice?.position == AVCaptureDevice.Position.back) {
            // video device back
            imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        } else {
            // video device front
            imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        }

        do {
            try imageRequestHandler.perform(self.requests)
        } catch{
            print(error)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // handle change camera btn
    @IBAction func changeCamera(_ sender: UIButton) {
        stopCaptureSession()
        setupAVCapture(position: videoDevice?.position == AVCaptureDevice.Position.back ? .front : .back)
        setupVisionModel()
        startCaptureSession()
    }
    
    // prepare segue to AnnotationViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if (segue.identifier == "photoSegue") {
            let vc = segue.destination as? AnnotationViewController
            vc?.capImage = capImage
            vc?.capSeg = capSeg
            vc?.classes = classes
            vc?.selection = selection
        }
    }
    
    // handle camera btn
    @IBAction func takePhoto(_ sender: UIButton) {
        let photoSettings = AVCapturePhotoSettings()
        let previewPixelType = photoSettings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160]
        photoSettings.previewPhotoFormat = previewFormat
        
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
        imageTaken = true
    }
    
    // handle photo capture and trigger segue
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {

        if let error = error {
            print("error occured : \(error.localizedDescription)")
        }

        if  let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {

            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)

            self.capImage = image

            self.capSeg = UIImage(ciImage: self.masker.outputImage!, scale: 1.0, orientation: .right)
            
            print("image", image)
            print("capturedImage", capImage)
            
            self.performSegue(withIdentifier: "photoSegue", sender: self)
        } else {
            print("error")
        }
    }
}


//converts the Grayscale image to RGB
// r = class * class * 7 mod 255
// g = class * 12
// b = class * class mod 21 * 39 mod 255
class ColorMasker: CIFilter
{
    var inputGrayImage : CIImage?
    
    let colormapKernel = CIColorKernel(source:
        "kernel vec4 colorMasker(__sample gray)" +
            "{" +
            " if (gray.r == 0.0f) {return vec4(0.0, 0.0, 0.0, 0.0);} else {" +
            "vec4 result;" +
//            "int class;" +
//            "class = (int)(1 / gray.r);" +
//            "result.r = (float)((((gray.r * 255 / 12) * (gray.r * 255 / 12) * 7) % 255) / 255);" +
//            "result.g = gray.r;" +
//            "result.b = (float)((((((gray.r * 255 / 12) * (gray.r * 255 / 12)) % 21) * 39) % 255) / 255);" +
            "result.r = 1;" +
            "result.g = gray.r;" +
            "result.b = gray.r;" +
            "result.a = 0.9;" +
            "return result;" +
        "}}"
    )
    
    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "Color masker",
            
            "inputGrayImage": [kCIAttributeIdentity: 0,
                              kCIAttributeClass: "CIImage",
                              kCIAttributeDisplayName: "Grayscale Image",
                              kCIAttributeType: kCIAttributeTypeImage
            ]
        ]
    }
    
    override var outputImage: CIImage!
    {
        guard let inputGrayImage = inputGrayImage,
            let colormapKernel = colormapKernel else
        {
            return nil
        }
        
        let extent = inputGrayImage.extent
        let arguments = [inputGrayImage]
        
        return colormapKernel.apply(extent: extent, arguments: arguments)
    }
}
