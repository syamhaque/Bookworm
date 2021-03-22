# Bookworm
Steve Give Us Jobs

# Project Summary
Bookworm

This platform facilitates a “yard sale”- for books. Each user will have a wish list that contains books they are searching for, and an inventory list that contains books they have but no longer want. Books can be added to either list by entering ISBN number, book condition (new, used, poor) and, optionally, a picture. The items on each user’s wish list/inventory list will be featured as listings on a general database, which will be able for all users to view. The app will also have a “matches” page, which displays all listings that correspond to the user’s personal wish list and inventory. Filters will be added to allow user to filter these listings by distance, condition, etc. Upon selecting a listing, users will be able to get into contact and arrange the book transaction!

# Team Members
Joel Boersma 

(handler: joelboersma)

<img src="https://avatars.githubusercontent.com/u/44932998?s=400&u=e3f021c85674d7d01b437d9bae66f8fbe41761d5&v=4" width="100">

Syam Haque 

(handler: syamhaque)

<img src="https://avatars.githubusercontent.com/u/32974225?s=400&u=baaf7fe021081d2878ce13e539b20eb080471774&v=4" width="100">

Peter Kim

(handler: pdekim)

<img src="https://avatars.githubusercontent.com/u/31204165?s=400&u=58ce474fdfed3527a70a413994fd6b317c6f6aa2&v=4" width="100">


Christina Luong 

(handler: cyluong)

<img src="https://avatars.githubusercontent.com/u/50270872?s=400&u=e1524778cdcdd603a5a6ebd5bf620da6bbf8a976&v=4" width="100">

Urvashi Mahto 

(handler: urvashimahto16)

<img src="https://avatars.githubusercontent.com/u/26194722?s=400&u=dc93bfb4b8509ee4845665520fa21ce46dedb021&v=4" width="100">


# Designs for all Planned Views

Figma Link: https://www.figma.com/file/5MVhFopjyrgpRBxOYQlR8y/Bookworm-UI?node-id=0%3A1

# Third Party Libraries for Potential Use
  * Core Location - For user locations
  * Firebase - Authentication, database storage
  * Open Library - For ISBN/book info
  * OCR (need to look into)
 
# Server support for Our App
  * Firebase
  
# A listing of all of the models you plan to include in your app
  * User 
    * WishList 
      * Book Titles
        * Condition
        * Location
        * User selling it
  * Inventory 
    * Book Titles
      * Condition
      * Location
      * User buying it
  * Name
  * Phone number
  * Radius Preference

# Listing of View Controllers 
Three Main View Controllers (Can navigate between each of these views through tab bar)
  * Listings View Controller: Database of all current book listings (books for “sale”, books “in need”)
    * Shows how many miles away the book is from user
    * Search function of book
    * Filter by book being sold or book being looked for
    * Filter by radius
    * Scan to add a book listing
      * Type in ISBN number or scan barcode
      * Show user the book we found, and ask to confirm. Otherwise go back to reenter
  * Matched View Controller: Lists all of the user’s “matches”
    * Table view of history and current listings that correspond to user's wish list or inventory
    * If user’s want to get in contact, it facilitates phone number exchanges/ transfers to imessaging
  * Profile View Controller
    * Settings Functionalities
    * Change user information 
    * Delete your account
    * Wish List
    * Inventory
      * See all of your own listings
    * Logout button

# This Week's Tasks
  * By Thursday (2/25):
    * Finish user interface
    * Add Matches View + its related views 
    * Add Scanner/Camera View + its related views
    * Update Create Account view
      * Add text field for user to enter a username and phone number 
  * By Sunday (2/28):
    * Begin setting up database 
    * Allow user to add items to wish list, inventory
    * Begin implementing OCR, location, ISBN

# Link to Trello Board
https://trello.com/invite/b/YcSdVfA2/6a48414a16ed7fb23fc1401451262411/bookworm

# Github Classroom Project
https://github.com/ECS189E/project-w21-steve-give-us-jobs

# Testing Plan
  * Test app on family and friends.
  * Perhaps a google form for different functionalities to add
