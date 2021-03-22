//
//  OpenLibraryAPI.swift
//  Bookworm
//
//  Created by Joel Boersma on 2/26/21.
//

import Foundation

/* APIs to use
 Books: https://openlibrary.org/dev/docs/api/books
   - Works, Editions, ISBN
 Search: https://openlibrary.org/dev/docs/api/search
 Covers: https://openlibrary.org/dev/docs/api/covers
 */

enum BookCoverSize : String {
    case S, M, L
}

enum BookCoverKey : String {
    case ISBN
    case OLID   // Open Library ID for edition
    case ID     // Cover ID
}

struct OpenLibraryAPI {
    
    struct ApiError: Error {
        var message: String
        var code: String
        
        init(response: [String: Any]) {
            self.message = (response["error_message"] as? String) ?? "Network error"
            self.code = (response["error_code"] as? String) ?? "network_error"
        }
    }
    
    typealias ApiCompletion = ((_ response: [String: Any]?, _ error: ApiError?) -> Void)
    
    static let defaultError = ApiError(response: [:])
    
    static func configuration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        return config
    }
    
    static func ApiCall(endpoint: String, completion: @escaping ApiCompletion) {
        let baseUrl = "https://openlibrary.org"
        
        guard let url = URL(string: baseUrl + endpoint) else {
            print("Wrong url")
            return
        }
        
        let session = URLSession(configuration: configuration())
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { data, response, error in
            guard let rawData = data else {
                print("no raw data")
                DispatchQueue.main.async { completion(nil, defaultError) }
                return
            }
            
            let jsonData = try? JSONSerialization.jsonObject(with: rawData)
            guard let responseData = jsonData as? [String: Any] else {
                print("no response data")
                DispatchQueue.main.async { completion(nil, defaultError) }
                return
            }
            
            DispatchQueue.main.async {
                if error == nil {
                    completion(responseData, nil)
                } else {
                    print(error ?? "unknown error")
                    completion(nil, ApiError(response: responseData))
                }
            }
            
        }.resume()
    }
    
    static func CoverApiCall(endpoint: String, completion: @escaping ApiCompletion) {
        let baseUrl = "https://covers.openlibrary.org"
        
        guard let url = URL(string: baseUrl + endpoint) else {
            print("Wrong url")
            return
        }
        
        let session = URLSession(configuration: configuration())
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { data, response, error in
            guard let sessionResponse = response as? HTTPURLResponse else{
                print("no response")
                return
            }

            
            guard let rawData = data else {
                print("no raw data")
                DispatchQueue.main.async { completion(nil, defaultError) }
                return
            }
    
            
            // JPEG data will need to be converted to UIImage within VC
            let responseData: [String: Any] = ["imageData": rawData]
        
            DispatchQueue.main.async {
                if error == nil && sessionResponse.statusCode != 404 {
                    completion(responseData, nil)
                } else {
                    print(error ?? "unknown error")
                    completion(nil, ApiError(response: responseData))
                }
            }
            
        }.resume()
    }
    
    static func unwrapInnerKey(fromDictionary dic: [String: Any], forOuterKey key: String) -> String? {
        guard let objects = dic[key] as? [[String: Any]] else {
            print("couldn't find object array: " + key)
            return nil
        }
        guard let firstObject = objects.first else {
            print("couldn't find first object: " + key)
            return nil
        }
        return firstObject["key"] as? String
    }
    
    
    /// Makes an API call at endpoint and calls completion when finished
    static func generic(_ endpoint: String, completion: @escaping ApiCompletion) {
        let jsonEndpoint = endpoint + ".json"
        ApiCall(endpoint: jsonEndpoint, completion: completion)
    }
    
    static func search(_ searchText: String, completion: @escaping ApiCompletion) {
        guard let query: String = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("bad url string")
            return
        }
        
        ApiCall(endpoint: "/search.json?q=\(query)", completion: completion)
    }
    
    /**
    Use an IBSN, Open Library ID, or a cover ID with book cover size S, M, or L.
    response["imageData"] contains JPEG image data, needs to be converted to a UIImage.
     
    Sample code for using image data:
     
         guard let imageData: Data = response["imageData"] as? Data else {
             print("bad image data")
             return
         }
         let image = UIImage(data: imageData)
         let imageView = UIImageView(image: image)
         self.view.addSubview(imageView)
     */
    static func cover(key: BookCoverKey, value: String, size: BookCoverSize, completion: @escaping ApiCompletion) {
        CoverApiCall(endpoint: "/b/\(key.rawValue)/\(value)-\(size.rawValue).jpg?default=false", completion: completion)
      
    }
    
    static func author(_ key: String, completion: @escaping ApiCompletion) {
        if (key.lowercased().hasPrefix("/authors/ol")) {
            let jsonKey = key + ".json"
            ApiCall(endpoint: jsonKey, completion: completion)
        }
        else {
            print("Error: Invalid path for author")
        }
    }
    
    // may not need this
    static func works(_ key: String, completion: @escaping ApiCompletion) {
        if (key.lowercased().hasPrefix("/works/ol")) {
            let jsonKey = key + ".json"
            ApiCall(endpoint: jsonKey, completion: completion)
        }
        else {
            print("Error: Invalid path for works")
        }
    }
    
    // may not need this
    static func editions(_ key: String, completion: @escaping ApiCompletion) {
        if (key.lowercased().hasPrefix("/books/ol")) {
            let jsonKey = key + ".json"
            ApiCall(endpoint: jsonKey, completion: completion)
        }
        else {
            print("Error: Invalid path for editions")
        }
    }
    
    // Should work with both ISBN-10 and ISBN-13
    static func ISBN(_ isbn: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/isbn/\(isbn).json", completion: completion)
    }
    static func ISBN(_ isbn: Int, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/isbn/\(isbn).json", completion: completion)
    }
    
    /*
     if we want all info...
     - title
     - author
     - cover
     - publishing date
     - edition
     - isbn13
     */
    
    // returns json object containing author name(s) and one cover from a given works key
    static func getWorksInfo(key: String, bookCoverSize: BookCoverSize) -> [String: Any] {
        var worksInfo: [String: Any] = [:]
        
        let semaphore = DispatchSemaphore(value: 0)
        works(key) { worksResponse, error in
            if let _error = error {
                print(_error)
                return
            }
            else if let _worksResponse = worksResponse {
                
                if let coverArray = _worksResponse["covers"] as? [Int], let coverID = coverArray.first {
                    cover(key: .ID, value: String(coverID), size: bookCoverSize) { coverResponse, error in
                        if let unwrappedError = error {
                            print("works cover error")
                            return
                        }
                        else if let coverResponse = coverResponse {
                            if let imageData = coverResponse["imageData"] as? Data {
                                worksInfo["imageData"] = imageData
                            }
                            else {
                                print("works bad cover image data")
                            }
                        }
                        else {
                            print("bad works cover response")
                        }
                        semaphore.signal()
                    }
                }
                else {
                    semaphore.signal()
                }
                
                if let authorsJson = _worksResponse["authors"] as? [[String: Any]] {
                    var authorNames: [String] = []
                    print("\(authorsJson.count) author(s)")
                    for authorArrayObject in authorsJson {
                        if let authorObject = authorArrayObject["author"] as? [String : Any],
                           let key = authorObject["key"] as? String {
                            print(key)
                            author(key) { authorResponse, authorError in
                                if let _authorError = authorError {
                                    // author error
                                    print(_authorError)
                                }
                                else if let _authorResponse = authorResponse,
                                        let authorName = _authorResponse["name"] as? String {
                                    authorNames.append(authorName)
                                }
                                else {
                                    print("bad author response")
                                }
                                
                                // if it's the final author, start the exit process
                                if authorNames.count == authorsJson.count {
                                    authorNames.sort()  // because they might be added out of order
                                    worksInfo["authors"] = authorNames
                                    semaphore.signal()
                                }
                            }
                        }
                        else {
                            // couldn't find key in author object
                            return
                        }
                    }
                }
                else {
                    
                }
            }
            else {
                print("bad works info")
            }
        }
        
        semaphore.wait()
        semaphore.wait()
        return worksInfo
    }
    
    
    static func getAllInfoForISBN(_ isbn: String, bookCoverSize: BookCoverSize, completion: @escaping ApiCompletion) {
        var bookInfo: [String: Any] = [:]
        bookInfo["isbn"] = isbn
        
        var worksKey: String = ""
        var worksInfo: [String: Any] = [:]
        
        ISBN(isbn) { isbnResponse, error in
            // title, publish date, isbn13
            if let unwrappedError = error {
                DispatchQueue.main.async {
                    completion(bookInfo, unwrappedError)
                }
                return
            }
            else if let _isbnResponse = isbnResponse {
                bookInfo["title"] = _isbnResponse["title"]
                bookInfo["publishDate"] = _isbnResponse["publish_date"]
                
                // get works key, just in case
                if let worksJson = _isbnResponse["works"] as? [[String: Any]],
                   let worksObject = worksJson.first {
                    worksKey = worksObject["key"] as? String ?? ""
                }
                
                cover(key: .ISBN, value: isbn, size: bookCoverSize) { coverResponse, error in
                    // cover
                    DispatchQueue.global(qos: .userInitiated).async {
                        if let unwrappedError = error {
                            DispatchQueue.main.async {
                                completion(bookInfo, unwrappedError)
                            }
                        }
                        else if let coverResponse = coverResponse {
                            if let imageData = coverResponse["imageData"] as? Data {
                                bookInfo["imageData"] = imageData
                            }
                            else {
                                print("bad cover image data")
                                if !worksKey.isEmpty && worksInfo.isEmpty {
                                    print("going to works")
                                    worksInfo = getWorksInfo(key: worksKey, bookCoverSize: bookCoverSize)
                                }
                                
                                if !worksInfo.isEmpty {
                                    print("using works info for cover")
                                    bookInfo["imageData"] = worksInfo["imageData"]
                                }
                            }
                            
                            // authors
                            if let authorsJson = _isbnResponse["authors"] as? [[String: Any]] {
                                var authorNames: [String] = []
                                print("\(authorsJson.count) author(s)")
                                for a in authorsJson {
                                    if let key = a["key"] as? String {
                                        author(key) { authorResponse, authorError in
                                            if let _authorError = authorError {
                                                // author error
                                                print(_authorError)
                                            }
                                            else if let _authorResponse = authorResponse,
                                                    let authorName = _authorResponse["name"] as? String {
                                                authorNames.append(authorName)
                                            }
                                            else {
                                                print("bad author response")
                                            }
                                            
                                            // if it's the final author, start the exit process
                                            if authorNames.count == authorsJson.count {
                                                authorNames.sort()  // because they might be added out of order
                                                bookInfo["authors"] = authorNames
                                                DispatchQueue.main.async {
                                                    completion(bookInfo, nil)
                                                }
                                            }
                                        }
                                    }
                                    else {
                                        // couldn't find key in author object
                                    }
                                }
                            }
                            else {
                                print("can't find authors in isbn response")
                                // check works
                                if !worksKey.isEmpty && worksInfo.isEmpty {
                                    print("going to works")
                                    worksInfo = getWorksInfo(key: worksKey, bookCoverSize: bookCoverSize)
                                }
                                
                                if !worksInfo.isEmpty {
                                    print("using works info for authors")
                                    bookInfo["authors"] = worksInfo["authors"]
                                    DispatchQueue.main.async {
                                        completion(bookInfo, nil)
                                    }
                                }
                                else {
                                    DispatchQueue.main.async {
                                        completion(bookInfo, ApiError(response: [:]))
                                    }
                                }
                            }
                        }
                        else {
                            print("bad response cover")
                        }
                    }
                }
            }
            else {
                print("bad response ISBN")
                DispatchQueue.main.async {
                    completion(bookInfo, ApiError(response: [:]))
                }
                return
            }
        }
        
    }
    
    static func getAllInfoForISBN(_ isbn: Int, bookCoverSize: BookCoverSize, completion: @escaping ApiCompletion) {
        getAllInfoForISBN("\(isbn)", bookCoverSize: bookCoverSize, completion: completion)
    }
}
