//
//  PhotosCollectionViewCell.swift
//  VirtualFlickrTourist
//
//  Created by Erik Uecke on 8/9/17.
//  Copyright © 2017 Erik Uecke. All rights reserved.
//



import Foundation
import UIKit


class PhotosCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    override var isSelected: Bool {
        didSet {
            imageView.layer.borderWidth = isSelected ? 100 : 0
        }
    }
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let themeColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.4)
        imageView.layer.borderColor = themeColor.cgColor
        isSelected = false
    }
    
}
