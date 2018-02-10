//
//  ViewController.swift
//  Bloom
//
//  Created by margot on 2018-02-09.
//  Copyright © 2018 foxberryfields. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()

    @IBOutlet weak var descriptionText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
    }
    
    
    @IBOutlet weak var photoTaken: UIImageView!
    
    @IBAction func cameraButton(_ sender: Any) {

        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let userPickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            //photoTaken.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert to CIImage")
            }
            detect(image: ciimage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage){
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model Failed")
        }
        
        let request = VNCoreMLRequest(model: model){(request, error) in
            guard let result = request.results as? [VNClassificationObservation] else {
                fatalError("Model Failed to process")
            }
            
            print(result)
            if let firstResult = result.first {
                    self.navigationItem.title = firstResult.identifier
                
                self.requestInfo(flowerName: firstResult.identifier)
                
                }
            }
            //print(result.first?.identifier)
        
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        }
        catch {
            print (error)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]

        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON
            { (response) in
                if response.result.isSuccess {
                    print("Got Wikipedia response")
                    //print(response)
                    
                    let flowerJSON: JSON = JSON(response.result.value!)
                    let pageID = flowerJSON["query"]["pageids"][0].stringValue
                    print(pageID)
                    let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue

                    let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                    
                    print(flowerDescription)
                    
                    self.photoTaken.sd_setImage(with: URL(string: flowerImageURL))
                    self.descriptionText.text = flowerDescription
                    
                }
        }
    }


}

