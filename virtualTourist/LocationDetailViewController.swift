//
//  LocationDetailViewController.swift
//  virtualTourist
//
//  Created by Shir Bar Lev on 19/04/2022.
//

import UIKit
import MapKit

let reuseIdentifier = "albumImageCell"

class LocationDetailViewController: UIViewController {
    var dataManager: DataManager!
    var pin: Pin!
    var albums: [PhotoAlbum] = []
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupMap()
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
}
