//
//  AddListingViewController.swift
//  Bookworm
//
//  Created by Mohammed Haque on 3/1/21.
//

import Foundation
import CoreLocation
import UIKit
import Firebase

protocol AddPostListingViewControllerDelegate {
    func addPostListingVCDismissed()
}

class AddPostListingViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var publishDateLabel: UILabel!
    @IBOutlet weak var isbnLabel: UILabel!
    @IBOutlet weak var bookConditionPickerView: UIPickerView!
    @IBOutlet weak var addListingButton: UIButton!
    
    var storageRef = Storage.storage().reference()
    var ref = Database.database().reference()
    
    var delegate: AddPostListingViewControllerDelegate?
    var isbn = "<ISBN_NUMBER>"
    var bookTitle: String = ""
    var bookAuthors:  [String] = []
    var bookAuthor: String = ""
    var bookPublishDate: String = ""
    var bookISBN: String = ""
    var bookCondition: String = ""
    var bookLocation: String = ""
    var bookCoverImageS: Data? = nil
    var bookCoverImageM: Data? = nil
    var bookCoverImageL: Data? = nil
    
    var authorString: String = ""
    
    var bookConditionPickerData: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // format buttons + view
        popupView.layer.cornerRadius = 10
        addListingButton.layer.cornerRadius = 5
        
        // connect data
        self.bookConditionPickerView.delegate = self
        self.bookConditionPickerView.dataSource = self
        
        // put book conditions into array
        bookConditionPickerData = ["Poor", "Fair", "Good", "Great", "New"]
        
        // if user doesn't touch UIPicker, default saved valuee is Poor
        self.bookCondition = bookConditionPickerData[0] as String
        
        titleLabel.text = bookTitle
        if let coverImageDataM = bookCoverImageM, let coverImageM = UIImage(data: coverImageDataM) {
            coverImageView.image = coverImageM
        }
        else {
            coverImageView.image = UIImage(systemName: "book")
        }
        
        if bookAuthor.isEmpty && bookAuthors.isEmpty {
            authorLabel.text = "Author: "
            authorString = " "
        }
        else if bookAuthor.isEmpty && !bookAuthors.isEmpty {
            authorLabel.text = "Authors: " + bookAuthors.joined(separator: ", ")
            authorString = bookAuthors.joined(separator: ", ")
        }
        else {
            authorLabel.text = "Author: " + bookAuthor
            authorString = bookAuthor
        }
        
        publishDateLabel.text = "Publish Date: " + bookPublishDate
        isbnLabel.text = "ISBN: " + bookISBN
        
        OpenLibraryAPI.ISBN(bookISBN, completion: { response, error in
            if let unwrappedError = error {
                print("search error")
                print(unwrappedError)
                return
            }
            guard let unwrappedResponse = response else {
                print("no response")
                return
            }
            
            if let publishDate = unwrappedResponse["publish_date"] as? String {
                self.publishDateLabel.text = "Publish Date: " + publishDate
                self.bookPublishDate = publishDate
            } else {
                self.publishDateLabel.text = "Publish Date: None found"
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            DispatchQueue.global(qos: .userInitiated).async { self.delegate?.addPostListingVCDismissed() }
        }
    }
    
    @IBAction func didPressAddListing(_ sender: Any) {
        
        let currentDateTime = Date()
        let timestamp = String(currentDateTime.timeIntervalSince1970)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        let date = formatter.string(from: currentDateTime)
        let uniquePostID = UUID().uuidString
        
        
        // save image to Firebase storage with uniqueBookID.jpg as image path
        let imageRef = storageRef.child("\(uniquePostID).jpg")
        
        // Conditional check, use default book image if no image found for book cover
        if let bookCoverData = bookCoverImageM {
            imageRef.putData(bookCoverData, metadata: nil) { (metadata, error) in
                if let error = error {
                    print(error)
                }
                if let metadata = metadata {
                    print(metadata)
                }
            }
        } else if let bookCoverData = bookCoverImageS {
            imageRef.putData(bookCoverData, metadata: nil) { (metadata, error) in
                if let error = error {
                    print(error)
                }
                if let metadata = metadata {
                    print(metadata)
                }
            }
        } else { //default book image
            if let bookImage = UIImage(systemName: "book"), let bookImageData = bookImage.jpegData(compressionQuality: 1.0) {
                imageRef.putData(bookImageData, metadata: nil) { (metadata, error) in
                    if let error = error {
                        print("error w default image")
                        print(error)
                    }
                    if let metadata = metadata {
                        print("error w default image")
                        print(metadata)
                    }
                }
            }
        }

        
        // Grab user ID from logged in user
        guard let userID = Auth.auth().currentUser?.uid else {
            assertionFailure("Couldn't unwrap userID")
            return
        }
        
        //add book isbn to user's inventory
        ref.self.ref.child("Inventories").child(userID).child(uniquePostID).setValue(["ISBN": self.bookISBN])
        
        
        // Grab zipcode from user
        self.ref.child("Users").child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
            let userData = snapshot.value as? [String: String]
            let bookZipCode = userData?["ZipCode"] ?? ""
            let userFirstName = userData?["FirstName"] ?? ""
            let userLastName = userData?["LastName"] ?? ""
            let userFullName = userFirstName + " " + userLastName

            //change zip code to city and push new post onto database "Posts"
            self.getCityFromPostalCode(postalCode: bookZipCode, userID: userID, uniquePostID: uniquePostID, date: date, timestamp: timestamp)
        
            
            // add user as a "seller" of this book under database's "Books"
            self.ref.child("Books").child(self.bookISBN).observeSingleEvent(of: .value, with: { (snapshot) in
                //Fill in "BookInformation" node (currently does this every time a user is added as buyer/seller)
                self.ref.child("Books").child(self.bookISBN).child("Book_Information").setValue(["Title": self.bookTitle, "Author": self.authorString, "Date_Published": self.bookPublishDate, "Edition": "", "Photo_Cover": "\(uniquePostID).jpg"])
                
                // Append user info to "Sellers" node
                self.ref.child("Books").child(self.bookISBN).child("Sellers").child(userID).child("User_Information").setValue(["User_Name": userFullName, "User_Location": bookZipCode])
                    
                // Append post info to "Sellers" node
                self.ref.child("Books").child(self.bookISBN).child("Sellers").child(userID).child("Posts").child(uniquePostID).setValue(["Post_Timestamp": date, "Condition": self.bookCondition])
                
            }) { (error) in
                print("Error adding post to \"Books\" node")
                print(error.localizedDescription)
            }
            
            
        })
        
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return bookConditionPickerData.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return bookConditionPickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent  component: Int) {
        bookCondition = bookConditionPickerData[row] as String
    }
    
    func createNewListing(userID: String, uniquePostID: String, date: String, timestamp: String){
        // make push call to database
        self.ref.child("Posts").child(uniquePostID).setValue(["Title": self.bookTitle, "Author": self.authorString, "Date_Published": self.bookPublishDate, "Edition": "", "ISBN": self.bookISBN, "Condition": self.bookCondition, "User": userID, "Date_Posted": date, "Location": self.bookLocation, "User_Description": "Seller", "Photo_Cover": "\(uniquePostID).jpg", "Time_Stamp": timestamp])
    }
    
    //    func getCityFromPostalCode(postalCode: String){
    func getCityFromPostalCode(postalCode: String, userID: String, uniquePostID: String, date: String, timestamp: String) {
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(postalCode) { results, error in
            
            // Placemark gives an array of best/closest results. First value of array most accurate.
            if let placemark = results?[0] {
                let locality = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                print(locality)
                print(state)
                
                
                self.bookLocation = "\(locality), \(state)"
                print()
                self.createNewListing(userID: userID, uniquePostID: uniquePostID, date: date, timestamp: timestamp)
                
            }
            if let error = error {
                print(error)
                self.bookLocation = "Did not Work"
            }
        }
    }
    
    
    @IBAction func didPressX(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
