//
//  LocationDetailViewController+FetchedResultsController.swift
//  virtualTourist
//
//  Created by Shir Bar Lev on 20/04/2022.
//

import Foundation
import CoreData

extension LocationDetailViewController: NSFetchedResultsControllerDelegate {
    // MARK: Setup Methods
    // setupAlbumFetchedResultsController
    // Sets up the fetched results controller
    func setupAlbumFetchedResultsController() {
        let albumRequest: NSFetchRequest<PhotoAlbum> = PhotoAlbum.fetchRequest()
        albumRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true), NSSortDescriptor(key: "createdAt", ascending: false)]
        albumRequest.predicate = NSPredicate(format: "location == %@", self.pin)
        
        self.albumResultsController = NSFetchedResultsController(fetchRequest: albumRequest, managedObjectContext: self.dataManager.viewContext, sectionNameKeyPath: nil, cacheName: "albumsForLocation\(pin.latitude)\(pin.longitude)")
        
        performAlbumRequest()
    }
    
    // performAlbumRequest
    // Performs the results controller's initial fetch
    func performAlbumRequest() {
        do {
            try self.albumResultsController.performFetch()
        } catch {
            showErrorAlert(error: error, retryCallback: performAlbumRequest)
        }
    }
    
    // setupPhotoFetchedResultsController
    // Sets up the fetch results controller for photos
    func setupPhotoFetchedResultsController(selectedAlbum: PhotoAlbum) {
        let photoRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        photoRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
        photoRequest.predicate = NSPredicate(format: "album == %@", selectedAlbum)
        
        self.photoResultsController = NSFetchedResultsController(fetchRequest: photoRequest, managedObjectContext: self.dataManager.viewContext, sectionNameKeyPath: nil, cacheName: "photosForAlbum\(selectedAlbum.name!)")
        self.photoResultsController?.delegate = self
        
        self.performPhotoRequest()
    }
    
    // performPhotoRequest
    // Performs the photo's FetchedResultsController's fetch
    func performPhotoRequest() {
        guard let photoResultsController = photoResultsController else { return }
        
        do {
            try photoResultsController.performFetch()
            
            // if the photos have been fetched, set the mode to photo
            if let _ = photoResultsController.fetchedObjects {
                self.currentMode = .Photo
                self.collectionView.reloadData()
                self.setupToolbar()
            }
        } catch {
            showErrorAlert(error: error, retryCallback: performPhotoRequest)
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate Methods
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView.insertItems(at: [(indexPath ?? newIndexPath)!])
            
            // if we're in album mode, it means we added an album, so run the image fetch
            if currentMode == .PhotoAlbum {
                let selectedAlbum = controller.object(at: (indexPath ?? newIndexPath)!) as? PhotoAlbum
                let imageFetcher = ImageFetcher(errorCallback: showErrorAlert(error:retryCallback:), imageSuccessCallback: {
                    images in
                    self.handleImages(images: images, photoAlbum: selectedAlbum!)
                })
                imageFetcher.getImages(page: selectedAlbum?.location?.albums?.count ?? 1, longitude: (selectedAlbum?.location!.longitude)!, latitude: (selectedAlbum?.location!.latitude)!)
            }
        case .delete:
            collectionView.deleteItems(at: [(indexPath ?? newIndexPath)!])
        case .move:
            collectionView.moveItem(at: indexPath!, to: newIndexPath!)
        case .update:
            collectionView.reloadItems(at: [(indexPath ?? newIndexPath)!])
        @unknown default:
            collectionView.reloadData()
        }
    }
}
