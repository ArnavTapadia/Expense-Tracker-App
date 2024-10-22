//
//  FirebaseHandler.swift

import Foundation
import Firebase

class FirebaseHandler {
    
    private static let databaseRef = Database.database().reference()
    private static let user = Auth.auth().currentUser!
    
    private static var userDates:[String] = [] //Holds downloaded years from firebase user profile
    
    private static var userExpenditure = ["Total":"", "Groceries":"", "Lifestyle":"", "Personal":"", "Transport": "", "Miscellaneous":""] //Dictionary of different expenditures for each month
    
    private static var receiptsForMonth = [Receipt]()
    
    static func downloadUserDates(getDates complete: @escaping([String]) -> Void) {

        databaseRef.child("users").child(user.uid).child("months").observe(.value) { (snapshot) in
            userDates.removeAll()
            //For ordering cast as NSDictionary
            if let datesForUser = snapshot.value as? NSDictionary {
                for date in datesForUser.allKeys {
                    userDates.append(date as! String)
                }
            }
            //datesForUser is a [String:[String:String]] where first string is the date and the dictionary of strings is the expenditure totals
            
            complete(userDates)
        }
        
    }
    
    static func getExpenditure(for date: String, complete: @escaping([String:String]) -> Void) {
        //Call calculate expenditure function which is escaping
        databaseRef.child("users").child(user.uid).child("months").child(date).removeAllObservers()
        databaseRef.child("users").child(user.uid).child("months").child(date).observe(.value) { (snapshot) in
            if let expenditureDict = snapshot.value as? [String:String] {
                complete(expenditureDict)
            }
            
        }
        //Called from ExpenditureViewController
    }
    
    static func downloadReceipts(for date: String, when complete: @escaping([[String:Any]]) -> Void) {
        //Called from ManageViewController when category == "All"
        var receiptsBriefArray:[[String:Any]] = []
        //Creating array to hold all receipts
        let categories = ["Groceries", "Lifestyle", "Personal & Discretionary", "Transportation", "Miscellaneous"]
        let allCategoriesRef = databaseRef.child("month").child(date).child(user.uid)
        
        //Querying database to get receipts
        allCategoriesRef.observeSingleEvent(of: .value) { (snapshot) in
            for category in categories {
                if let receiptHeldDict = snapshot.childSnapshot(forPath: "\(category)/receipts").value as? [String:Any] {
                    //Copying receipts from each category into array
                    for (token, briefData) in receiptHeldDict {
                        receiptsBriefArray.append([token:briefData])
                    }
                }
            }
            
            complete(receiptsBriefArray)
            
        }
    }
    
    static func downloadReceipts(for date: String, in category: String, when complete: @escaping([[String:Any]]) -> Void) {
        //Called from ManageViewController when category != "All"
        var receiptsBriefArray:[[String:Any]] = []
        let categoryRef = databaseRef.child("month").child(date).child(user.uid).child(category)
        
        categoryRef.observeSingleEvent(of: .value) { (snapshot) in
            if let receiptHeldDict = snapshot.childSnapshot(forPath: "receipts").value as? [String:Any] {
                for (token, briefData) in receiptHeldDict {
                    receiptsBriefArray.append([token:briefData])
                }
            }
            complete(receiptsBriefArray)
        }
        
    }
    
    static func uploadReceipt(thisreceipt receipt:Receipt) {
        //Called from confirmReceiptsViewController
        //Changes database
        databaseRef.child("month").child(String(receipt.getDate().prefix(7))).child(user.uid).child(receipt.getCategory()).child("receipts").child(receipt.getToken()).setValue(["total":receipt.getTotal(), "date":receipt.getDate(), "buyer":receipt.getBuyer(), "category":receipt.getCategory()]) { (err1, ref1) in
            //Call databaseChanged
            databaseChanged(at: "month/\(String(receipt.getDate().prefix(7)))/\(user.uid)", in: String(receipt.getDate().prefix(7)))
        }
        //if duplicate receipt uploaded data in .child("month") does not change if the month is different then original or if category is different to original
        //Check if month or category is different
        //month or month & category different: go to og month and deleteReceipt(receipt) in og category
        //if category different go to .child("month").child(String(receipt.getDate().prefix(7))) and og category and delete
        //update duplicate receipt in .child("receipts")
        //Adding receipt to month
        
        //Need check for if receipt is duplicate
        //If duplicate then the data in .child("receipts") changes automatically
        
        
        databaseRef.child("receipts").child(receipt.getToken()).setValue(["date":receipt.getDate(), "total":receipt.getTotal(), "category":receipt.getCategory(), "buyer":receipt.getBuyer(), "duplicate":receipt.isDuplicate()]) { (error, ref) in
            let lineItemsRef = databaseRef.child("receipts").child(receipt.getToken()).child("lineItems")
            lineItemsRef.setValue(receipt.getLineItems(), withCompletionBlock: { (err2, ref2) in
                //Handle error
            })
        }
        //Add to array of receipts
        //Upload to firebase with token as ID (check if duplicate & ask if need update)
        //Add receipt token + buyer + total + date to correct month/year with correct user and correct category
        //Add month/year to user profile
        

    }
    
    static func deleteReceipt(_ receipt:[String:Any]) {
        //Called from ManageViewController
        //delete receipt in database (opposite of upload function
        let receiptToDeleteData = receipt[Array(receipt.keys)[0]] as! [String:String]
        let tokenToDelete = Array(receipt.keys)[0]
        //1. Deleting receipt from database child receipts
        databaseRef.child("receipts").child(tokenToDelete).removeValue()
        
        //2. Deleting receipt from database child month
        databaseRef.child("month").child(String(receiptToDeleteData["date"]!.prefix(7))).child(user.uid).child(receiptToDeleteData["category"]!).child("receipts").child(tokenToDelete).removeValue { (err, ref) in
            
            //3. Checking if there are no receipts in that month for that user (user.uid doesn't exist in that month)
            //updating database child users months
            databaseRef.child("month").child(String(receiptToDeleteData["date"]!.prefix(7))).observeSingleEvent(of: .value, with: { (snapshotFindingUID) in
                
                if !snapshotFindingUID.hasChild(user.uid) {
                    //edit user profile for months
                    databaseRef.child("users").child(user.uid).child("months").child(String(receiptToDeleteData["date"]!.prefix(7))).removeValue()
                } else {
                    databaseChanged(at: "month/\(String(receiptToDeleteData["date"]!.prefix(7)))/\(user.uid)", in: String(receiptToDeleteData["date"]!.prefix(7)))
                }
                
            })
        }
        
        
    }
    
    //Function recalculates all totals for the changes made to that month for that user
    private static func databaseChanged(at path:String, in month:String) {
        //Recalculate total for that category in that month for that user (in user profile)
        //Update total for user for specific month by adding categories again
        var recalculatedTotals:[String:Double] = ["total":0, "Groceries":0, "Lifestyle":0, "Personal & Discretionary":0, "Transportation":0, "Miscellaneous":0]
        
        databaseRef.child(path).observeSingleEvent(of: .value) { (snapshot) in
            
            if let categoryDictionary = snapshot.value as? [String:Any] {
                
                for category in categoryDictionary.keys {
                    //Calculating category total
                    
                    if let receiptDataDictionary = snapshot.childSnapshot(forPath: "\(category)/receipts").value as? [String:Any] {
                        for (token, data) in receiptDataDictionary {
                            if let receiptInfo = data as? [String:String] {
                                recalculatedTotals[category] = recalculatedTotals[category]! + Double(receiptInfo["total"]!)!
                            }
                            
                        }
                        
                    }
                    
                }
                
                
            }
            
            recalculatedTotals["total"] = recalculatedTotals["Groceries"]! + recalculatedTotals["Lifestyle"]! + recalculatedTotals["Personal & Discretionary"]! + recalculatedTotals["Transportation"]! + recalculatedTotals["Miscellaneous"]!
            
            // Converting into a [String:String]
            let recalculatedTotalsStringDict = ["total": "\(String(describing: recalculatedTotals["total"]!))", "groceryTotal": "\(String(describing: recalculatedTotals["Groceries"]!))", "lifestyleTotal": "\(String(describing: recalculatedTotals["Lifestyle"]!))", "personalTotal":"\(String(describing: recalculatedTotals["Personal & Discretionary"]!))", "transportTotal":"\(String(describing: recalculatedTotals["Transportation"]!))", "miscellaneousTotal":"\(String(describing: recalculatedTotals["Miscellaneous"]!))"]
            databaseRef.child("users").child(user.uid).child("months").child(month).setValue(recalculatedTotalsStringDict)
        }
        
        
    }
    
    static func getFullReceiptData(fromReceipt receiptBriefData:[String:Any], when complete: @escaping(Receipt) -> Void) {
        //Called from ManageViewController when passing data to ConfirmReceiptViewController
        //Creates a Receipt object after downloading data from Firebase
        let token = Array(receiptBriefData.keys)[0]
        
        databaseRef.child("receipts").child(token).observeSingleEvent(of: .value) { (snapshot) in
            
            
            if let receiptData = snapshot.value as? [String:Any] {
                
                
                let buyer = receiptData["buyer"] as! String
                let category = receiptData["category"] as! String
                let date = receiptData["date"] as! String
                let total = receiptData["total"] as! String
                
                let lineItems = receiptData["lineItems"] as! NSArray as! [[String:Any]]
                
                let receipt:Receipt = Receipt(boughtBy: buyer, uploadToken: token, hasBeenUploaded: true, ofCategory: category, onDate: date, withItems: lineItems, ofTotal: total)
                
                complete(receipt)
                
            }
            
        }
        
    }
    
}
