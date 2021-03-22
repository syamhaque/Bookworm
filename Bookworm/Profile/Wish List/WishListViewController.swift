//
//  WishListViewController.swift
//  Bookworm
//
//  Created by Christina Luong on 2/22/21.
//

import UIKit
import Firebase

class WishListTableViewCell: UITableViewCell{
    @IBOutlet weak var bookCoverImage: UIImageView!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var bookAuthorLabel: UILabel!
    @IBOutlet weak var bookPublishDateLabel: UILabel!
    @IBOutlet weak var bookISBNLabel: UILabel!
    
    func fillInWishListCell(book: WishListBook){
        self.bookCoverImage.image = UIImage(data: book.bookCoverData)
        self.bookTitleLabel.text = book.title
        self.bookAuthorLabel.text = book.authors.joined(separator: ", ")
        self.bookISBNLabel.text = "ISBN: \(book.isbn)"
        self.bookPublishDateLabel.text = "Publish Date: \(book.publishDate)"
    }
}

class WishListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ReloadAfterBookRemovalDelegate {

    @IBOutlet weak var wishListTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noItemsLabel: UILabel!
    
    var wishListBooks: [WishListBook] = []
    let storageRef = Storage.storage().reference()
    var ref = Database.database().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        wishListTableView.dataSource = self
        wishListTableView.delegate = self
        wishListTableView.reloadData()
        loadWishList()
        noItemsLabel.text = ""
        
    }
    
    @IBAction func didPressX(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func reloadAfterBookRemoval() {
        wishListBooks.removeAll()
        wishListTableView.reloadData()
        loadWishList()
    }
    
    func addBookToDataSource(bookInfo: NSDictionary, isbn: String, postID: String){
//        self.wait()

        guard let title = bookInfo.value(forKey: "Title") as? String, let authors = bookInfo.value(forKey: "Author") as? String, let publishDate = bookInfo.value(forKey: "Date_Published") as? String else{
            print("error getting book data")
            return
        }
        
        let cover = "\(postID).jpg"

        // get book image reference from Firebase Storage
        let bookCoverRef = self.storageRef.child(cover)
                
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
            
            let book = WishListBook(title: title, isbn: isbn, authors: [authors], publishDate: publishDate, bookCover: cover, bookCoverData: bookCoverData, postID: postID)
            self.wishListBooks.append(book)
            self.wishListTableView.reloadData()
//            self.start()

        }
    }
    
    func loadWishList(){
        // Grab user ID from logged in user
        guard let userID = Auth.auth().currentUser?.uid else {
            assertionFailure("Couldn't unwrap userID")
            return
        }
        ref.child("Wishlists").child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
            //get wishlist content, fill in table view
            guard let wishlist = snapshot.value as? NSDictionary else {
                self.noItemsLabel.text = "No Books in Wishlist"
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
                            
                            if let bookInfo = snapshot.value as? NSDictionary {
                                
                                self.addBookToDataSource(bookInfo: bookInfo, isbn: isbn, postID: postIDKey)
                            } else{
                                print("couldnt acess book information")
                            }
                        }) { (error) in
                            print("error loading book info")
//                            print(error.localizedDescription)
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
        return wishListBooks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "wishListCell", for: indexPath) as? WishListTableViewCell else {
            assertionFailure("Cell dequeue error")
            return UITableViewCell.init()
        }
        let book = wishListBooks[indexPath.row]
        cell.fillInWishListCell(book: book)
        cell.layer.cornerRadius = 10
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let book = wishListBooks[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "wishListListingViewController")
        guard let wishListListingVC = vc as? WishListListingViewController else {
            assertionFailure("couldn't find vc")
            return
        }
        
        wishListListingVC.delegate = self
        
        wishListListingVC.bookAuthors = book.authors.joined(separator: ", ")
        wishListListingVC.bookISBN = book.isbn
        wishListListingVC.bookTitle = book.title
        wishListListingVC.bookEdition = book.edition ?? ""
        wishListListingVC.bookCoverData = book.bookCoverData
        wishListListingVC.bookPublishDate = book.publishDate
        wishListListingVC.bookPostID = book.postID
        wishListListingVC.bookCover = book.bookCover
        
        present(wishListListingVC, animated: true, completion: nil)
    
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let book = wishListBooks[indexPath.row]
        let deleteCell = UIContextualAction(style: .normal, title: "Delete") { (action, view, completion) in
            self.deleteCellHandler(book)
            self.wishListTableView.setEditing(false, animated: true)
            self.reloadAfterBookRemoval()
        }
        deleteCell.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteCell])
    }
    
    func deleteCellHandler(_ book: WishListBook) {
        // Grab user ID from logged in user
        guard let userID = Auth.auth().currentUser?.uid else {
            assertionFailure("Couldn't unwrap userID")
            return
        }
        
        //database- remove post from "Posts"
        self.ref.child("Posts/\(book.postID)").removeValue()
        
        //database- remove book from user's wishlist in "Wishlists"
        self.ref.child("Wishlists/\(userID)/\(book.postID)").removeValue()

        //database- remove post from user's node in "Books" -> "Buyers" -> User ID
        self.ref.child("Books/\(book.isbn)/Buyers/\(userID)/Posts/\(book.postID)").removeValue()

        
        //database- if user has no more posts of the book, remove the user entirely from the book
        ref.child("Books/\(book.isbn)/Buyers/\(userID)").observeSingleEvent(of: .value, with: { (snapshot) in
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
              }) { (error) in
                print(error.localizedDescription)
            }

          }) { (error) in
            print(error.localizedDescription)
        }

        
        //database- remove book image from storage
        let imageRef = self.storageRef.child(book.bookCover)
        print("book cover" + book.bookCover)
        imageRef.delete{ error in
            if let error = error {
              print("faild to delete image")
            }
          }
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
