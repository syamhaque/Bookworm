//
//  InitialNewAccountViewController.swift
//  Bookworm
//
//  Created by Peter Kim on 2/25/21.
//

import UIKit
import PhoneNumberKit
import CoreLocation


class InitialNewAccountViewController: UIViewController {
    
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: PhoneNumberTextField!
    @IBOutlet weak var zipCodeTextField: UITextField!
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    
    // Phone number implementation taken from ECS189E HW Solution
    let phoneNumberKit = PhoneNumberKit()
    var isValidNumber = false
    var isForeignNumber = false
    var phoneNumber_e164 = ""
    var zipCode = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create tap gesture object for dismissing keyboard.
        let tapGesture = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        
        // Add tap gesture to view.
        view.addGestureRecognizer(tapGesture)
        
        self.errorLabel.text = ""
        
        self.continueButton.layer.cornerRadius = 5
    }
    
    // Continiue Button Validation Checks
    @IBAction func continueButtonPressed(_ sender: Any) {
        let firstNameTF = firstNameTextField.text ?? ""
        let lastNameTF = lastNameTextField.text ?? ""
        let phoneNumberTF = phoneNumberTextField.text ?? ""
        let zipCodeNumberTF = zipCodeTextField.text ?? ""
        
        if (firstNameTF == "" || lastNameTF == "" || phoneNumberTF == "" || zipCodeNumberTF == "") {
            errorLabel.text = "Missing field(s), please try again"
            errorLabel.textColor = UIColor.systemRed
        } else if(isForeignNumber) {
            errorLabel.text = "Please enter a US phone number"
            errorLabel.textColor = UIColor.systemRed
        } else if(!isValidNumber) {
            errorLabel.text = "Please enter a valid phone number"
            errorLabel.textColor = UIColor.systemRed
        }
        
        // Checks to see if global var zipCode matches regex for zip codes
        else if(zipCode.range(of: "^[0-9]{5}(-[0-9]{4})?$", options: .regularExpression) == nil){
            errorLabel.text = "Please enter a valid zip code"
            errorLabel.textColor = UIColor.systemRed
        } else {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "createAccountViewController")
            guard let newAccountVC = vc as? NewAccountViewController else {
                assertionFailure("couldn't find vc")
                return
            }
            
            newAccountVC.userFirstName = firstNameTF
            newAccountVC.userLastName = lastNameTF
            newAccountVC.userPhoneNumber = phoneNumber_e164
            newAccountVC.userZipCode = zipCode

            self.navigationController?.pushViewController(newAccountVC, animated: true)
            
        }
        
        
    }
    
    
    // MARK: Phone Number Validation (taken from ECS189E HW Solution)
    @IBAction func phoneNumberChanged() {
        self.errorLabel.text = ""
        let phoneNumber = phoneNumberTextField.text ?? ""
        
        do {
            let ph = try phoneNumberKit.parse(phoneNumber)
            self.isValidNumber = true
            let regId = ph.regionID ?? ""
            print(regId)
            if(regId == "US") {
                self.isForeignNumber = false
                self.phoneNumber_e164 = phoneNumberKit.format(ph, toType: .e164)
                
            } else {
                self.isForeignNumber = true
            }
        } catch {
            self.isValidNumber = false
            self.isForeignNumber = false
        }
    }
    
    
    // MARK: Zip Code Validation
    @IBAction func zipCodeChanged() {
        self.errorLabel.text = ""
        zipCode = zipCodeTextField.text ?? ""
        
        getCityFromPostalCode(postalCode: zipCode)
    }
    
    
    // MARK: Changes zip code number to city, country if a valid zip code
    func getCityFromPostalCode(postalCode : String){
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(postalCode) { results, error in 
            
            // Placemark gives an array of best/closest results. First value of array most accurate.
            if let placemark = results?[0] {
                
                if placemark.postalCode == postalCode{
                    let locality = placemark.locality ?? ""
                    let state = placemark.administrativeArea ?? ""
                    
                    self.zipCodeTextField.text = "\(locality), \(state)"
                    
                }
                else{
                    print("Please enter valid zipcode")
                }
            }
        }
    }
    
    
    
    
}
