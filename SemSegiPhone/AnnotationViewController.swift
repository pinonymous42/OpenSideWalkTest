//
//  AnnotationViewController.swift
//  SemSegiPhone
//
//  ViewController for AnnotationView
//
//  Created by ESP-NET on 5/29/20.
//  Copyright © 2020 Sachin Mehta. All rights reserved.
//

import UIKit

class AnnotationViewController: UIViewController {

    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet weak var capturedSeg: UIImageView!
    @IBOutlet weak var buttons: UIStackView!
    @IBOutlet weak var colorswatch: UIImageView!
    @IBOutlet weak var classLabel: UILabel!
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    private var index: Int!
    
    // handled by segue
    var capImage: UIImage!
    var capSeg: UIImage!
    var classes = [String]();
    var selection = [Int]();
    var responses = [Int]();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        responses = selection
        
        capturedImage.image = capImage
        capturedSeg.image = capSeg
        
        index = 0
        
        colorswatch.backgroundColor = UIColor(red: 1.0, green: CGFloat(12 * selection[index]) / 255.0, blue: CGFloat(12 * selection[index]) / 255.0, alpha: 1.0);
        
        classLabel.text = classes[selection[index]]
        progressBar.progress = Float(index)
        
        for subview in buttons.arrangedSubviews {
            let btn = subview as! UIButton
            btn.addTarget(self, action: #selector(selectionClicked), for: .touchUpInside)
        }
    }
    
    // TODO: clean up
    @objc func selectionClicked(_ sender: AnyObject?) {
        let btn = sender as! UIButton
        if sender === buttons.arrangedSubviews[0] {
            responses[index] = 0
            btn.setTitleColor(UIColor.red, for: .normal)
            let btn2 = buttons.arrangedSubviews[1] as! UIButton
            let btn3 = buttons.arrangedSubviews[2] as! UIButton
            btn2.setTitleColor(UIColor.blue, for: .normal)
            btn3.setTitleColor(UIColor.blue, for: .normal)
        } else if sender === buttons.arrangedSubviews[1] {
            responses[index] = 1
            btn.setTitleColor(UIColor.red, for: .normal)
            let btn2 = buttons.arrangedSubviews[2] as! UIButton
            let btn3 = buttons.arrangedSubviews[0] as! UIButton
            btn2.setTitleColor(UIColor.blue, for: .normal)
            btn3.setTitleColor(UIColor.blue, for: .normal)
        } else if sender === buttons.arrangedSubviews[2] {
            responses[index] = 2
            btn.setTitleColor(UIColor.red, for: .normal)
            let btn2 = buttons.arrangedSubviews[1] as! UIButton
            let btn3 = buttons.arrangedSubviews[0] as! UIButton
            btn2.setTitleColor(UIColor.blue, for: .normal)
            btn3.setTitleColor(UIColor.blue, for: .normal)
        }
        print("response", responses[index])
    }

    // handle next btn
    @IBAction func onClickNext(_ sender: Any) {
        index += 1
        progressBar.progress += 1.0 / Float(selection.count)
        
        if (index == selection.count) {
            _ = navigationController?.popViewController(animated: true)
        } else {
            classLabel.text = classes[selection[index]]
            // TODO: swap to new color mapping
            colorswatch.backgroundColor = UIColor(red: 1.0, green: CGFloat(12 * selection[index]) / 255.0, blue: CGFloat(12 * selection[index]) / 255.0, alpha: 1.0);
        }
        
        for subview in buttons.arrangedSubviews {
            let btn = subview as! UIButton
            btn.setTitleColor(UIColor.blue, for: .normal)
        }
    }
}
