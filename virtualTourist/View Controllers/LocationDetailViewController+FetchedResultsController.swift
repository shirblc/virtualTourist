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
        
        performRequest(controller: self.albumResultsController, successCallback: nil)
    }
    
    // setupPhotoFetchedResultsController
    // Sets up the fetch results controller for photos
    func setupPhotoFetchedResultsController(selectedAlbum: PhotoAlbum) {
        let photoRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        photoRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
        photoRequest.predicate = NSPredicate(format: "album == %@", selectedAlbum)
        
        self.photoResultsController = NSFetchedResultsController(fetchRequest: photoRequest, managedObjectContext: self.dataManager.viewContext, sectionNameKeyPath: nil, cacheName: "photosForAlbum\(selectedAlbum.name!)")
        self.photoResultsController?.delegate = self
        
        guard let photoResultsController = photoResultsController else { return }
        
        performRequest(controller: photoResultsController) {
            // if the photos have been fetched, set the mode to photo
            if let _ = photoResultsController.fetchedObjects {
                self.toggleDetailTypeView()
            }
        }
    }
    
    // performRequest
    // Performs a FetchedResultsController's fetch request
    func performRequest<T: NSManagedObject>(controller: NSFetchedResultsController<T>, successCallback: (() -> Void)?) {
        do {
            try controller.performFetch()
            successCallback?()
        } catch {
            showErrorAlert(error: error) {
                self.performRequest(controller: controller, successCallback: successCallback)
            }
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate Methods
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView.insertItems(at: [(indexPath ?? newIndexPath)!])
            
            // if we're in album mode, it means we added an album, so run the image fetch
            if currentMode == .PhotoAlbum {
                self.fetchImages(indexPath: (indexPath ?? newIndexPath)!)
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
