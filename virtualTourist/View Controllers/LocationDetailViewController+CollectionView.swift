//
//  LocationDetailViewController+CollectionView.swift
//  virtualTourist
//
//  Created by Shir Bar Lev on 20/04/2022.
//

import Foundation
import UIKit

extension LocationDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    // MARK: UICollectionViewDataSource Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // if we're veiewing albums, set the length of that array as number of items in view
        if(currentMode == .PhotoAlbum) {
            return self.albumResultsController.fetchedObjects?.count ?? 0
        // otherwise make sure there's a photoResultsController; if there is, set the length of the fetched results as the number of items in view
        } else {
            guard let photoResultsController = photoResultsController else { return 0 }
            
            return photoResultsController.fetchedObjects?.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let viewCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumViewCell
        
        // if we're in albums mode, show the album in the given position and its title
        if(currentMode == .PhotoAlbum) {
            let albumAtIndex = self.albumResultsController.object(at: indexPath)
            
            DispatchQueue.main.async {
                viewCell.albumLabel.isHidden = false
                viewCell.albumLabel.text = albumAtIndex.name
                // randomly select an image from the set to display
                let randomNumber = Int.random(in:0..<(albumAtIndex.photos?.count ?? 0))
                let photosArray = albumAtIndex.photos?.allObjects as! [Photo]
                if let selectedPhoto = photosArray[randomNumber].photo {
                    viewCell.albumImage.image = UIImage(data: selectedPhoto)
                    viewCell.albumImage.alpha = 0.5
                }
            }
        // otherwise show the image in the given position
        } else {
            let photoAtIndex = self.photoResultsController?.object(at: indexPath)
            
            DispatchQueue.main.async {
                viewCell.albumLabel.isHidden = true
                viewCell.albumImage.alpha = 1
                
                if let photoAtIndex = photoAtIndex, let photo = photoAtIndex.photo {
                    viewCell.albumImage.image = UIImage(data: photo)
                }
            }
        }
        
        return viewCell
    }
    
    // MARK: UICollectionViewDelegate Methods
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return self.currentMode == .PhotoAlbum ? true : false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedAlbum = self.albumResultsController.object(at: indexPath)
        setupPhotoFetchedResultsController(selectedAlbum: selectedAlbum)
    }
}
