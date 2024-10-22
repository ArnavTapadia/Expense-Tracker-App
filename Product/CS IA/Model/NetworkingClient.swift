//
//  NetworkingClient.swift

import Foundation
import Alamofire //Using Alamofire library to manage networking requests

class NetworkingClient {

    //MARK: POST/GET to TabScanner
    static func uploadForOCR(image: UIImage, to url: URL, params: [String: Any], uploadCompletion: @escaping (Data?) -> Void) {
        //AF.upload(multipartFormData: <#T##(MultipartFormData) -> Void#>, to: <#T##URLConvertible#>) – function being used
        //convert image:UIImage to type Data for the .append function to use:
        let imageJpeg = image.jpegData(compressionQuality: 0.8)! //compression is 0.8 for high quality
        
        //Using multipartFormData as required by api
        AF.upload(multipartFormData: { multiPart in
            for (key, value) in params {
                if let temp = value as? String {
                    multiPart.append(temp.data(using: .utf8)!, withName: key)
                }
                if let temp = value as? Int {
                    multiPart.append("\(temp)".data(using: .utf8)!, withName: key)
                }
            }
            multiPart.append(imageJpeg, withName: "file", fileName: "file.png", mimeType: "image/png")
        }, to: url as URLConvertible)
            .uploadProgress(queue: .main, closure: { progress in
                //Current upload progress of file
            })
            .responseData(completionHandler: { responseData in
                //Do what ever you want to do with response
                //responseData is AF DataResponse<Any> object
                //.data returns a Data?
                //Check data is not nil with guard let then return
                uploadCompletion(responseData.data) //Closure called when function ends
            })
    }
    
    static func getOCRData(to url: URL, getCompletion: @escaping (Data?) -> Void) {
        //this function is called before upload is done
        //using Alamofire's request method – method is get by default
        AF.request(url).uploadProgress(queue: .main, closure: { progress in
            //Current upload progress of file
        })
        .responseData(completionHandler: { responseData in
            //Do what ever you want to do with response
            //responseData is AF DataResponse<Any> object
            //.data returns a Data?
            getCompletion(responseData.data) //Closure called when function ends
        })
        
        
    }
    
    static func parseJson(parse data: Data) -> [String:Any] {
        var serializationStatus = 0
        var jsonReturn: [String:Any] = [:]
        do {
            //JSONSerialization is a library in swift
            //JSONSerialization library imported within import Foundation
            //Converts type Data? to [String:Any] dictionary
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                jsonReturn = json
            }
        } catch let error {
            print(error.localizedDescription)
            serializationStatus = 1
        }
        jsonReturn["serializationStatus"] = serializationStatus
        return jsonReturn
    }
    
}
