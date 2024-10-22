//
//  LoginViewController.swift

import UIKit
import Firebase


class LoginViewController: UIViewController, UITextFieldDelegate {

    //MARK: Properties
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Handle the text field's user inputs through delegate callbacks
        emailField.delegate = self
        passwordField.delegate = self
    }

    //MARK: Actions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func loginTapped(_ sender: UIButton) {
        //Validating the user has entered something in the TextFields
        if emailField.text != "" && passwordField.text != "" {
            //Logging in existing user with email and password typed in text fields
            Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!) { (user, error) in //escaping closure which returns the user or an error depending on if they are authenticated
                if error != nil{
                    self.handleLoginError(error!)
                }
            }
        } else {
            let alert = UIAlertController(title: "Email or password were not entered", message: "Try Again", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func SignUpTapped(_ sender: UIButton) {
        //Validating the user has entered something in the TextFields
        if emailField.text != "" && passwordField.text != "" {
            //Signing up new user with email and password typed in the text fields
            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { (user, error) in
                if error != nil {
                    self.handleLoginError(error!)
                } else {
                    let user = Auth.auth().currentUser
                    let signUpRef = Database.database().reference()
                    signUpRef.child("users").child(user!.uid).child("email").setValue(self.emailField.text!)
                }
                
            }
            
        } else {
            let alert = UIAlertController(title: "Email or password were not entered", message: "Try Again", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func dismissKeyboard(_ sender: Any) {
        self.resignFirstResponder()
    }
    
    
    private func handleLoginError (_ error:Error) {
        //Creating alert
        let alert = UIAlertController(title: "Unknown Error", message: "Try Again", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        
        //Checking error codes
        switch error._code {
        case 17007, 17008, 17011: //emailAlreadyInUse, invalideEmailFormat, userNotFound
            alert.title = "Enter a different email" //Changing alert title to inform user what the problem was
            if error._code == 17007 {
                alert.message = "The email you entered is already being used"
            } else if error._code == 17008 {
                alert.message = alert.title
                alert.title = "Invalid email format"
            } else {
                alert.message = alert.title
                alert.title = "User not found"
            }
            self.present(alert, animated: true)
        case 17009: //wrongPassword
            alert.title = "Enter different password"
            alert.message = "The password you entered was incorrect"
            self.present(alert, animated: true)
        case 17005: //accountDisabled
            alert.title = "Error"
            alert.message = "Account is Disabled"
            self.present(alert, animated: true)
        case 17026: //weakPassword
            alert.title = "Enter a different password"
            alert.message = "The password you chose was too weak"
            self.present(alert, animated: true)
        default:
            alert.title = "Unknown error"
            alert.message = "\(error.localizedDescription), \(error._code)"
            self.present(alert, animated: true)
        }
    }
    
    
}
