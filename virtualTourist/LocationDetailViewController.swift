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

class LocationDetailViewController: UIViewController {
    var dataManager: DataManager!
    var pin: Pin!
    var albumResultsController: NSFetchedResultsController<PhotoAlbum>!
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
