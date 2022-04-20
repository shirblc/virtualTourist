//
//  LocationDetailViewController.swift
//  virtualTourist
//
//  Created by Shir Bar Lev on 19/04/2022.
//

import UIKit
import MapKit
import CoreData

let reuseIdentifier = "albumImageCell"

enum DetailMode: String {
    case PhotoAlbum = "PhotoAlbum"
    case Photo = "Photo"
}

class LocationDetailViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    var dataManager: DataManager!
    var pin: Pin!
    var albumResultsController: NSFetchedResultsController<PhotoAlbum>!
    var photoResultsController: NSFetchedResultsController<Photo>?
    var currentMode: DetailMode = .PhotoAlbum
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupMap()
        self.setupAlbumFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.albumResultsController = nil
    }
    
    // MARK: Setup Methods
    // setupMap
    // Centres the map on the pin's location and adds the relevant annotation
    func setupMap() {
        let locationCoordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let locationSpan = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(0.5), longitudeDelta: CLLocationDegrees(0.5))

        DispatchQueue.main.async {
            self.mapView.setRegion(MKCoordinateRegion(center: locationCoordinate, span: locationSpan), animated: true)
            let annotation = MKPointAnnotation()
            annotation.coordinate.longitude = self.pin.longitude
            annotation.coordinate.latitude = self.pin.latitude
            self.mapView.addAnnotation(annotation)
        }
    }
    
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
    
    // MARK: UICollectionViewDataSource Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.albumResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let albumAtIndex = self.albumResultsController.object(at: indexPath)
        
        let viewCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumViewCell
        viewCell.albumLabel.text = albumAtIndex.name
        // randomly select an image from the set to display
        let randomNumber = Int.random(in:0..<(albumAtIndex.photos?.count ?? 0))
        let photosArray = albumAtIndex.photos?.allObjects as! [Photo]
        if let selectedPhoto = photosArray[randomNumber].photo {
            viewCell.albumImage.image = UIImage(data: selectedPhoto)
        }
        
        return viewCell
    }
    
    // MARK: UICollectionViewDataSource Methods
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return self.currentMode == .PhotoAlbum ? true : false
    }
    
    // MARK: Utilities
    // showErrorAlert
    // Displays an error alert that allows the user to optionally retry
    func showErrorAlert(error: Error, retryCallback: (() -> Void)?) {
        DispatchQueue.main.async {
            let errorAlert = UIAlertController(title: "Error Performing Request", message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                self.dismiss(animated: true)
            }))
            errorAlert.addAction(UIAlertAction(title: "Try again", style: .default, handler: { _ in
                retryCallback?()
            }))
            self.present(errorAlert, animated: true)
        }
    }
}
