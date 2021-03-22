//
//  ViewController.swift
//  Bookworm
//
//  Created by Joel Boersma on 2/18/21.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var newAccountButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Create tap gesture object for dismissing keyboard.
        let tapGesture = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        
        // Add tap gesture to view.
        view.addGestureRecognizer(tapGesture)
        
        self.errorLabel.text = ""
        
        loginButton.layer.cornerRadius = 5
        newAccountButton.layer.cornerRadius = 5
        
        // For dot inputs for password
        self.passwordTextField.isSecureTextEntry = true
        
        // Change email textField to email keyboard
        self.emailTextField.keyboardType = UIKeyboardType.emailAddress
        
        self.navigationController?.isNavigationBarHidden = false
    }
    
    @IBAction func loginButtonPressed() {
        
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        // Check for errors, else try authentication
        if (email == "" || password == ""){
            errorLabel.text = "Missing field(s), please try again"
            errorLabel.textColor = UIColor.systemRed
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
                if let error = error {
                    print(error)
                    
                    // API error checking, can add more as neeeded
                    if let errCodeMessage = AuthErrorCode(rawValue: error._code) {
                        switch errCodeMessage {
                        case .userNotFound:
                            self.errorLabel.text = "Invalid user, please try again"
                            self.errorLabel.textColor = UIColor.systemRed
                        case .wrongPassword:
                            self.errorLabel.text = "Invalid password, please try again"
                            self.errorLabel.textColor = UIColor.systemRed
                        case .networkError:
                            self.errorLabel.text = "Network Error, please try again"
                            self.errorLabel.textColor = UIColor.systemRed
                        default:
                            print("Unknown error occurred")
                            self.errorLabel.text = "Unknown error has occurred, please try again later"
                            self.errorLabel.textColor = UIColor.systemRed
                        }
                    }
                    
                } else {
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    guard let vc = storyboard.instantiateViewController(withIdentifier: "tabBarController") as? UITabBarController  else { assertionFailure("Couldn't find tab bar controller."); return }
                    let tabBarController = [vc]
                    self.navigationController?.setViewControllers(tabBarController, animated: true)
                }
            }
        }
    }
    
    
    // If pressed, push initialNewAccount VC. This is where preliminary info like name, phone number, zip code is taken and will be pushed to database.
    @IBAction func newAccountButtonPressed(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "initialNewAccountView")
        guard let initialNewAccountVC = vc as? InitialNewAccountViewController else {
            assertionFailure("couldn't find vc")
            return
        }
        self.navigationController?.pushViewController(initialNewAccountVC, animated: true)
    }
}



