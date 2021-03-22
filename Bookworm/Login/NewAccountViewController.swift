//
//  NewAccountViewController.swift
//  Bookworm
//
//  Created by Peter Kim on 2/21/21.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase


class NewAccountViewController: UIViewController {
    
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    var ref = Database.database().reference()
    
    // Values passed from InitialNewAccountViewController
    var userFirstName: String = ""
    var userLastName: String = ""
    var userPhoneNumber: String = ""
    var userZipCode: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create tap gesture object for dismissing keyboard.
        let tapGesture = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        
        // Add tap gesture to view.
        view.addGestureRecognizer(tapGesture)
        
        self.errorLabel.text = ""
        
        self.signUpButton.layer.cornerRadius = 5
        
        // For dot inputs for passwords
        self.passwordTextField.isSecureTextEntry = true
        self.confirmPasswordTextField.isSecureTextEntry = true
        
        // Change keyboard type for respective text fields
        self.emailTextField.keyboardType = UIKeyboardType.emailAddress
        
    }
    
    
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""
        
        // If any text field is empty
        if (email == "" || password == "" || confirmPassword == "") {
            errorLabel.text = "Missing field(s), please try again"
            errorLabel.textColor = UIColor.systemRed
        } else if (confirmPassword != password) {
            errorLabel.text = "Password does not match"
            errorLabel.textColor = UIColor.systemRed
        } else {
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                
                if let authResult = authResult {
                    
                    print(authResult)
                    self.errorLabel.text = "Account created successfully"
                    self.errorLabel.textColor = UIColor.systemGreen
                    
                    // Handle data pushing here
                    self.ref.child("Users").child(authResult.user.uid).setValue(["FirstName": self.userFirstName, "LastName": self.userLastName, "PhoneNumber": self.userPhoneNumber, "ZipCode": self.userZipCode])

                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    guard let vc = storyboard.instantiateViewController(withIdentifier: "tabBarController") as? UITabBarController  else { assertionFailure("Couldn't find tab bar controller."); return }
                    let tabBarController = [vc]
                    self.navigationController?.setViewControllers(tabBarController, animated: true)
                    
                    
                    
                } else if let error = error {
                    print(error)
                    
                    if let errCodeMessage = AuthErrorCode(rawValue: error._code) {
                        self.errorLabel.textColor = UIColor.systemRed
                        
                        switch errCodeMessage {
                        case .invalidEmail:
                            self.errorLabel.text = "Please enter a valid email"
                        case .weakPassword:
                            self.errorLabel.text = "Weak Password; Password must be over 6 characters"
                        case .networkError:
                            self.errorLabel.text = "Network Error, please try again"
                        default:
                            print("Unknown error occurred")
                            self.errorLabel.text = "Unknown error has occurred, please try again later"
                        }
                    }
                }
            }
        }
    }
    
    
    
    
}

