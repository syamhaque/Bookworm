//
//  FilterViewController.swift
//  Bookworm
//
//  Created by Urvashi Mahto on 2/24/21.
//

import Foundation
import UIKit
import Firebase

protocol FilterViewControllerDelegate {
    func filterVCDismissed(selectedFilterValue: Int, selectedDistanceFilter: Int)
}

class FilterViewController: UIViewController {
    @IBOutlet weak var setFiltersButton: UIButton!
    @IBOutlet weak var categoryFilter: UISegmentedControl!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var distanceSlider: UISlider!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var categorySegment0 = "Listings"
    var categorySegment1 = "Requests"
    var categorySegment2 = "Both"
    
    var delegate: FilterViewControllerDelegate?
    
    var selectedFilterValue = 2
    var selectedDistanceFilter = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        categoryFilter.selectedSegmentIndex = selectedFilterValue
        distanceSlider.value = Float(selectedDistanceFilter)
        distanceLabel.text = "\(Int(distanceSlider.value))"
        //format buttons + view
        setFiltersButton.layer.cornerRadius = 5
        popupView.layer.cornerRadius = 10
        
        categoryFilter.setTitle(categorySegment0, forSegmentAt: 0)
        categoryFilter.setTitle(categorySegment1, forSegmentAt: 1)
        categoryFilter.setTitle(categorySegment2, forSegmentAt: 2)
    }
    
    @IBAction func setFiltersButtonPressed(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "homeViewController")
        guard let homeVC = vc as? HomeViewController else {
            assertionFailure("couldn't find vc")
            return
        }
        
        // 0 = Listing
        // 1 = Requests
        // 2 = Both
        if (categoryFilter.selectedSegmentIndex == 0) {
            print("Listing!")
            selectedFilterValue = 0
            homeVC.filterValue = 0
        } else if (categoryFilter.selectedSegmentIndex == 1) {
            print("Request!")
            selectedFilterValue = 1
            homeVC.filterValue = 1
        } else {
            print("Both!")
            selectedFilterValue = 2
            homeVC.filterValue = 2
        }
        selectedDistanceFilter = Int(distanceSlider.value)
        homeVC.filterValue = Int(distanceSlider.value)
        self.delegate?.filterVCDismissed(selectedFilterValue: selectedFilterValue, selectedDistanceFilter: selectedDistanceFilter)
        
        // Dismiss view controller
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func distanceSliderValueChanged(_ sender: Any) {
        self.distanceLabel.text = String(Int(distanceSlider.value))
    }
}
