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
    @IBOutlet weak var collectionViewToolbar: UIToolbar!
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupMap()
        self.setupToolbar()
        self.setupAlbumFetchedResultsController()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
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
    
    // setupToolbar
    // Sets up the bottom toolbar
    func setupToolbar() {
        let createItem = UIBarButtonItem(title: "New Album", style: .plain, target: self, action: #selector(addAlbum))
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let backItem = UIBarButtonItem(title: "Back to Albums", style: .plain, target: self, action: #selector(returnToAlbumView))
        
        if(currentMode == .PhotoAlbum) {
            collectionViewToolbar.items = [spaceItem, createItem, spaceItem]
        } else {
            collectionViewToolbar.items = [spaceItem, backItem, spaceItem]
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
    
    // addAlbum
    // Shows the alert for adding an album
    @objc func addAlbum() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Create Album", message: "Enter name for the album", preferredStyle: .alert)
            alert.addTextField()
            alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { _ in
                let albumName = alert.textFields?[0].text
                self.createAlbum(albumName: albumName)
                self.dismiss(animated: true)
            }))
            self.present(alert, animated: true)
        }
    }
    
    // createAlbum
    // Creates a new album with the given name in Core Data
    func createAlbum(albumName: String?) {
        dataManager.backgroundContext.perform {
            let photoAlbum = PhotoAlbum(context: self.dataManager.backgroundContext)
            photoAlbum.name = albumName
            photoAlbum.createdAt = Date()
            
            self.dataManager.saveContext(useViewContext: false) { error in
                self.showErrorAlert(error: error, retryCallback: nil)
            }
        }
    }
    
    // returnToAlbumView
    // Switches back to the album view
    @objc func returnToAlbumView() {
        self.currentMode = .PhotoAlbum
        self.photoResultsController = nil
    }
}
