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
    
    // returnToAlbumView
    // Switches back to the album view
    @objc func returnToAlbumView() {
        self.currentMode = .PhotoAlbum
        self.photoResultsController = nil
        self.setupToolbar()
        self.collectionView.reloadData()
    }
}
