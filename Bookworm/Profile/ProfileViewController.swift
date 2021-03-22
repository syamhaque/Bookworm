//
//  ProfileViewController.swift
//  Bookworm
//
//  Created by Christina Luong on 2/22/21.
//

import UIKit
import Firebase
import CoreLocation

class ProfileViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var greetingLabel: UITextField!
    @IBOutlet weak var locationLabel: UILabel!
    
    //get references to all buttons (for formatting)
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var inventoryButton: UIButton!
    @IBOutlet weak var wishListButton: UIButton!
    @IBOutlet weak var changeLocationButton: UIButton!
    @IBOutlet weak var deleteAccountButton: UIButton!
    
    var ref = Database.database().reference()
    var dbLocation = ""
    var dbLocationZip = ""
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
        
        //format buttons
        logoutButton.layer.cornerRadius = 5
        inventoryButton.layer.cornerRadius = 5
        wishListButton.layer.cornerRadius = 5
        changeLocationButton.layer.cornerRadius = 5
        deleteAccountButton.layer.cornerRadius = 5
        
        // set greeting label to first name
        let user = Auth.auth().currentUser
        self.ref.child("Users").child(user?.uid ?? "").observeSingleEvent(of: .value, with: { (snapshot) in
            let userData = snapshot.value as? [String: String]
            
            if let firstName = userData?["FirstName"] {
                self.greetingLabel.text = "Hello, \(firstName)"
            }
            else {
                self.greetingLabel.text = "Hello!"
            }
            
            if let postalCode = userData?["ZipCode"] {
                self.dbLocationZip = postalCode
                self.changeLocationLabel(postalCode: postalCode)
            }
            else {
                self.locationLabel.text = ""
            }
        })
//        ref.child("Users").child(user?.uid ?? "").child("FirstName").observeSingleEvent(of: .value, with: { (snapshot) in
//
//            if let firstName = snapshot.value as? String{
//                self.greetingLabel.text = "Hello, \(firstName)"
//            }
//        })
    }
    
    func returnToLoginView(){
        do
        {
            try Auth.auth().signOut()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let vc = storyboard.instantiateViewController(withIdentifier: "loginViewController") as? LoginViewController  else { assertionFailure("Couldn't find login view controller."); return }
            let loginViewController = [vc]
            self.navigationController?.setViewControllers(loginViewController, animated: true)
        }
        catch let error as NSError
        {
            print(error.localizedDescription)
        }
        
    }
    
    @IBAction func didPressLogout(_ sender: Any) {
        //re-set navication controller to login view
        returnToLoginView()
    }
    
    @IBAction func didPressInventory(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "inventoryViewController") as? InventoryViewController  else { assertionFailure("Couldn't find inventory view controller."); return }
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func didPressWishList(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "wishListViewController") as? WishListViewController  else { assertionFailure("Couldn't find wish list view controller."); return }
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func didPressChangeLocation(_ sender: Any) {
        let alert = UIAlertController(title: "How do you wish to change your location?", message: nil, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Current Location", style: .default, handler: { (action) in
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.delegate = self
                self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.locationManager.startUpdatingLocation()
            }
        }))
        alert.addAction(UIAlertAction(title: "Enter ZipCode", style: .default, handler: { (action) in
            let locationAlert = UIAlertController(title: "Enter the desired zipcode", message: nil, preferredStyle: .alert)
            locationAlert.addTextField { (textfield) in
                textfield.placeholder = "\(self.dbLocationZip)"
            }
            locationAlert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
                let textfield = locationAlert.textFields?[0]
                self.changeLocationLabel(postalCode:textfield?.text ?? "\(self.dbLocationZip)")
            }))
            locationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(locationAlert, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(manager.location ?? CLLocation.init()) { (placemarks, error) in
            if error != nil {
                print("Reverse geocoder failed with error")
                return
            }

            if placemarks?.count ?? 0 > 0 {
                let pm = placemarks?[0]
                self.changeLocationLabel(postalCode: pm?.postalCode ?? self.dbLocation)
                
            }
            else {
                print("Problem with the data received from geocoder")
            }
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    func changeLocationLabel(postalCode: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(postalCode) { results, error in
            
            // Placemark gives an array of best/closest results. First value of array most accurate.
            if let placemark = results?[0] {
                let locality = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                
                self.dbLocation = "\(locality), \(state)"
                self.locationLabel.text = "\(self.dbLocation)"
                
                // Grab user ID from logged in user
                guard let userID = Auth.auth().currentUser?.uid else {
                    assertionFailure("Couldn't unwrap userID")
                    return
                }

                //update user's ZipCode under users -> userID -> zipcode
                self.ref.child("Users").child(userID).updateChildValues(["ZipCode": postalCode])
            }
            if let error = error {
                print(error)
            }
        }
    }
    
    @IBAction func didPressDeleteAccount(_ sender: Any) {
        let user = Auth.auth().currentUser
        let userDatabaseRef = ref.child("Users").child(user?.uid ?? "")
        
        //user must confirm deletion before account is actually deleted
        let confirmDeleteAlert = UIAlertController(title: "Delete", message: "Are you sure you want to delete this account?", preferredStyle: .alert)
        
        //if user confirms deletion, account is deleted and screen returns to login view
        confirmDeleteAlert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {action in
            user?.delete {error in
                if let err = error{ print(err)}
            }
            
            // delete user from database
            userDatabaseRef.removeValue() { error, _ in
                if let err = error{ print(err)}
            }
            
            self.returnToLoginView()
        }))
        
        //if user does not confirm deletion, screen returns to profile view
        confirmDeleteAlert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
        
        self.present(confirmDeleteAlert,animated: true)
    }
}
