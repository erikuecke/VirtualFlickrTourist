//
//  MapLocationsViewController.swift
//  VirtualFlickrTourist
//
//  Created by Erik Uecke on 8/9/17.
//  Copyright © 2017 Erik Uecke. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData


class MapLocationsViewController: UIViewController {
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var editLabel: UILabel!
    
    var coordinate: CLLocationCoordinate2D?
    
    var droppedPin : Pin!
    var isEditPin = false
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>?{
        didSet{
            //Whenever the frc changes, we execute the search and
            fetchedResultsController?.delegate = self
            executeSearch()
            loadTheMap()
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configMap()
        configureFetchResultsController()
    }
    
    
    @IBAction func editPressed(_ sender: Any) {
        
        if !isEditPin{
            UIView.animate(withDuration: 0.2, animations: {
                self.mapView.frame.origin.y -= self.editLabel.frame.height
                self.editLabel.frame.origin.y -= self.editLabel.frame.height
                self.isEditPin = true
                self.editButton.title = "Done"
            })
            
        }else{
            UIView.animate(withDuration: 0.2, animations: {
                self.mapView.frame.origin.y += self.editLabel.frame.height
                self.editLabel.frame.origin.y += self.editLabel.frame.height
                self.isEditPin = false
                self.editButton.title = "Edit"
            })
        }
    }
}

//MARK: MapLocationsViewController: (MKMapViewDelegate)

extension MapLocationsViewController: MKMapViewDelegate{
    
    func loadTheMap(){
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        if (self.fetchedResultsController?.fetchedObjects?.count)! > 0{
            
            var annotations = [MKPointAnnotation]()
            for pin in (self.fetchedResultsController?.fetchedObjects)! {
                
                let newPin = pin as! Pin
                let lat = CLLocationDegrees(newPin.latitude)
                let long = CLLocationDegrees(newPin.longitude)
                
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                

                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                
                annotations.append(annotation)
                
                self.mapView.addAnnotations(annotations)
            }
        }
    }
    
    
    func getPinSelected(latitude: Double, longitude: Double) -> Pin {
        var pin: Pin?
        let pins = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        pins.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true),
                                NSSortDescriptor(key: "longitude", ascending: false)]
        
        let pred = NSPredicate(format: "latitude = %@ AND longitude = %@", argumentArray: [latitude, longitude])
        pins.predicate = pred
        
        
        // Create FetchedResultsController
        let fc = NSFetchedResultsController(fetchRequest: pins, managedObjectContext:self.delegate.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fc.performFetch()
            if((fc.fetchedObjects?.count)! > 0 ){
                pin = fc.fetchedObjects?[0] as? Pin
            }
            
        } catch let e as NSError {
            print("Error while trying to perform a search: \n\(e)\n\(String(describing: fetchedResultsController))")
        }
        
        return pin!
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "photoAlbum" {
            
            if let controller = segue.destination as? PhotosViewController {
                
                let pin = getPinSelected(latitude: (self.coordinate?.latitude)!, longitude: (self.coordinate?.longitude)!)
                
                // Create a fetchrequest
                let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
                fr.sortDescriptors = [NSSortDescriptor(key: "url", ascending: false)]
                
                // Create the FetchedResultsController
                let pred = NSPredicate(format: "pin = %@", argumentArray: [pin])
                fr.predicate = pred
                
                let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext:self.delegate.stack.context, sectionNameKeyPath: nil, cacheName: nil)
                
                controller.pin = pin
                controller.fetchedResultsController = fc
                
            }
        }
    }
    
    //Get the center location coordinate
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let region = mapView.region
        let coordinate = ["latitude": region.center.latitude,
                          "longitude": region.center.longitude,
                          "latitudeDelta": region.span.latitudeDelta,
                          "longitudeDelta" : region.span.longitudeDelta ]
        
        UserDefaults.standard.set(coordinate, forKey: "coordinate")
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        
        var pin: Pin?
        
        let coordinate = view.annotation?.coordinate
        let pins = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        pins.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true),
                                NSSortDescriptor(key: "longitude", ascending: false)]
        
        let pred = NSPredicate(format: "latitude = %@ AND longitude = %@", argumentArray: [coordinate?.latitude, coordinate?.longitude])
        pins.predicate = pred
        
        
        // Create FetchedResultsController
        let fc = NSFetchedResultsController(fetchRequest: pins, managedObjectContext:fetchedResultsController!.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fc.performFetch()
            if((fc.fetchedObjects?.count)! > 0 ){
                pin = fc.fetchedObjects?[0] as? Pin
            }
            
        } catch let e as NSError {
            print("Error while trying to perform a search: \n\(e)\n\(String(describing: fetchedResultsController))")
            return
        }
        
        
        if isEditPin {
            self.mapView.removeAnnotation(view.annotation!)
            fetchedResultsController!.managedObjectContext.delete(pin!)
            self.delegate.stack.save()
        }else{
            self.mapView.deselectAnnotation(view.annotation, animated: true)
            self.coordinate = view.annotation?.coordinate
            self.performSegue(withIdentifier: "photoAlbum", sender: self)
        }
    }
    
}


// MARK: MapLocationsViewController: (UIGestureRecognizerDelegate)

extension MapLocationsViewController: UIGestureRecognizerDelegate {
    
    func configMap(){
        
        mapView.delegate = self
        
        // Set Region
        if let coordinate = UserDefaults.standard.dictionary(forKey: "coordinate") {
            
            let location = CLLocationCoordinate2D(
                latitude: (coordinate["latitude"] as? Double)!,
                longitude: (coordinate["longitude"] as? Double)!
            )
            
            let span = MKCoordinateSpanMake(
                (coordinate["latitudeDelta"] as? Double)!,
                (coordinate["longitudeDelta"] as? Double)!
            )
            
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
        
        
        //Add Gesture Recognizer
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        lpgr.minimumPressDuration = 0.9
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        mapView.addGestureRecognizer(lpgr)
        
    }
    
    
    func handleLongPress(_ gestureReconizer: UILongPressGestureRecognizer) {
        
        if !isEditPin{
            // coordinates of a point the user touched on the map
            let location = gestureReconizer.location(in: self.mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            switch gestureReconizer.state {
            case .began:
                // create a pin
                self.droppedPin = Pin(latitude: coordinate.latitude, longitude: coordinate.longitude, context: (fetchedResultsController?.managedObjectContext)!)
                self.delegate.stack.save()
                
            default:
                return
                
            }
        }
    }
}

// MARK: MapLocationsViewController: (NSFetchedResultsControllerDelegate)
extension MapLocationsViewController: NSFetchedResultsControllerDelegate {
    
    func configureFetchResultsController(){
        // Get the stack
        let stack = delegate.stack
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true),
                              NSSortDescriptor(key: "longitude", ascending: false)]
        
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        DispatchQueue.main.async{
            switch(type) {
            case .insert:
                
                let pinCoordinate = controller.object(at: newIndexPath!) as! Pin
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pinCoordinate.latitude, longitude: pinCoordinate.longitude)
                
                self.mapView.addAnnotation(annotation)
                self.mapView.deselectAnnotation(annotation, animated: false)
            case .delete:
                let pinCoordinate = anObject as! Pin
                let coordinate = CLLocationCoordinate2D(latitude: pinCoordinate.latitude, longitude: pinCoordinate.longitude)
            default:
                break
            }
        }
    }
}

extension MapLocationsViewController {
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(String(describing: fetchedResultsController))")
            }
        }
    }
}
