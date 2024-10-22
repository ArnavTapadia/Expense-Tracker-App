//
//  CameraViewController.swift

//Tabscanner URl: https://api.tabscanner.com/{api_key}/process
//Tabscanner API Key: xQngF5pQoxXOC0tM1PGJaFVCkrmiWpfJO721MvoNlSFYjlTQ7atZe3747bQIMLti

import Foundation
import UIKit
import Photos
import Firebase

class CameraViewController : UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: Properties
    
    @IBOutlet weak var imageDisplay: UIImageView!
    
    
    let pickerController = UIImagePickerController() // UIImagePickerController is a view controller that lets a user pick media from their photo library.

    override func viewDidLoad() {
        super.viewDidLoad()
        pickerController.delegate = self //Make sure CameraViewController is notified when the user picks an image.
        pickerController.allowsEditing = false
        pickerController.mediaTypes = ["public.image"]
        checkPermission()
    }
    
    //MARK: checkPermissions
    private func checkPermission() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            print("Access granted by user")
        case .notDetermined:
            print("Not Determined") //THIS IS WHAT HAPPENS
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                
                if (newStatus == PHAuthorizationStatus.authorized) {
                    print("Access granted by user")
                } else {
                    print("Access denied by user")
                }
            })
        case .restricted:
            print("restrictted")
        case .denied:
            print("denied")
        @unknown default:
            print("unknown")
        }
    }
    
    
    //MARK: Actions
    @IBAction func photosTapped(_ sender: Any) {
        
        pickerController.sourceType = .photoLibrary //Only photos picked from photolibrary
        self.present(pickerController, animated : true, completion : nil)
        
    }
    
    @IBAction func cameraTapped(_ sender: Any) {
        
        pickerController.sourceType = .camera //Only photos taken from camera
        self.present(pickerController, animated : true, completion : nil)
    }
    
    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //Dismiss the picker if the user canceled
        dismiss(animated: true, completion: nil)
    }
    
    @objc func imagePickerController(_ pickerController: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        self.imageDisplay.contentMode = .scaleAspectFit
        self.imageDisplay.image = chosenImage
        
        pickerController.dismiss(animated: true, completion: nil)
        
        post(with: chosenImage)
    }
    
    private func post(with image: UIImage) {

        var parsedUpload: [String:Any] = ["":""]
        var receiptUploadToken: String = ""
        var duplicate: Bool = false
        
        var uploadComponents = URLComponents() //Create url components
        uploadComponents.scheme = "https"
        uploadComponents.host = "api.tabscanner.com"
        uploadComponents.path = "/xQngF5pQoxXOC0tM1PGJaFVCkrmiWpfJO721MvoNlSFYjlTQ7atZe3747bQIMLti/process"
        
        guard let uploadUrlToExecute = uploadComponents.url else {
            return
        }
        //Parameters of the upload
        let parameters = [
            "decimalPlaces": 2,
            ] as [String : Any]
        
        //Calling upload function from networking client
        //Everything inside closure because upload is asynchronous
        NetworkingClient.uploadForOCR(image: image, to: uploadUrlToExecute, params: parameters) { (jsonData) in
            //Create Receipt object containing this data
            parsedUpload = NetworkingClient.parseJson(parse: jsonData!)
            //checking if JSONSerialization failed
            if parsedUpload["serializationStatus"] as! Int == 1 {
                print("JSONSerialization error – retake photo")
            } //else do nothing
            //checking API's upload response codes
            switch parsedUpload["code"] as! Int {
            case 200:
                print("Image uploaded successfully")
            case 300:
                print("Image uploaded, but did not meet the recommended dimension of 720x1280 (WxH)")
            case 403:
                print("No file detected") //should never happen
            case 407:
                print("Unsupported file extension – reupload")
            default:
                print(parsedUpload["code"]!)
            }
            
            if (parsedUpload["duplicateToken"] as? String) != nil {
                receiptUploadToken = parsedUpload["duplicateToken"] as! String
                duplicate = true
            } else {
                receiptUploadToken = parsedUpload["token"] as! String
            }

            //Getting upload result
            var getComponents = URLComponents() //Create url components for upload (path changes)
            getComponents.scheme = "https"
            getComponents.host = "api.tabscanner.com"
            getComponents.path = "/xQngF5pQoxXOC0tM1PGJaFVCkrmiWpfJO721MvoNlSFYjlTQ7atZe3747bQIMLti/result/\(receiptUploadToken)"
            
            guard let getURL = getComponents.url else {
                print("Invalid")
                return
            }
            
            
            self.get(from: getURL, using: image, isduplicate: duplicate, withToken: receiptUploadToken)

        }
    }
    
    private func get(from getURL:URL, using image:UIImage, isduplicate duplicate:Bool, withToken receiptUploadToken:String) {
            var parsedGET: [String:Any] = ["":""]
            //Takes about 5.0s for upload to be processed
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                NetworkingClient.getOCRData(to: getURL) { (receiptJSON) in
                    parsedGET = NetworkingClient.parseJson(parse: receiptJSON!)
                    //checking if JSONSerialization failed
                    if parsedGET["serializationStatus"] as! Int == 1 {
                        let alert = UIAlertController(title: "Upload faile", message: "Try Again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                    } //else do nothing
                    //checking API's get response codes
                    switch parsedGET["code"] as! Int {
                    case 202:
                        let destinationViewController = self.storyboard?.instantiateViewController(withIdentifier: "ConfirmReceiptViewController") as! ConfirmReceiptViewController //Segueing to ConfirmReceiptViewController
                        let receipt = Receipt(uploadResponse: parsedGET, uploadToken: receiptUploadToken, hasBeenUploaded: duplicate)
                        destinationViewController.passData(withReceipt: receipt)
                        self.navigationController?.pushViewController(destinationViewController, animated: true)
                    case 301:
                        //Result not yet available
                        self.get(from: getURL, using: image, isduplicate: duplicate, withToken: receiptUploadToken)
                    case 401:
                        print("Not enough credit")
                    case 402:
                        print("Token not found")
                    default:
                        print(parsedGET["code"]!)
                    }
            }
        }
    }
    
    
    //Logout
    
    @IBAction func logOutTapped(_ sender: Any) {
        try! Auth.auth().signOut()
    }
    
    
}
