//
//  SetupViewController.swift
//  SemSegiPhone
//
//  ViewController for SetupView
//
//  Created by ESP-NET on 5/22/20.
//  Copyright © 2020 Sachin Mehta. All rights reserved.
//

import UIKit

class SetupViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    // TODO: import list of classes from file
    let classes = ["Background", "Aeroplane", "Bicycle", "Bird", "Boat", "Bottle", "Bus", "Car", "Cat", "Chair", "Cow", "Diningtable", "Dog", "Horse", "Motorbike", "Person", "Pottedplant", "Sheep", "Sofa", "Train", "TV"]
    
    var selection = [Int]();

    @IBOutlet weak var Grid: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return classes.count
    }
    
    // populate collection view with cells
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("in cell")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell
        
        cell.CellLabel.text = classes[indexPath.item]
        print("creating cell for", classes[indexPath.item])
        
        // legacy red monochrome color equation
//        cell.backgroundColor = UIColor(red: 1.0, green: CGFloat(12 * indexPath.item) / 255.0, blue: CGFloat(12 * indexPath.item) / 255.0, alpha: 1.0);
        
        cell.backgroundColor = UIColor(red: CGFloat((indexPath.item * indexPath.item * 7) % 255) / 255.0, green: CGFloat(12 * indexPath.item) / 255.0, blue: CGFloat((((indexPath.item * indexPath.item) % 21) * 39) % 255) / 255.0, alpha: 1.0);
        if (cell.isSelected) {
            cell.backgroundColor = UIColor(red: CGFloat((indexPath.item * indexPath.item * 7) % 255) / 255.0, green: CGFloat(12 * indexPath.item) / 255.0, blue: CGFloat((((indexPath.item * indexPath.item) % 21) * 39) % 255) / 255.0, alpha: 0.5);
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selection.append(indexPath.item)
        print("selected index ", indexPath.item)
        print("selection ", selection)
        
        let selectedCell:UICollectionViewCell = collectionView.cellForItem(at: indexPath)!
        selectedCell.backgroundColor = UIColor(red: CGFloat((indexPath.item * indexPath.item * 7) % 255) / 255.0, green: CGFloat(12 * indexPath.item) / 255.0, blue: CGFloat((((indexPath.item * indexPath.item) % 21) * 39) % 255) / 255.0, alpha: 0.5);
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is ViewController
        {
            let vc = segue.destination as? ViewController
            vc?.selection = selection
            vc?.classes = classes
        }
    }
}
