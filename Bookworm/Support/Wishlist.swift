//
//  Wishlist.swift
//  Bookworm
//
//  Created by Christina Luong on 3/8/21.
//

import Foundation
class WishListBook {
    let title: String
    let isbn: String
    let authors: [String]
    var publishDate: String
    let bookCover: String
    let bookCoverData: Data
    var edition: String? = ""
    let postID: String
 

    init(title: String, isbn: String, authors: [String], publishDate: String, bookCover: String, bookCoverData: Data, postID: String) {
        self.title = title
        self.isbn = isbn
        self.authors = authors
        self.publishDate = publishDate
        self.bookCover = bookCover
        self.bookCoverData = bookCoverData
        self.postID = postID
    
    }
}

