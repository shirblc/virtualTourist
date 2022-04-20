//
//  LocationDetailViewController+FetchedResultsController.swift
//  virtualTourist
//
//  Created by Shir Bar Lev on 20/04/2022.
//

import Foundation
import CoreData

extension LocationDetailViewController {
    // MARK: Setup Methods
    // setupAlbumFetchedResultsController
    // Sets up the fetched results controller
    func setupAlbumFetchedResultsController() {
        let albumRequest: NSFetchRequest<PhotoAlbum> = PhotoAlbum.fetchRequest()
        albumRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false), NSSortDescriptor(key: "createdAt", ascending: false)]
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
        
        self.performAlbumRequest()
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
            }
        } catch {
            showErrorAlert(error: error, retryCallback: performPhotoRequest)
        }
    }
}
