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
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return (currentMode == .PhotoAlbum ? albumResultsController.sections?.count : photoResultsController?.sections?.count) ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // if we're veiewing albums, set the length of that array as number of items in view
        if(currentMode == .PhotoAlbum) {
            return self.albumResultsController.sections?[section].numberOfObjects ?? 0
        // otherwise make sure there's a photoResultsController; if there is, set the length of the fetched results as the number of items in view
        } else {
            guard let photoResultsController = photoResultsController else { return 25 }
            let numberOfPhotosInAlbum = photoResultsController.sections?[section].numberOfObjects ?? 0
            
            return numberOfPhotosInAlbum == 0 ? 25 : numberOfPhotosInAlbum
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let viewCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumViewCell
        viewCell.layer.borderWidth = 1
        viewCell.layer.borderColor = UIColor.gray.cgColor
        
        // if we're in albums mode, show the album in the given position and its title
        if(currentMode == .PhotoAlbum) {
            let albumAtIndex = self.albumResultsController.object(at: indexPath)
            
            DispatchQueue.main.async {
                viewCell.albumLabel.isHidden = false
                viewCell.albumLabel.text = albumAtIndex.name
                // randomly select an image from the set to display
                if let photos = albumAtIndex.photos {
                    if photos.count > 0 {
                        let randomNumber = Int.random(in:0..<photos.count)
                        let photosArray = photos.allObjects as! [Photo]
                        if let selectedPhoto = photosArray[randomNumber].photo {
                            viewCell.albumImage.image = UIImage(data: selectedPhoto)
                            viewCell.albumImage.alpha = 0.5
                        }
                    } else {
                        viewCell.albumImage.image = nil
                    }
                }
            }
        // otherwise show the image in the given position
        } else {
            var photoAtIndex: Photo?
            
            // if there are images, get the image
            if(self.photoResultsController?.sections?[indexPath.section].numberOfObjects ?? 0 > indexPath.row) {
                photoAtIndex = self.photoResultsController?.object(at: indexPath)
            // otherwise set it to nil so we can set the image to the placeholder
            } else {
                photoAtIndex = nil
            }
            
            DispatchQueue.main.async {
                viewCell.albumLabel.isHidden = true
                viewCell.albumImage.alpha = 1
                
                if let photoAtIndex = photoAtIndex, let photo = photoAtIndex.photo {
                    viewCell.albumImage.image = UIImage(data: photo)
                } else {
                    viewCell.albumImage.image = UIImage(systemName: "photo.fill")
                }
            }
        }
        
        return viewCell
    }
    
    // MARK: UICollectionViewDelegate Methods
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // in album mode, see the album's photos
        if(currentMode == .PhotoAlbum) {
            let selectedAlbum = self.albumResultsController.object(at: indexPath)
            // if the selected album has no photos, fetch pics
            if(selectedAlbum.photos?.count == 0) {
                self.fetchImages(indexPath: indexPath)
            }
            setupPhotoFetchedResultsController(selectedAlbum: selectedAlbum)
        // otherwise delete the selected photo
        } else {
            let selectedPhoto = self.photoResultsController?.object(at: indexPath)
            self.deleteImage(image: selectedPhoto!)
        }
    }
}
