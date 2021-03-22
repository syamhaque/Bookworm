# Bookworm
Steve Give Us Jobs

# Set Up
If testing on an external device, please modify the bundle identifier in Signing & Capabilities to your own unique bundle ID.

# Project Summary
## Bookworm

This platform facilitates a “yard sale”- for books. Each user will have a wish list that contains books they are searching for, and an inventory list that contains books they have but no longer want. Books can be added to either list by entering ISBN number, book condition (new, used, poor) and, optionally, a picture. The items on each user’s wish list/inventory list will be featured as listings on a general database, which will be able for all users to view. The app will also have a “matches” page, which displays all listings that correspond to the user’s personal wish list and inventory. Filters will be added to allow user to filter these listings by distance, condition, etc. Upon selecting a listing, users will be able to get into contact and arrange the book transaction!

# Team Members
## Joel Boersma 

(handler: joelboersma)

<img align="left" src="https://avatars.githubusercontent.com/u/44932998?s=400&u=e3f021c85674d7d01b437d9bae66f8fbe41761d5&v=4" width="100"> My largest contribution to this project was `OLAPI.swift`, which interfaces with the [Open Library API](https://openlibrary.org/developers/api). This is the source of all our book information on Post and Request pages, as well as for our two scanners. This file also includes a function for elegantly acquiring all the information of a book given just an ISBN. Utilizing the Open Library search API, I worked on the search funcionality on the Post and Request pages, at first only fetching results when the search button is pressed, and then fetching results each time the search bar text is changed. I worked on color-coding items on the Home and Matches pages based on whether whether the item is a listing or a request. I made some changes for `MatchesEntryViewController` so that it can be dual-purpose for both buying and selling. I also updated the way in which we get the distances between users in Home and Matches. Boilerplate repository setup, creating the launch screen, minor UI changes, and some optimizations round out my project contributions.

## Syam Haque 

(handler: syamhaque)

<img align="left" src="https://avatars.githubusercontent.com/u/32974225?s=400&u=baaf7fe021081d2878ce13e539b20eb080471774&v=4" width="100"> I contributed the most in developing the magical moment for this project with developing the barcode and book cover scanners using AVFoundation and Vision/VisionKit. I also contributed to developing the UI through designing the Matches view in Figma. and implementing primarily the Matches and Post views along with their branches in Storyboard. After the layout was finalized and implemented for all the views that appear post login, I went back and made all the views to look as uniform as possible with the repositioning of objects and the text font/size, along with redesigning the table cells to make them scrollable. The last contribution I made to the UI was implementing sliders for the table cells, some examples include swiping left to right in the home view to easily contact the poster or swiping right to left on your own post to easily delete it (there are sliders in all views with table views). My final contribution comes with the implmentation of changing locations and filtering for distance. Using CoreLocation and the location manager, current location is found, and using Geocoder with zipcodes, address is found and the distance is found between users.

## Peter Kim

(handler: pdekim)

<img align="left" src="https://avatars.githubusercontent.com/u/31204165?s=400&u=58ce474fdfed3527a70a413994fd6b317c6f6aa2&v=4" width="100"> My biggest contributions to the project was creating the login flow (from UI, backend authentication using Firebase Auth, storing new user data) as well as handling a large part of the backend functionalities for pushing/pulling data with our Firebase database. I worked closely with Christina in efficiently structuring the database in order to facilitate simple server calls for data push/pulls (following best practices, such as avoiding large, nested nodes, etc). I mainly focused on populating user table views with our book data and saving user posts/requests into our database, such as title, author, isbn, post date, etc. Additionally, I was also busy creating a search bar for HomeViewController and a filtering method for Home/Matched VCs. Some miscellaneous things I also worked on: book condition scroll picker, chronological ordering of posts, CoreLocation for converting zip-codes to city, UI constraint fixes, and small optimizations to our database schema.


## Christina Luong 

(handler: cyluong)

<img align="left" src="https://avatars.githubusercontent.com/u/50270872?s=400&u=e1524778cdcdd603a5a6ebd5bf620da6bbf8a976&v=4" width="100"> For frontend, my main contributions were setting up initial views/view controllers and flow for Profile view and their related views (Wishlist, Inventory, and their Book Information views). I also made updates to UI along the way. For backend, I collaborated closely with Peter on structuring the database. I also contributed to pushing/pulling/removing data to/from the database. Specifically, I worked on pushing book and wishlist/inventory information to the database upon new requests and listings (to the “Books”, “Wishlists”, and “Inventories” nodes). I worked on pulling data from the database to populate the Wishlist and Inventory views, and their associated pop-up book information views. Finally, I worked on removal of book, wishlist/inventory, and post information from the database upon presses on the “Remove from Wishlist” and “Remove from Inventory” buttons.


## Urvashi Mahto 

(handler: urvashimahto16)

<img align="left" src="https://avatars.githubusercontent.com/u/26194722?s=400&u=dc93bfb4b8509ee4845665520fa21ce46dedb021&v=4" width="100"> For frontend and UI, I worked on sketches in Figma with the rest of my team as well as the initial set up and linking of listings view (now home view), database listings pop up, and filter pop up and added placeholder information to table cells for testing purposes. For backend, I implemented the contact seller/buyer UI message composer pop up which pulls the buyer/seller's phone number from our realtime database and populates a personalized message using the user's first name and post details. I attempted a partial implementation of matches view, but it wasn't robust and a different implementation made more sense based on the structure of our database. Lastly, I implemented the backend portion of the change location button in profile view, by updating users' ZipCode values in our realtime database as needed.


# Designs for all Planned Views

Figma Link: https://www.figma.com/file/5MVhFopjyrgpRBxOYQlR8y/Bookworm-UI?node-id=0%3A1


# Link to Trello Board
https://trello.com/invite/b/YcSdVfA2/6a48414a16ed7fb23fc1401451262411/bookworm

# Github Classroom Project
https://github.com/ECS189E/project-w21-steve-give-us-jobs

