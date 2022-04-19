//
//  MapViewController.swift
//  virtualTourist
//
//  Created by Shir Bar Lev on 19/04/2022.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    // MARK: Variables and Constants
    var dataManager: DataManager!
    var pins: [Pin] = []
    @IBOutlet weak var mapView: MKMapView!
    
    var pinsAnnotations: [MKPointAnnotation] {
        var annotations: [MKPointAnnotation] = []
        
        for pin in self.pins {
            let pinAnnotation = MKPointAnnotation()
            pinAnnotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            annotations.append(pinAnnotation)
        }
        
        return annotations
    }
    
    // MARK: Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }

    // MARK: Pins-related Methods
    // loadPins
    // Creates and executes the fetch request for the saved pins
    func loadPins() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: false), NSSortDescriptor(key: "longtitude", ascending: false)]
        
        // if the fetch was successful, add the annotations to the map
        do {
            let pins = try dataManager.viewContext.fetch(fetchRequest)
            self.pins = pins
            self.mapView.addAnnotations(self.pinsAnnotations)
        // otherwise alert the user
        } catch {
            self.showErrorAlert(error: error)
        }
    }
    
    // showErrorAlert
    // Displays an error alert that allows the user to retry fetching the pins
    func showErrorAlert(error: Error) {
        DispatchQueue.main.async {
            let errorAlert = UIAlertController(title: "Error fetching pins", message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                self.dismiss(animated: true)
            }))
            errorAlert.addAction(UIAlertAction(title: "Try again", style: .default, handler: { _ in
                self.loadPins()
            }))
            self.present(errorAlert, animated: true)
        }
    }
}

