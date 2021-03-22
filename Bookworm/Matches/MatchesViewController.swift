//
//  MatchedView.swift
//  Bookworm
//
//  Created by Mohammed Haque on 2/21/21.
//

import Foundation
import CoreLocation
import UIKit
import Firebase
import MapKit
import MessageUI

class MatchesTableViewCell: UITableViewCell {
    @IBOutlet weak var buyerSellerColorView: UIView!
    @IBOutlet weak var bookCoverImage: UIImageView!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    
    var storageRef = Storage.storage().reference()
    
    func fillInBookCell (book: BookCell){
        
        let image = UIImage(data: book.bookCoverData as Data)
        self.bookCoverImage.image = image
        
        self.bookTitleLabel.text = book.title
        self.locationLabel.text = book.location
        
        self.userNameLabel.text = "\(book.userDescription): \(book.buyerSeller)"
        self.dateLabel.text = "Posted: " + book.postDate
        
        if book.distance != "" {
            self.distanceLabel.text = "\(book.distance) away"
        }
        else {
            self.distanceLabel.text = ""
        }
        
        //display condition label if user is selling
        if book.userDescription == "Buyer"{
            self.conditionLabel.text = ""
            self.buyerSellerColorView.backgroundColor = .systemOrange
        } else{
            self.conditionLabel.text = "Condition: \(book.condition)"
            self.buyerSellerColorView.backgroundColor = .systemBlue
        }
        
    }
    
}

class MatchesViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, ReloadDelegate, MFMessageComposeViewControllerDelegate, FilterViewControllerDelegate { 
    
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var matchesTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noResultsLabels: UIStackView!
    
    var books: [BookCell] = []
    var ref = Database.database().reference()
    var storageRef = Storage.storage().reference()
    let locationManager = CLLocationManager()
    var locationUpdateTimer = Timer()
    var currLocation: CLLocation = CLLocation(latitude: 0.0, longitude: 0.0)
    // var currLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    var currentUserName = ""
    
    var wishListISBNs: [String] = []
    var inventoryISBNs: [String] = []
    
    // 0 = Inventory
    // 1 = Wishlists
    // Default: 2 = Both
    var filterValue = 2
    var distanceFilter = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //format buttons
        filterButton.layer.cornerRadius = 5
        
        self.navigationController?.isNavigationBarHidden = true
        
        matchesTableView.dataSource = self
        matchesTableView.delegate = self
        matchesTableView.reloadData()
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            self.locationManager.requestLocation()
        }
        
        locationUpdateTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(self.locationUpdate), userInfo: nil, repeats: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // For getting database data and reloadData for listingsTableView
        self.books.removeAll()
        self.wishListISBNs.removeAll()
        self.inventoryISBNs.removeAll()
        self.userWishlistInventoryCall()
        self.ref.child("Posts").removeAllObservers()
        self.makeDatabaseCallsforReload(filterOption: filterValue, distanceFilterOption: distanceFilter)
        locationUpdateTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(self.locationUpdate), userInfo: nil, repeats: true)
    }
    
    func makeDatabaseCallsforReload(filterOption: Int, distanceFilterOption: Int) {
        self.wait()
        
        self.ref.child("Posts").queryOrdered(byChild: "Date_Posted").observe(.childAdded, with: { (snapshot) in
            let results = snapshot.value as? [String : String]
            let user = results?["User"] ?? ""
            let condition = results?["Condition"] ?? ""
            let isbn = results?["ISBN"] ?? ""
            let edition = results?["Edition"] ?? ""
            let author = results?["Author"] ?? ""
            let datePublished = results?["Date_Published"] ?? ""
            let datePosted = results?["Date_Posted"] ?? ""
            let timeStamp = results?["Time_Stamp"] ?? ""
            let location = results?["Location"] ?? ""
            let title = results?["Title"] ?? ""
            let userDescription = results?["User_Description"] ?? ""
            
            // Phooto_Cover from DB returns path in FBStorage
            let bookCover = results?["Photo_Cover"] ?? ""
            
            // get book image reference from Firebase Storage
            let bookCoverRef = self.storageRef.child(bookCover)
            
            // download URL of reference, then get contents of URL and set imageView to UIImage
            bookCoverRef.downloadURL { url, error in
                guard let imageURL = url, error == nil else {
                    print(error ?? "")
                    return
                }
                
                guard let bookCoverData = NSData(contentsOf: imageURL) else {
                    assertionFailure("Error in getting Data")
                    return
                }
                
                self.ref.child("Users").child(user).observeSingleEvent(of: .value, with: { (snapshot) in
                    let userData = snapshot.value as? [String: String]
                    
                    let firstName = userData?["FirstName"] ?? ""
                    let lastName = userData?["LastName"] ?? ""
                    
                    let userName = firstName + " " + lastName
                    
                    self.getDistance(location) { (response) in
                        let distance = response
                        let databaseData = BookCell(title: title, isbn: isbn, edition: edition, publishDate: datePublished, author: author, condition: condition, location: location, distance: distance, buyerSellerID: user, buyerSeller: userName, postDate: datePosted, timeStamp: timeStamp, bookCover: bookCover, userDescription: userDescription, bookCoverData: bookCoverData)
                        
                        
                        DispatchQueue.main.async {
                            self.books.append(databaseData)
                            
                            // Remove current user entries in Matches
                            self.books = self.books.filter{$0.buyerSeller != self.currentUserName}
                            
                            // Default is both Inventory and Wishlist
                            self.books = self.books.filter { (self.wishListISBNs.contains($0.isbn) && $0.userDescription == "Seller") || (self.inventoryISBNs.contains($0.isbn) && $0.userDescription == "Buyer")
                            }
                            
                            // Inventory
                            if (filterOption == 0){
                                self.books = self.books.filter { $0.userDescription == "Buyer"
                                }
                            }
                            
                            // Wishlist
                            if (filterOption == 1) {
                                self.books = self.books.filter {  $0.userDescription == "Seller"
                                }
                            }
                            
                            self.books = self.books.filter{
                                var routeDistance = $0.distance
                                if routeDistance.contains(".") {
                                    routeDistance = routeDistance.components(separatedBy: CharacterSet.init(charactersIn: "0123456789.").inverted).joined()
                                    return Int(Double(routeDistance) ?? 0.0) <= distanceFilterOption
                                }
                                return Int(routeDistance.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0 <= distanceFilterOption
                            }
                            
                            // Sort by date and time.
                            self.books.sort(by: {$0.timeStamp > $1.timeStamp})
                            
                            self.matchesTableView.reloadData()
                            self.start()
                        }
                    }
                })
            }
            
        })
        
    }
    
    @IBAction func filterButtonPressed() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "filterVC")
        guard let filterVC = vc as? FilterViewController else {
            assertionFailure("couldn't find vc")
            return
        }
        filterVC.categorySegment0 = "Inventory"
        filterVC.categorySegment1 = "Wishlist"
        filterVC.delegate = self
        filterVC.selectedFilterValue = filterValue
        filterVC.selectedDistanceFilter = distanceFilter
        present(filterVC, animated: true, completion: nil)
    }
    
    func filterVCDismissed(selectedFilterValue: Int, selectedDistanceFilter: Int) {
        filterValue = selectedFilterValue
        distanceFilter = selectedDistanceFilter
        self.books.removeAll()
        self.wishListISBNs.removeAll()
        self.inventoryISBNs.removeAll()
        userWishlistInventoryCall()
        self.ref.child("Posts").removeAllObservers()
        makeDatabaseCallsforReload(filterOption: filterValue, distanceFilterOption: distanceFilter)
        locationUpdateTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(self.locationUpdate), userInfo: nil, repeats: true)
    }
    
    func userWishlistInventoryCall(){
        guard let userID = Auth.auth().currentUser?.uid else {
            assertionFailure("Couldn't unwrap userID")
            return
        }
        
        self.ref.child("Users/\(userID)").observeSingleEvent(of: .value, with: { (snapshot) in
            let userData = snapshot.value as? [String: String]
            
            let firstName = userData?["FirstName"] ?? ""
            let lastName = userData?["LastName"] ?? ""
            
            self.currentUserName = firstName + " " + lastName
        })
        
        self.ref.child("Wishlists/\(userID)").observe(.childAdded, with: { (snapshot) in
            let results = snapshot.value as? [String : String]
            let isbn = results?["ISBN"] ?? ""
            self.wishListISBNs.append(isbn)
        })
        
        self.ref.child("Inventories/\(userID)").observe(.childAdded, with: { (snapshot) in
            let results = snapshot.value as? [String : String]
            let isbn = results?["ISBN"] ?? ""
            self.inventoryISBNs.append(isbn)
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell =
                tableView.dequeueReusableCell(withIdentifier: "matchesCell") as? MatchesTableViewCell else {
            assertionFailure("Cell dequeue error")
            return UITableViewCell.init()
        }
        let book = books[indexPath.row]
        cell.fillInBookCell(book: book)
        //        cell.layer.cornerRadius = 10
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let book = books[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "matchesEntryVC")
        guard let matchesEntryVC = vc as? MatchesEntryViewController else {
            assertionFailure("couldn't find vc")
            return
        }
        
        matchesEntryVC.bookTitle = book.title
        matchesEntryVC.userDescription = book.userDescription
        matchesEntryVC.buyerSellerID = book.buyerSellerID
        matchesEntryVC.buyerSeller = book.buyerSeller
        matchesEntryVC.bookAuthor = book.author
        matchesEntryVC.bookEdition = book.edition
        matchesEntryVC.bookISBN = book.isbn
        matchesEntryVC.bookPublishDate = book.publishDate
        matchesEntryVC.bookCoverImage = book.bookCover
        matchesEntryVC.bookIndex = indexPath.row
        matchesEntryVC.delegate = self
        
        present(matchesEntryVC, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let book = books[indexPath.row]
        let contact = UIContextualAction(style: .normal, title: "Contact") { (action, view, completion) in
            self.contactHandler(book)
            self.matchesTableView.setEditing(false, animated: true)
        }
        contact.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [contact])
    }
    
    func contactHandler(_ book: BookCell) {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = self
        
        if(book.userDescription == "Buyer"){
            controller.body = "Hello " + book.buyerSeller + ", I saw your request for " + book.title + " on Book Worm and I have a copy! Are you interested?"
        }else{
            controller.body = "Hello " + book.buyerSeller + ", I am interested in your listing for " + book.title + " on Book Worm."
        }
        
        self.ref.child("Users/\(book.buyerSellerID)").observeSingleEvent(of: .value, with: { (snapshot) in
            let buyerSellerData = snapshot.value as? [String: String]
            let buyerSellerContact = buyerSellerData?["PhoneNumber"] ?? ""
            controller.recipients = [buyerSellerContact]
            if MFMessageComposeViewController.canSendText() {
                self.present(controller, animated: true, completion: nil)
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func getDistance(_ location: String, completion: @escaping(String) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            if error != nil {
                print("Geocoder Address String failed with error")
                completion("")
            }
            else if let placemark = placemarks?.first {
                guard let cellLocation: CLLocation = placemark.location else { return }
                let distanceInMeters = Measurement(value: cellLocation.distance(from: self.currLocation), unit: UnitLength.meters)
                let distanceInMiles = distanceInMeters.converted(to: UnitLength.miles)
                let distanceString = String(format: "%.1f", distanceInMiles.value) + " miles"
                completion(distanceString)

            //     guard let cellLocation: CLLocationCoordinate2D = placemark.location?.coordinate else { return }
            //     let request = MKDirections.Request()
            // // source and destination are the relevant MKMapItems
            //     let source = MKPlacemark(coordinate: self.currLocation)
            //     let destination = MKPlacemark(coordinate: cellLocation)
            //     request.source = MKMapItem(placemark: source)
            //     request.destination = MKMapItem(placemark: destination)

            //     // Specify the transportation type
            //     request.transportType = MKDirectionsTransportType.automobile;

            //     // If open to getting more than one route,
            //     // requestsAlternateRoutes = true; else requestsAlternateRoutes = false;
            //     request.requestsAlternateRoutes = true

            //     let directions = MKDirections(request: request)

            //     directions.calculate { (response, error) in
            //         if let response = response, let route = response.routes.first {
            //             completion(MKDistanceFormatter().string(fromDistance: route.distance))
            //         }
            //     }
            }
            else {
                // this shouldn't happen but
                assertionFailure("bad placemark, but no error")
                completion("")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocation = manager.location else { return }
        // guard let location: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.currLocation = location
        //        self.books.removeAll()
        //        self.ref.child("Posts").removeAllObservers()
        //        self.makeDatabaseCallsforReload(filterOption: self.filterValue, distanceFilterOption: self.distanceFilter, searchQuery: currentQuery)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    @objc func locationUpdate() {
        self.locationManager.requestLocation()
    }
    
    func reload(index: Int) {
        return
    }
    
    func reload(isbn: String, deleteIf sellerOrBuyer: String){
        books = books.filter({book in
            if book.isbn == isbn && book.userDescription == sellerOrBuyer {
                return false
            } else {
                return true
            }
        })
        self.matchesTableView.reloadData()
    }
    
    func wait() {
        self.matchesTableView.isHidden = false
        self.noResultsLabels.isHidden = true
        self.activityIndicator.startAnimating()
        self.view.alpha = 0.2
        self.view.isUserInteractionEnabled = false
    }
    
    func start() {
        if (self.books.count == 0) {
            self.matchesTableView.isHidden = true
            self.noResultsLabels.isHidden = false
        }
        else {
            self.matchesTableView.isHidden = false
            self.noResultsLabels.isHidden = true
        }
        self.activityIndicator.stopAnimating()
        self.view.alpha = 1
        self.view.isUserInteractionEnabled = true
    }
}
