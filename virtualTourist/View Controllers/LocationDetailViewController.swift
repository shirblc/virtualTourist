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

class LocationDetailViewController: UIViewController {
    var dataManager: DataManager!
    var pin: Pin!
    var albumResultsController: NSFetchedResultsController<PhotoAlbum>!
    var photoResultsController: NSFetchedResultsController<Photo>?
    var currentMode: DetailMode = .PhotoAlbum
    var currentAlbumID: NSManagedObjectID?
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
        self.albumResultsController.delegate = self
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
        let refreshAlbum = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshAlbum))
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let backItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(toggleDetailTypeView))
        
        if(currentMode == .PhotoAlbum) {
            collectionViewToolbar.items = [spaceItem, createItem, spaceItem]
        } else {
            collectionViewToolbar.items = [spaceItem, backItem, spaceItem, refreshAlbum, spaceItem]
        }
    }
    
    // MARK: Album methods
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
            let bgContextPin = self.dataManager.backgroundContext.object(with: self.pin.objectID)
            let photoAlbum = PhotoAlbum(context: self.dataManager.backgroundContext)
            photoAlbum.name = albumName
            photoAlbum.createdAt = Date()
            photoAlbum.location = bgContextPin as? Pin
            
            self.dataManager.saveContext(useViewContext: false) { error in
                self.showErrorAlert(error: error, retryCallback: nil)
            }
        }
    }
    
    // refreshAlbum
    // Deletes all the photos in the album and refetches the album
    @objc func refreshAlbum() {
        if let currentAlbumID = currentAlbumID {
            // Fetch the album's photos
            dataManager.backgroundContext.perform {
                let bgContextAlbum = self.dataManager.backgroundContext.object(with: currentAlbumID)
                let fetchRequest = Photo.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "album == %@", bgContextAlbum)
                
                do {
                    let photos = try self.dataManager.backgroundContext.fetch(fetchRequest)
                    (bgContextAlbum as! PhotoAlbum).flickrCount = photos[0].flickrCount
                    
                    // Delete the photos
                    for photo in photos {
                        self.dataManager.backgroundContext.delete(photo)
                    }
                    
                    self.dataManager.saveContext(useViewContext: false) { error in
                        self.showErrorAlert(error: error, retryCallback: self.refreshAlbum)
                    }
                    
                    // Fetch new photos
                    self.dataManager.viewContext.perform {
                        let albumIndex = self.albumResultsController.indexPath(forObject: self.dataManager.viewContext.object(with: currentAlbumID) as! PhotoAlbum)
                        self.fetchImages(indexPath: albumIndex!)
                    }
                } catch {
                    self.showErrorAlert(error: error, retryCallback: self.refreshAlbum)
                }
            }
        }
    }
    
    // MARK: Image Methods
    // fetchImages
    // Triggers image fetch
    func fetchImages(indexPath: IndexPath) {
        var page: Int
        let selectedAlbum = albumResultsController.object(at: indexPath)
        
        if let numObjects = photoResultsController?.sections?[0].numberOfObjects, numObjects > 0 {
            let firstImage: Photo? = self.photoResultsController?.sections?[0].objects?[0] as? Photo
            page = self.getPageNumber(flickrCount: firstImage!.flickrCount)
        } else {
            let flickrCount = selectedAlbum.flickrCount
            page = self.getPageNumber(flickrCount: flickrCount)
        }
        
        let imageFetcher = ImageFetcher(errorCallback: showErrorAlert(error:retryCallback:), imageSuccessCallback: {
            images in
            self.handleImages(images: images, photoAlbum: selectedAlbum)
        })
        imageFetcher.getImages(page: page, longitude: selectedAlbum.location!.longitude, latitude: selectedAlbum.location!.latitude)
    }
    
    // getPageNumber
    // Generates the page number for the flickr fetch
    func getPageNumber(flickrCount: Double) -> Int {
        var page: Int
        
        if(flickrCount > 0) {
            let pages = Int(ceil(flickrCount / 25))
            page = Int.random(in:0..<pages)
        } else {
            page = 1
        }
        
        return page
    }
    
    // handleImages
    // Adds the fetched images to the store
    func handleImages(images: [ImageData], photoAlbum: PhotoAlbum) {
        dataManager.backgroundContext.perform {
            let bgContextAlbum = self.dataManager.backgroundContext.object(with: photoAlbum.objectID) as! PhotoAlbum
            
            for image in images {
                let photo = Photo(context: self.dataManager.backgroundContext)
                photo.name = image.name
                photo.photo = image.photo
                photo.flickrCount = Double(image.totalCount)
                photo.album = bgContextAlbum
                bgContextAlbum.flickrCount = Double(image.totalCount)
            }
            
            self.dataManager.saveContext(useViewContext: false) { error in
                self.showErrorAlert(error: error, retryCallback: nil)
            }
            
            // reload visible items to replace the placeholders
            DispatchQueue.main.async {
                let visibleItems = self.collectionView.indexPathsForVisibleItems
                self.collectionView.reloadItems(at: visibleItems)
            }
        }
    }
    
    // deleteImage
    // Confirms that the user wishes to delete & deletes the image (if the user chooses to)
    func deleteImage(image: Photo) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Delete Image?", message: "Are you sure you want to delete this image?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.dismiss(animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { _ in
                self.dataManager.viewContext.delete(image)
                self.dataManager.saveContext(useViewContext: true) { error in
                    self.showErrorAlert(error: error, retryCallback: nil)
                }
                self.dismiss(animated: true)
            }))
            self.present(alert, animated: true)
        }
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
    
    // toggleDetailTypeView
    // Switches between album mode and photo mode
    @objc func toggleDetailTypeView() {
        // If we're in album mode, switch to photo
        if(currentMode == .PhotoAlbum) {
            currentMode = .Photo
        // otherwise switch to album
        } else {
            currentMode = .PhotoAlbum
            photoResultsController = nil
        }
        
        DispatchQueue.main.async {
            self.setupToolbar()
            self.collectionView.reloadData()
            let visibleItems = self.collectionView.indexPathsForVisibleItems
            self.collectionView.reloadItems(at: visibleItems)
        }
    }
}
