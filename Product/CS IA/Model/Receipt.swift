//
//  Receipt.swift

/* This class is used for uploading receipt images to TabScanner, and then downloading the ocr
    result in a JSON encoded format.
    Result will then be uploaded to firebase database using a class which will be created called DatabaseClient
    DatabaseClient needs to look through the existing database and put the corresponding items from the receipt
    being uploaded into their corresponding categories –  – and who bought the items (user or friend)
 */

import Foundation
import UIKit
import Alamofire

/* From parsedUpload; use: duplicate:boolean(1 or 0)–use to tell if user has reuploaded, token:String
    From parsedGet; use: lineItems:Array of objects, totalConfidence:float, (sub)total:float, date:String (if nil-use phone upload date)
    lineItem object; use: lineTotal:float, desc:String –contains words on same line as lineTotal, descClean:String —may contain weight (e.g 500G/GM or 0.84x12.90/KG, qty:int (defaults to 0), unit:float –may contain weight
 */

//TODO: Use static variable for getting data array from Firebase

final class Receipt {

    //MARK: Properties
    //private var receiptPic: UIImage //Contains picture of receipt (required?)
    private var boughtBy: String //"User" or "<name of friend>"
    //private var uploadResponse: [String:Any] //Dictionary that contains complete response from GET result to Tabscanner (required?)
    //private var receiptOCR: [String:Any] //OCR Data of receipt in form of a dictionary (required?)
    private var token: String //Token of receipt on Tabscanner
    private var lineItems: [[String:Any]] //Array for all the line items
    private var date: String //Date of receipt
    private var duplicate: Bool //Checking if receipt has been uploaded 2+ times by user
    private var category: String //Category of the receipt
    private var total: String
    
    //MARK: Initialization from camera view controller
    init(boughtBy buyer:String = "me", uploadResponse response:[String:Any], uploadToken tokenID: String, hasBeenUploaded duplicateUpload: Bool = false, ofCategory receiptCategory:String = "Miscellaneous") {
        boughtBy = buyer
        let receiptOCR = response["result"] as! [String:Any]
        token = tokenID
        total = receiptOCR["total"] as! String
        lineItems = receiptOCR["lineItems"] as! [[String:Any]]
        
        //Removing unecessary data in lineItems
        for i in 0 ..< lineItems.count {
            lineItems[i].removeValue(forKey: "descClean")
            lineItems[i].removeValue(forKey: "discount")
            lineItems[i].removeValue(forKey: "lineType")
            lineItems[i].removeValue(forKey: "productCode")
            lineItems[i].removeValue(forKey: "symbols")
            lineItems[i].removeValue(forKey: "price")
            lineItems[i].removeValue(forKey: "unit")
            lineItems[i].removeValue(forKey: "customFields")
            lineItems[i].removeValue(forKey: "supplementaryLineItems")
        }
        
        date = receiptOCR["date"] as! String
        //Checking if date is not empty
        if date.isEmpty {
            let defaultDate = Date()
            let format = DateFormatter()
            format.timeZone = .current
            format.dateFormat = "yyyy-MM-dd HH:mm:ss"
            date = format.string(from: defaultDate)
        }
        duplicate = duplicateUpload
        category = receiptCategory
    }
    
    
    //MARK: Second initialiser used FirebaseHandler
    init(boughtBy buyer:String = "me", uploadToken tokenID: String, hasBeenUploaded duplicateUpload: Bool = false, ofCategory receiptCategory:String = "Miscellaneous", onDate thisDate:String, withItems items:[[String:Any]], ofTotal totalSpent:String) {
        boughtBy = buyer
        token = tokenID
        date = thisDate
        duplicate = duplicateUpload
        category = receiptCategory
        total = totalSpent
        lineItems = items
    }
    
    //MARK: Accessor methods
    func getBuyer() -> String {
        return boughtBy
    }
    
    func getToken() -> String {
        return token
    } //Token is given by Tabscanner… can't be changed; therefore, no mutator method
    
    func getLineItems() -> [[String:Any]] {
        return lineItems
    }
    
    func getDate() -> String {
        return date
    }
    
    func getCategory() -> String {
        return category
    }
    
    func isDuplicate() -> Bool {
        return duplicate
    } //Has no mutator method because is determined only by upload to Tabscanner
    
    func getTotal() -> String {
        return total
    }
    
    //MARK: Mutator methods
    func setBuyer(as buyer:String) {
        boughtBy = buyer
    }
    
    func setLineItems(to newLine:[[String:Any]]) {
        lineItems = newLine
    }
    
    func setDate(to newDate:String) {
        date = newDate
    }
    
    func setCategory(to newCategory:String) {
        category = newCategory
    }
    
    func setTotal(to newTotal:String) {
        total = newTotal
    }
    
}
