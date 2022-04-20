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
    @IBOutlet var longPressGestureRecogniser: UILongPressGestureRecognizer!
    
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
        self.loadPins()
        self.setUpLongTouchRecogniser()
    }
    
    // prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // if the destination is the detail view controller, set the relevant variables
        if(segue.identifier == "viewDetailSegue") {
            let destination = segue.destination as! LocationDetailViewController
            // set the data manager property
            destination.dataManager = self.dataManager
            
            // get the index of the selected pin
            let pinIndex = self.pins.firstIndex(where: { pin in
                return pin.longitude == (sender as! MKAnnotationView).annotation?.coordinate.longitude && pin.latitude == (sender as! MKAnnotationView).annotation?.coordinate.latitude
            })
            
            // pass it to the detail VC
            if let pinIndex = pinIndex {
                destination.pin = self.pins[pinIndex]
            }
        }
    }

    // MARK: Pins-related Methods
    // loadPins
    // Creates and executes the fetch request for the saved pins
    func loadPins() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: false), NSSortDescriptor(key: "longitude", ascending: false)]
        
        // if the fetch was successful, add the annotations to the map
        do {
            let pins = try dataManager.viewContext.fetch(fetchRequest)
            self.pins = pins
            self.mapView.addAnnotations(self.pinsAnnotations)
        // otherwise alert the user
        } catch {
            self.showErrorAlert(error: error) {
                self.loadPins()
            }
        }
    }
    
    // addAnnotation
    // Adds an annotation to the map and the store
    @IBAction func addAnnotation(_ sender: Any) {
        let recogniser = sender as! UILongPressGestureRecognizer
        let touchLocation = recogniser.location(in: self.mapView)
        let locationCoords = self.mapView.convert(touchLocation, toCoordinateFrom: self.mapView)
        
        // create the pin in the view context since we need to use it in the view
        let pin = Pin(context: self.dataManager.viewContext)
        pin.latitude = locationCoords.latitude
        pin.longitude = locationCoords.longitude
        
        // add the annotation to the map view
        DispatchQueue.main.async {
            self.pins.append(pin)
            self.mapView.addAnnotation(self.pinsAnnotations.last!)
        }
        
        // save the context
        self.dataManager.viewContext.perform {
            self.dataManager.saveContext(useViewContext: true) {
                error in
                self.showErrorAlert(error: error, retryCallback: nil)
            }
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
    
    // setUpLongTouchRecogniser
    // Sets up the long touch recogniser
    func setUpLongTouchRecogniser() {
        self.longPressGestureRecogniser.minimumPressDuration = 1.5
        self.longPressGestureRecogniser.numberOfTouchesRequired = 1
    }
    
    // MARK: MKMapViewDelegate Methods
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // pass the selected pin to the prepare(forSegue) method
        performSegue(withIdentifier: "viewDetailSegue", sender: view)
    }
}

