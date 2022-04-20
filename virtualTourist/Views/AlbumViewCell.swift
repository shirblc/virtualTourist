//
//  AlbumViewCell.swift
//  virtualTourist
//
//  Created by Shir Bar Lev on 20/04/2022.
//

import UIKit

class AlbumViewCell: UICollectionViewCell {
    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var albumLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        albumImage.image = nil
        albumLabel.text = nil
    }
}
