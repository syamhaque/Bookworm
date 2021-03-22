//
//  InventoryViewController.swift
//  Bookworm
//
//  Created by Christina Luong on 2/22/21.
//

import UIKit
import Firebase


class InventoryTableViewCell: UITableViewCell{
    @IBOutlet weak var bookCoverImage: UIImageView!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var bookAuthorLabel: UILabel!
    @IBOutlet weak var bookPublishDateLabel: UILabel!
    @IBOutlet weak var bookISBNLabel: UILabel!
    @IBOutlet weak var bookConditionLabel: UILabel!
    
    func fillInInventoryCell(book: InventoryBook){
        self.bookCoverImage.image = UIImage(data: book.bookCoverData)
        self.bookTitleLabel.text = book.title
        self.bookAuthorLabel.text = book.authors.joined(separator: ", ")
        self.bookConditionLabel.text = "Condition: " + book.condition
        self.bookISBNLabel.text = "ISBN: " + book.isbn
        self.bookPublishDateLabel.text = "Publish Date: " + book.publishDate
    }
}

class InventoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ReloadAfterBookRemovalDelegate {
    
    @IBOutlet weak var inventoryTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noItemsLabel: UILabel!
    
    var inventoryBooks: [InventoryBook] = []
    let storageRef = Storage.storage().reference()
    var ref = Database.database().reference()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inventoryTableView.dataSource = self
        inventoryTableView.delegate = self
        inventoryTableView.reloadData()
        loadInventory()
        noItemsLabel.text = ""

    }
    
    
    @IBAction func didPressX(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func addBookToDataSource(bookInfo: NSDictionary, isbn: String, condition: String, postID: String){
        print("here")
        guard let title = bookInfo.value(forKey: "Title") as? String, let authors = bookInfo.value(forKey: "Author") as? String, let publishDate = bookInfo.value(forKey: "Date_Published") as? String else{
            print("error getting book data")
            return
        }
        let cover = "\(postID).jpg"
                
        let storageRef = Storage.storage().reference()

        // get book image reference from Firebase Storage
        let bookCoverRef = storageRef.child(cover)
        
        // download URL of reference, then get contents of URL and set imageView to UIImage
        bookCoverRef.downloadURL { url, error in
            guard let imageURL = url, error == nil else {
                print(error ?? "")
                return
            }
            
            guard let bookCoverData = NSData(contentsOf: imageURL) as Data? else {
                assertionFailure("Error in getting Data")
                return
            }
            let book = InventoryBook(title: title, isbn: isbn, authors: [authors], publishDate: publishDate, bookCover: cover, bookCoverData: bookCoverData, condition: condition, postID: postID)
            self.inventoryBooks.append(book)
            self.inventoryTableView.reloadData()
        }
    }
    
    func reloadAfterBookRemoval() {
        inventoryBooks.removeAll()
        inventoryTableView.reloadData()
        loadInventory()
    }
    
    func loadInventory(){
        // Grab user ID from logged in user
        guard let userID = Auth.auth().currentUser?.uid else {
            assertionFailure("Couldn't unwrap userID")
            return
        }
        ref.child("Inventories").child(userID).observeSingleEvent(of: .value, with: { (snapshot) in

            //get wishlist content, fill in table view
            guard let wishlist = snapshot.value as? NSDictionary else {
                self.noItemsLabel.text = "No Books in Inventory"
                return
            }
            for postID in wishlist{
                guard let postIDKey = postID.key as? String else{
                    print("post id couldn't be unwrapped")
                    return
                }
            
                if let isbnNode = postID.value as? [String: String], let isbn = isbnNode["ISBN"]{
                    // look up isbn in Books node for book info -> fill in table view cell
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.ref.child("Books").child(isbn).child("Book_Information").observeSingleEvent(of: .value, with: { (snapshot) in
                            
                            //create book instance, add to array
                            if let bookInfo = snapshot.value as? NSDictionary {
                                //get book condition
                                self.ref.child("Books").child(isbn).child("Sellers").child(userID).child("Posts").child(postIDKey).observeSingleEvent(of: .value, with: { (snapshot) in
                                    if let postInfo = snapshot.value as? NSDictionary, let condition = postInfo.value(forKey: "Condition") as? String{
                                        
                                        self.addBookToDataSource(bookInfo: bookInfo, isbn: isbn, condition: condition, postID: postIDKey)
                                    }
                                  }) { (error) in
                                    print(error.localizedDescription)
                                }
                            } else{
                                print("couldnt acess book information")
                            }
                            
                        }) { (error) in
                            print("error loading book info")
                            print(error.localizedDescription)
                        }
                    }
                }
            }
          }) { (error) in
            print("error loading wishlist")
            print(error.localizedDescription)
        }
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inventoryBooks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "inventoryCell", for: indexPath) as? InventoryTableViewCell else {
            assertionFailure("Cell dequeue error")
            return UITableViewCell.init()
        }
        
        let book = inventoryBooks[indexPath.row]
        cell.fillInInventoryCell(book: book)
        cell.layer.cornerRadius = 10
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let book = inventoryBooks[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "inventoryListingViewController")
        guard let inventoryListingVC = vc as? InventoryListingViewController else {
            assertionFailure("couldn't find vc")
            return
        }
        
        inventoryListingVC.delegate = self
        
        inventoryListingVC.bookAuthors = book.authors.joined(separator: ", ")
        inventoryListingVC.bookISBN = book.isbn
        inventoryListingVC.bookTitle = book.title
        inventoryListingVC.bookEdition = book.edition ?? ""
        inventoryListingVC.bookCoverData = book.bookCoverData
        inventoryListingVC.bookPublishDate = book.publishDate
        inventoryListingVC.bookCondition = book.condition
        inventoryListingVC.bookPostID = book.postID
        inventoryListingVC.bookCover = book.bookCover
        
        present(inventoryListingVC, animated: true, completion: nil)

    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let book = inventoryBooks[indexPath.row]
        let deleteCell = UIContextualAction(style: .normal, title: "Delete") { (action, view, completion) in
            self.deleteCellHandler(book)
            self.inventoryTableView.setEditing(false, animated: true)
            self.reloadAfterBookRemoval()
        }
        deleteCell.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteCell])
    }
    
    func deleteCellHandler(_ book: InventoryBook) {
        // Grab user ID from logged in user
        guard let userID = Auth.auth().currentUser?.uid else {
            assertionFailure("Couldn't unwrap userID")
            return
        }
        
        
        //database- remove post from "Posts"
        self.ref.child("Posts/\(book.postID)").removeValue()
        
        //database- remove book from user's inventory in "Inventories"
        self.ref.child("Inventories/\(userID)/\(book.postID)").removeValue()
        
        //database- remove post from user's node in "Books" -> "Sellers" -> User ID
        self.ref.child("Books/\(book.isbn)/Sellers/\(userID)/Posts/\(book.postID)").removeValue()
        
        //database- if user has no more posts of the book, remove the user entirely from the book
        ref.child("Books/\(book.isbn)/Sellers/\(userID)").observeSingleEvent(of: .value, with: { (snapshot) in
          // Get user value
            let numChildren = snapshot.childrenCount

            if numChildren == 1 {
                self.ref.child("Books/\(book.isbn)/Sellers/\(userID)").removeValue()
            }
            //if there are no longer sellers or buyers  of the book, remove the book entirely from the database
            self.ref.child("Books/\(book.isbn)").observeSingleEvent(of: .value, with: { (snapshot) in
              // Get user value
                let numChildren = snapshot.childrenCount

                if numChildren == 1 {
                    self.ref.child("Books/\(book.isbn)").removeValue()
                }
              }) { (error) in
                print(error.localizedDescription)
            }

          }) { (error) in
            print(error.localizedDescription)
        }

        
        //database- remove book image from storage
        let imageRef = self.storageRef.child(book.bookCover)
        imageRef.delete(completion: nil)
    }
    
    func wait() {
        self.activityIndicator.startAnimating()
        self.view.alpha = 0.2
        self.view.isUserInteractionEnabled = false
    }
    
    func start() {
        self.activityIndicator.stopAnimating()
        self.view.alpha = 1
        self.view.isUserInteractionEnabled = true
    }
    
}
