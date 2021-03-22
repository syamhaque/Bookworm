//
//  HomeViewController.swift
//  Bookworm
//
//  Created by Christina Luong on 3/1/21.
//

import UIKit
import Firebase
import MessageUI
import CoreLocation
import MapKit

class ListingsTableViewCell: UITableViewCell {
    @IBOutlet weak var bookCoverImage: UIImageView!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var buyerSellerLabel: UILabel!
    @IBOutlet weak var postDateLabel: UILabel!
    @IBOutlet weak var buyerSellerColorView: UIView!
    
    var storageRef = Storage.storage().reference()
    
    func fillInBookCell (book: BookCell){
        
        let image = UIImage(data: book.bookCoverData as Data)
        self.bookCoverImage.image = image
        
        self.bookTitleLabel.text = book.title
        self.locationLabel.text = book.location
        
        if book.distance != "" {
            self.distanceLabel.text = "\(book.distance) away"
        }
        else {
            self.distanceLabel.text = ""
        }
        
        self.buyerSellerLabel.text = "\(book.userDescription): \(book.buyerSeller)"
        self.postDateLabel.text = "Posted: " + book.postDate
        
        //display condition label if user is selling
        if book.userDescription == "Buyer"{
            self.conditionLabel.text = ""
            self.buyerSellerColorView.backgroundColor = .systemOrange
        } else {
            self.conditionLabel.text = "Condition: \(book.condition)"
            self.buyerSellerColorView.backgroundColor = .systemBlue
        }
        
    }
    
}

class HomeViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, FilterViewControllerDelegate, MFMessageComposeViewControllerDelegate, ReloadDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var listingsTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noResultsLabels: UIStackView!
    
    var books: [BookCell] = []
    var currentQuery = ""
    let locationManager = CLLocationManager()
    var locationUpdateTimer = Timer()
    var currLocation: CLLocation = CLLocation(latitude: 0.0, longitude: 0.0)
    // var currLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    var ref = Database.database().reference()
    var storageRef = Storage.storage().reference()
    
    // 0 = Listing
    // 1 = Requests
    // Default: 2 = Both
    var filterValue = 2
    var distanceFilter = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
        
        searchBar.delegate = self
        listingsTableView.dataSource = self
        listingsTableView.delegate = self
        
        
        self.activityIndicator.stopAnimating()
        filterButton.layer.cornerRadius = 5
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground.
        self.locationManager.requestWhenInUseAuthorization()
        
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
        self.searchBar.text = ""
        currentQuery = ""
        self.ref.child("Posts").removeAllObservers()
        self.makeDatabaseCallsforReload(filterOption: filterValue, distanceFilterOption: distanceFilter, searchQuery: currentQuery)
        locationUpdateTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(self.locationUpdate), userInfo: nil, repeats: true)
    }
    
    
    func makeDatabaseCallsforReload(filterOption: Int, distanceFilterOption: Int, searchQuery: String) {
        
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
                            
                            // For listings
                            if (filterOption == 0){
                                self.books = self.books.filter { $0.userDescription != "Buyer" }
                            }
                            
                            // For requests
                            if (filterOption == 1) {
                                self.books = self.books.filter { $0.userDescription != "Seller" }
                            }
                            
                            if (!searchQuery.isEmpty){
                                self.books = self.books.filter { $0.title.lowercased() == searchQuery }
                            }
                            
                            self.books = self.books.filter{
                                var routeDistance = $0.distance
                                if routeDistance.contains(".") {
                                    routeDistance = routeDistance.components(separatedBy: CharacterSet.init(charactersIn: "0123456789.").inverted).joined()
                                    return Int(Double(routeDistance) ?? 0.0) <= distanceFilterOption
                                }
                                return Int(routeDistance.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0 <= distanceFilterOption
                            }
                            // Default is both
                            // Sort by date and time.
                            self.books.sort(by: {$0.timeStamp > $1.timeStamp})
                            self.listingsTableView.reloadData()
                            self.start()
                        }
                    }
                })
            }
            
        })
        
    }
    
    func reload(index: Int) {
        books.remove(at: index)
        self.listingsTableView.reloadData()
    }
    func reload(isbn: String, deleteIf sellerOrBuyer: String){
        return
    }
    
    @IBAction func filterButtonClicked(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "filterVC")
        guard let filterVC = vc as? FilterViewController else {
            assertionFailure("couldn't find vc")
            return
        }
        filterVC.selectedDistanceFilter = distanceFilter
        filterVC.selectedFilterValue = filterValue
        filterVC.delegate = self
        
        present(filterVC, animated: true, completion: nil)
    }
    
    func filterVCDismissed(selectedFilterValue: Int, selectedDistanceFilter: Int) {
        filterValue = selectedFilterValue
        distanceFilter = selectedDistanceFilter
        self.books.removeAll()
        self.ref.child("Posts").removeAllObservers()
        makeDatabaseCallsforReload(filterOption: filterValue, distanceFilterOption: distanceFilter, searchQuery: currentQuery)
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.tapGestureRecognizer.isEnabled = true
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        self.tapGestureRecognizer.isEnabled = false
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        currentQuery = searchBar.text ?? ""
        currentQuery = currentQuery.lowercased()
        self.books.removeAll()
        self.ref.child("Posts").removeAllObservers()
        listingsTableView.reloadData()
        makeDatabaseCallsforReload(filterOption: filterValue, distanceFilterOption: distanceFilter, searchQuery: currentQuery)
        
        view.endEditing(true)
    }
    
    // table view scrolling
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Hide keyboard
        view.endEditing(true)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell =
                tableView.dequeueReusableCell(withIdentifier: "listingsCell") as? ListingsTableViewCell else {
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
        let vc = storyboard.instantiateViewController(identifier: "dblistingVC")
        guard let dblistingVC = vc as? DatabaseListingViewController else {
            assertionFailure("couldn't find vc")
            return
        }
        
        dblistingVC.bookTitle = book.title
        dblistingVC.userDescription = book.userDescription
        dblistingVC.buyerSellerID = book.buyerSellerID
        dblistingVC.buyerSeller = book.buyerSeller
        dblistingVC.bookAuthor = book.author
        dblistingVC.bookEdition = book.edition
        dblistingVC.bookISBN = book.isbn
        dblistingVC.bookPublishDate = book.publishDate
        dblistingVC.bookCoverImage = book.bookCover
        dblistingVC.bookIndex = indexPath.row
        dblistingVC.delegate = self
        
        present(dblistingVC, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let book = books[indexPath.row]
        guard let userID = Auth.auth().currentUser?.uid else {
            assertionFailure("Couldn't unwrap userID")
            return UISwipeActionsConfiguration(actions: [])
        }
        if userID != book.buyerSellerID {
            let contact = UIContextualAction(style: .normal, title: "Contact") { (action, view, completion) in
                self.contactHandler(book)
                self.listingsTableView.setEditing(false, animated: true)
            }
            contact.backgroundColor = .systemGreen
            return UISwipeActionsConfiguration(actions: [contact])
        }
        return UISwipeActionsConfiguration(actions: [])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let book = books[indexPath.row]
        guard let userID = Auth.auth().currentUser?.uid else {
            assertionFailure("Couldn't unwrap userID")
            return UISwipeActionsConfiguration(actions: [])
        }
        if userID == book.buyerSellerID {
            let delete = UIContextualAction(style: .normal, title: "Delete") { (action, view, completion) in
                if book.userDescription == "Buyer" {
                    self.deleteHandler(book, userID, indexPath.row, from: "Wishlists", userStatus: "Buyers")
                }
                else if book.userDescription == "Seller" {
                    self.deleteHandler(book, userID, indexPath.row, from: "Inventories", userStatus: "Sellers")
                }
                self.listingsTableView.setEditing(false, animated: true)
            }
            delete.backgroundColor = .systemRed
            return UISwipeActionsConfiguration(actions: [delete])
        }
        return UISwipeActionsConfiguration(actions: [])
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
    
    func deleteHandler(_ book: BookCell, _ userID: String, _ bookIndex: Int?, from wishlistOrInventory: String, userStatus sellerOrBuyer: String) {
        self.wait()
        let postID = String(book.bookCover.dropLast(4) as Substring)
        
        //remove book image from storage
        let imageRef = self.storageRef.child(book.bookCover)
        imageRef.delete{ error in
            if error != nil {
              print("failed to delete image")
            }
            
            //Remove book from Posts
            self.ref.child("Posts/\(postID)").removeValue()
            
            //Remove book from Inventory or Wishlist
            self.ref.child("\(wishlistOrInventory)/\(userID)/\(postID)").removeValue()
            
            //Remove post from User's Seller/Buyer Node
            self.ref.child("Books/\(book.isbn)/\(sellerOrBuyer)/\(userID)/Posts/\(postID)").removeValue()
            
            //database- if user has no more posts of the book, remove the user entirely from the book
            self.ref.child("Books/\(book.isbn)/\(sellerOrBuyer)/\(userID)").observeSingleEvent(of: .value, with: { (snapshot) in

                // Get user value
                let numChildren = snapshot.childrenCount

                if numChildren == 1 {
                    self.ref.child("Books/\(book.isbn)/Buyers/\(userID)").removeValue()
                }
                //if there are no longer sellers or buyers  of the book, remove the book entirely from the database
                self.ref.child("Books/\(book.isbn)").observeSingleEvent(of: .value, with: { (snapshot) in
                  // Get user value
                    let numChildren = snapshot.childrenCount

                    if numChildren == 1 {
                        self.ref.child("Books/\(book.isbn)").removeValue()
                    }
                    
                    self.start()
                    if let bookIndex = bookIndex {
                        self.reload(index: bookIndex)
                                            
                    }
                    
                    self.dismiss(animated: true, completion: nil)

                  }) { (error) in
                    print(error.localizedDescription)
                }
                
              }) { (error) in
                print(error.localizedDescription)
            }
        
        }
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
                // guard let cellLocation: CLLocationCoordinate2D = placemark.location?.coordinate else { return }
                // let request = MKDirections.Request()
                // // source and destination are the relevant MKMapItems
                // let source = MKPlacemark(coordinate: self.currLocation)
                // let destination = MKPlacemark(coordinate: cellLocation)
                // request.source = MKMapItem(placemark: source)
                // request.destination = MKMapItem(placemark: destination)

                // // Specify the transportation type
                // request.transportType = MKDirectionsTransportType.automobile;

                // // If open to getting more than one route,
                // // requestsAlternateRoutes = true; else requestsAlternateRoutes = false;
                // request.requestsAlternateRoutes = true

                // let directions = MKDirections(request: request)

                // directions.calculate { (response, error) in
                //     if let response = response, let route = response.routes.first {
                //         completion(MKDistanceFormatter().string(fromDistance: route.distance))
                //     }
                // }
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
        // print("Location updated:", location)
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
    
    override func viewDidDisappear(_ animated: Bool) {
        locationUpdateTimer.invalidate()
    }
    
    func wait() {
        self.listingsTableView.isHidden = false
        self.noResultsLabels.isHidden = true
        self.activityIndicator.startAnimating()
        self.view.alpha = 0.2
        self.view.isUserInteractionEnabled = false
    }
    
    func start() {
        if (self.books.count == 0) {
            self.listingsTableView.isHidden = true
            self.noResultsLabels.isHidden = false
        }
        else {
            self.listingsTableView.isHidden = false
            self.noResultsLabels.isHidden = true
        }
        self.activityIndicator.stopAnimating()
        self.view.alpha = 1
        self.view.isUserInteractionEnabled = true
    }
    
    @IBAction func tapped(_ sender: Any) {
        searchBar.resignFirstResponder()
    }
}
