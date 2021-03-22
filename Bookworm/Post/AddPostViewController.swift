//
//  AddPostViewController.swift
//  Bookworm
//
//  Created by Mohammed Haque on 3/8/21.
//

import UIKit
import Vision
import VisionKit
import Firebase
import CoreLocation

class AddPostBookCell: UITableViewCell {
    @IBOutlet weak var bookCoverImage: UIImageView!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var bookAuthorsLabel: UILabel!
    @IBOutlet weak var bookISBNLabel: UILabel!
    
    func fillInBookCell (book: Book){
        
        //fill in book cover if available
        if let coverImageDataM = book.coverImageM, let coverImageM = UIImage(data: coverImageDataM) {
            self.bookCoverImage.image = coverImageM
        } else if let coverImageDataS = book.coverImageS, let coverImageS = UIImage(data: coverImageDataS) {
            self.bookCoverImage.image = coverImageS
        } else if let coverImageDataL = book.coverImageL, let coverImageL = UIImage(data: coverImageDataL) {
            self.bookCoverImage.image = coverImageL
        } else {
            self.bookCoverImage.image = UIImage(systemName: "book")
        }
        
        //fill in book title
        self.bookTitleLabel.text = book.title

        //fill in book author
        self.bookAuthorsLabel.text = "Authors: " + book.authors.joined(separator: ", ")
        
        self.bookISBNLabel.text = "ISBN: " + book.isbn
    }
}


class AddPostViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, VNDocumentCameraViewControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    // Search API
    // https://openlibrary.org/dev/docs/api/search
    
    var books: [Book] = []
    var inputSearch: String = ""
    var recognizeTextRequest = VNRecognizeTextRequest()
    var recognizedText = ""
    var currentQuery = ""
    var bookConditionPickerData: [String] = [String]()
    var bookCondition: String = ""
    var storageRef = Storage.storage().reference()
    var ref = Database.database().reference()
    var bookLocation: String = ""
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultsTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noSearchResultsLabel: UILabel!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var bigSearchLabel: UILabel!
    @IBOutlet weak var bigScanLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsTableView.isHidden = true
        resultsTableView.dataSource = self
        resultsTableView.delegate = self
        searchBar.delegate = self
        
        self.activityIndicator.stopAnimating()
        
        noSearchResultsLabel.text = ""
        
        recognizeTextHandler()
        
        bookConditionPickerData = ["Poor", "Fair", "Good", "Great", "New"]
    }
    
    func getResults(num: Int, query: String) {
        OpenLibraryAPI.search(query) { response, error in
            if query != self.currentQuery { return }
            if let unwrappedError = error {
                print("search error")
                print(unwrappedError)
                self.start()
                return
            }
            guard let unwrappedResponse = response else {
                print("no response")
                self.start()
                return
            }
            guard let responseWorks = unwrappedResponse["docs"] as? [[String:Any]] else {
                print("bad docs response")
                self.start()
                return
            }
            
            if responseWorks.count == 0 {
                self.noSearchResultsLabel.text = "No Results Found"
                self.start()
                return
            }
            
            for work in responseWorks {
                if query != self.currentQuery {
                    self.start()
                    return
                }
                else if self.books.count >= num {
                    print("search done: " + query)
                    self.start()
                    self.resultsTableView.reloadData()
                    break
                }
                if let title = work["title"] as? String,
                   let authors = work["author_name"] as? [String],
                   let isbns = (work["isbn"] as? [String])?.filter({ $0.count == 13 }) {
                    // Required: Title, author(s), and ISBN 13
                    // Optional: publish date, cover
                    // Publish date should be retrieved when user clicks on UITableView cell
                    for isbn in isbns {
                        if query != self.currentQuery {
                            self.start()
                            return
                        }
                        else if self.books.count >= num {
                            break
                        }
                        let book = Book(title: title, isbn: isbn, authors: authors, publishDate: nil)
                        self.books.append(book)
                        self.resultsTableView.reloadData()
                        
                        // Get medium sized cover for the add request listing view
                        DispatchQueue.global(qos: .userInitiated).async {
                            OpenLibraryAPI.cover(key: .ISBN, value: isbn, size: .M) { response, error in
                                if let unwrappedError = error {
                                    print(unwrappedError)
                                }
                                else if let coverResponse = response {
                                    guard let imageData: Data = coverResponse["imageData"] as? Data else {
                                        print("bad image data")
                                        return
                                    }
                                    book.coverImageM = imageData
                                    self.resultsTableView.reloadData()
                                }
                            }
                        }
                    }
                }
            }
            self.resultsTableView.reloadData()
            self.start()
        }
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
        // Hide keyboard
        view.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        currentQuery = searchText
        books.removeAll()
        resultsTableView.reloadData()
        noSearchResultsLabel.text = ""
        if searchText.filter({!$0.isWhitespace}).isEmpty {
            self.start()
            bigSearchLabel.isHidden = false
            bigScanLabel.isHidden = false
            resultsTableView.isHidden = true
        }
        else {
            self.wait()
            bigSearchLabel.isHidden = true
            bigScanLabel.isHidden = true
            resultsTableView.isHidden = false
            getResults(num: 25, query: searchText)
        }
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

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "addPostBookCell") as? AddPostBookCell else {
            assertionFailure("Cell dequeue error")
            return UITableViewCell.init()
        }
        
        let book = books[indexPath.row]
        cell.fillInBookCell(book: book)
        cell.layer.cornerRadius = 5
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let book = books[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "addPostListingVC")
        guard let addPostListingVC = vc as? AddPostListingViewController else {
            assertionFailure("couldn't find vc")
            return
        }
        
        addPostListingVC.bookAuthors = book.authors
        addPostListingVC.bookTitle = book.title
        addPostListingVC.bookISBN = book.isbn
        addPostListingVC.bookCoverImageS = book.coverImageS
        addPostListingVC.bookCoverImageM = book.coverImageM
        addPostListingVC.bookCoverImageL = book.coverImageL
    
        present(addPostListingVC,animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let book = books[indexPath.row]
        let addPost = UIContextualAction(style: .normal, title: "Post") { (action, view, completion) in
            self.addPostHandler(book)
            self.resultsTableView.setEditing(false, animated: true)
        }
        addPost.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [addPost])
    }
    
    func addPostHandler(_ book: Book) {
        let alert = UIAlertController(title: "Choose book condition for your post", message: "\n\n", preferredStyle: .alert)
        let picker = UIPickerView(frame: CGRect(x: 9.5, y: 60, width: 250, height: 60))
        picker.dataSource = self
        picker.delegate = self
        
        alert.view.addSubview(picker)
        alert.addAction(UIAlertAction(title: "Post", style: .default, handler: { (action) in
            self.didPressPostAlert(book)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            self.resultsTableView.setEditing(false, animated: true)
        }))
        present(alert, animated: true)
    }
    
    func didPressPostAlert(_ book: Book) {
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
        if let bookCoverData = book.coverImageM {
            imageRef.putData(bookCoverData, metadata: nil) { (metadata, error) in
                if let error = error {
                    print(error)
                }
                if let metadata = metadata {
                    print(metadata)
                }
            }
        } else if let bookCoverData = book.coverImageS {
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
        ref.self.ref.child("Inventories").child(userID).child(uniquePostID).setValue(["ISBN": book.isbn])
        
        
        // Grab zipcode from user
        self.ref.child("Users").child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
            let userData = snapshot.value as? [String: String]
            let bookZipCode = userData?["ZipCode"] ?? ""
            let userFirstName = userData?["FirstName"] ?? ""
            let userLastName = userData?["LastName"] ?? ""
            let userFullName = userFirstName + " " + userLastName

            //change zip code to city and push new post onto database "Posts"
            self.getCityFromPostalCode(postalCode: bookZipCode, userID: userID, uniquePostID: uniquePostID, date: date, timestamp: timestamp, book: book)
        
            
            // add user as a "seller" of this book under database's "Books"
            self.ref.child("Books").child(book.isbn).observeSingleEvent(of: .value, with: { (snapshot) in
                //Fill in "BookInformation" node (currently does this every time a user is added as buyer/seller)
                self.ref.child("Books").child(book.isbn).child("Book_Information").setValue(["Title": book.title, "Author": book.authors.joined(separator: ", "), "Date_Published": book.publishDate ?? "", "Edition": "", "Photo_Cover": "\(uniquePostID).jpg"])
                
                // Append user info to "Sellers" node
                self.ref.child("Books").child(book.isbn).child("Sellers").child(userID).child("User_Information").setValue(["User_Name": userFullName, "User_Location": bookZipCode])
                    
                // Append post info to "Sellers" node
                self.ref.child("Books").child(book.isbn).child("Sellers").child(userID).child("Posts").child(uniquePostID).setValue(["Post_Timestamp": date, "Condition": self.bookCondition])
                
            }) { (error) in
                print("Error adding post to \"Books\" node")
                print(error.localizedDescription)
            }            
        })
    }
    
    func getCityFromPostalCode(postalCode: String, userID: String, uniquePostID: String, date: String, timestamp: String, book: Book) {
        
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
                self.createNewListing(userID: userID, uniquePostID: uniquePostID, date: date, timestamp: timestamp, book: book)
                
            }
            if let error = error {
                print(error)
                self.bookLocation = "Did not Work"
            }
        }
    }
    
    func createNewListing(userID: String, uniquePostID: String, date: String, timestamp: String, book: Book){
        // make push call to database
        self.ref.child("Posts").child(uniquePostID).setValue(["Title": book.title, "Author": book.authors.joined(separator: ", "), "Date_Published": book.publishDate ?? "", "Edition": "", "ISBN": book.isbn, "Condition": self.bookCondition, "User": userID, "Date_Posted": date, "Location": self.bookLocation, "User_Description": "Seller", "Photo_Cover": "\(uniquePostID).jpg", "Time_Stamp": timestamp])
    }
    
    @IBAction func scanBarcodePressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "scannerVC")
        guard let scannerVC = vc as? ScannerViewController else {
            assertionFailure("couldn't find vc")
            return
        }
        present(scannerVC, animated: true, completion: nil)
    }
    
    @IBAction func scanCoverPressed(_ sender: Any) {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        self.present(documentCameraViewController, animated: true, completion: nil)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        let image = scan.imageOfPage(at: 0)
        guard let cgimage = image.cgImage else {return}
        let handler = VNImageRequestHandler(cgImage: cgimage, options: [:])
        do {
            try handler.perform([recognizeTextRequest])
        } catch {
            print(error)
        }
        let ordinalNumberEndings = ["st", "nd", "rd", "th"]
        var recognizedTextArray = recognizedText.components(separatedBy: " ")
        let decimalDigits = CharacterSet.decimalDigits
        for (ind, str) in recognizedTextArray.enumerated() {
            let currStr = str.lowercased()
            if currStr.contains("edition") {
                recognizedTextArray[ind] = ""
                if ind > 0 {
                    if recognizedTextArray[ind - 1].rangeOfCharacter(from: decimalDigits) != nil || ordinalNumberEndings.filter({recognizedTextArray[ind - 1].lowercased().suffix(2).contains($0)}).count != 0 {
                        recognizedTextArray[ind - 1] = ""
                    }
                }
            }
        }
        
        let searchInputArray = recognizedTextArray.filter({$0 != ""})
        let searchText = searchInputArray.joined(separator: " ")
        searchBar.text = searchText
        searchBar(searchBar, textDidChange: searchText)
        self.tapGestureRecognizer.isEnabled = false
        
        controller.dismiss(animated: true)
    }
    
    func recognizeTextHandler() {
        recognizeTextRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNRecognizedTextObservation] {
                    self.recognizedText = ""
                    for observation in requestResults {
                        guard let candidiate = observation.topCandidates(1).first else { return }
//                        print(candidiate.string)
                        self.recognizedText += candidiate.string
                        self.recognizedText += " "
                    }
                }
            }
        })
        recognizeTextRequest.recognitionLevel = .accurate
        recognizeTextRequest.usesLanguageCorrection = true
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
    
    @IBAction func didTap(_ sender: UITapGestureRecognizer) {
        // Hide keyboard
        if sender.state == .ended {
            view.endEditing(true)
        }
    }
    
    func wait() {
        self.activityIndicator.startAnimating()
//        self.view.alpha = 0.2
//        self.view.isUserInteractionEnabled = false
    }
    func start() {
        self.activityIndicator.stopAnimating()
//        self.view.alpha = 1
//        self.view.isUserInteractionEnabled = true
    }
}

