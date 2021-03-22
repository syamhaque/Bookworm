//
//  Book.swift
//  Bookworm
//
//  Created by Joel Boersma on 3/1/21.
//

import Foundation

class Book {
    /*
     if we want all info...
     - title
     - author
     - cover
     - publishing date
     - edition??? (isbn already kinda does that)
     - isbn13
     */
    
    let title: String
    let isbn: String
    let authors: [String]
    
    var publishDate: String?
    var coverImageS: Data? = nil
    var coverImageM: Data? = nil
    var coverImageL: Data? = nil
    
    init(title: String, isbn: String, authors: [String], publishDate: String?) {
        self.title = title
        self.isbn = isbn
        self.authors = authors
        self.publishDate = publishDate
    }
}


class BookCell {
    
    // This class is used in HomeViewController
    
    let title: String
    let isbn: String
    let edition: String
    let publishDate: String
    let author: String
    let condition: String
    let location: String
    let distance: String
    let buyerSellerID: String
    let buyerSeller: String
    let postDate: String
    let timeStamp: String
    let bookCover: String
    let userDescription: String
    let bookCoverData: NSData
    
    // Initialize for each book
    
    init(title: String, isbn: String, edition: String, publishDate: String, author: String, condition: String, location: String, distance: String, buyerSellerID: String, buyerSeller: String, postDate: String, timeStamp:String, bookCover: String, userDescription: String, bookCoverData: NSData) {
        
        self.title = title
        self.isbn = isbn
        self.edition = edition
        self.publishDate = publishDate
        self.author = author
        self.condition = condition
        self.location = location
        self.distance = distance
        self.buyerSellerID = buyerSellerID
        self.buyerSeller = buyerSeller
        self.postDate = postDate
        self.timeStamp = timeStamp
        self.bookCover = bookCover
        self.userDescription = userDescription
        self.bookCoverData = bookCoverData
        
    }
    
}
