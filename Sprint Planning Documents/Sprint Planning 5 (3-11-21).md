# Sprint Planning 5 (3/11/21)

## App Summary

This platform facilitates a “yard sale”- for books. 
Each user will have a wish list that contains books they are searching for, and an inventory list that contains books they have but no longer want. 
Books can be added to either list by entering ISBN number, book condition (new, used, poor) and, optionally, a picture. 
The items on each user’s wish list/inventory list will be featured as listings on a general database, which will be able for all users to view. 
The app will also have a “matches” page, which displays all listings that correspond to the user’s personal wish list and inventory. 
Filters will be added to allow user to filter these listings by distance, condition, etc. 
Upon selecting a listing, users will be able to get into contact and arrange the book transaction!

## Trello Link
https://trello.com/invite/b/YcSdVfA2/6a48414a16ed7fb23fc1401451262411/bookworm

## Completed Tasks
  * Christina 
    * Pulled data from database to populate Wishlist and Inventory tableviews ([87a4e54](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/87a4e5418fb6145255a1fd4ea3675d961a5b07e7), [8ad364e](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/8ad364e1b5a6acbd0d3c80fdd1f797b2df0d98d5))
    * Populated wishlist's and inventory's book info views ([87a4e54](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/87a4e5418fb6145255a1fd4ea3675d961a5b07e7))
    * Added functionality to the "remove" buttons in wishlist/inventory (it now updates the database) ([6edd4b8](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/6edd4b8de278a6bec5bff5b3c25feb912bebfa6b), [7e579b5](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/7e579b522d52267c532a23364555e5ce59ce124c), [735a774](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/735a774b00407b1168a8e6f26a16621f370b79fc), [271a0da](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/271a0daf8cc171da20ae93a0e5689d3029725e0f))
    * Created Books, Inventories, Wishlists nodes on database, implemented pushing request/post information to these nodes ([865e2e8](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/865e2e888b63c1c3abbb018e3e374e72abbda23e), [2ddfa71](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/2ddfa7156bfb994fd1961602b6d8be8a5aa96c6d), [2bd21d5](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/2bd21d503dcbebaa96e0a7e863b7b1a4acc5804d), [ec7c0dc](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/ec7c0dc4aa859ca7096053aa96d9573fa72b75fe))
  * Joel
  * Peter
    * Created new node values for database, such as timestamp, books to post ([6b8d82e](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/6b8d82e8a23274907d7519b7200f6dc2b79d518e))
    * Populated HomeView filtering by date and time ([965ae5d](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/965ae5d12bf79b31c3ac83ef42811c6145602efd))
    * Implemented filtering for request and listing in HomeView ([bf5d9a7](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/bf5d9a72d014b3662ded25d35cfc95ad3fa91f52))
  * Urvashi 
    * pulling buyerseller phone number and populating messages based on post ([3d56abf](https://github.com/ECS189E/project-w21-steve-give-us-jobs/commit/3d56abf49cc4ca124eb6c8b6acbf763a5798ad7a))
  * Mohammed

## Planned Tasks
  * Christina
    * Add UI elements to wishlist/inventory (ie activity indicator)
    * Add functionality to "Add to Wishlist" button on home screen book info view
    * Update book condition picker 
  * Joel
  * Peter
    * Work on Matched View Controller
    * Implement search feature in HomeVC
  * Urvashi 
    * Conditional text rendering (buyer/seller) on dblistingvc
  * Mohammed
  
## Issues
  * Christina - None
  * Joel - None
  * Peter - None
  * Urvashi - None 
  * Mohammed - None
