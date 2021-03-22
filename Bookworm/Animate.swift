//
//  Animate.swift
//  ConexUp
//
//  Created by Mohammed Haque on 1/28/21.
//

import Foundation
import UIKit

// Class to have all the animation functions I use.
class Animate {
    
    // Functions to animate objects coming in and out of view.
    func animateLabelInOut(_ outputLabel : UILabel, _ durationIn : Double = 1, _ durationOut : Double = 1, _ delayIn : Double = 0, _ delayOut : Double = 0) {
        // First animation used to display the output label.
        UIView.animate(withDuration: durationIn, delay: delayIn, options: .curveEaseOut) {
            outputLabel.alpha = 1
        } completion: { (completed) in
            // Upon completion of the first animation, do a second one that hides the output label with with a 3s delay at first.
            UIView.animate(withDuration: durationOut, delay: delayOut, options: .curveEaseIn) {
                outputLabel.alpha = 0
            }
        }
    }
    
    func animateButtonIn(_ outputButton : UIButton, _ durationIn : Double = 1, _ delayIn : Double = 0) {
        // Animation used to display the output button.
        UIView.animate(withDuration: durationIn, delay: delayIn, options: .curveEaseOut, animations: { outputButton.alpha = 1 }, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + durationIn + delayIn){outputButton.isUserInteractionEnabled = true}
    }
    
    func animateButtonOut(_ outputButton : UIButton, _ durationOut : Double = 1, _ delayOut : Double = 0)  {
        // Animation used to hide the output button.
        UIView.animate(withDuration: durationOut, delay: delayOut, options: .curveEaseIn, animations: { outputButton.alpha = 0 }, completion: nil)
        outputButton.isUserInteractionEnabled = false
    }
}
