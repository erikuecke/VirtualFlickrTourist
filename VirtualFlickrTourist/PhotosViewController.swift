//
//  PhotosViewController.swift
//  VirtualFlickrTourist
//
//  Created by Erik Uecke on 8/9/17.
//  Copyright © 2017 Erik Uecke. All rights reserved.
//


import Foundation
import UIKit
import MapKit
import CoreData


class PhotosViewController: CDCollectionViewController {
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImageLabel: UILabel!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var pin: Pin?
    var selectedPhotos = [Photo]()
    var isSelectCell: Bool = false {
        didSet {
            isSelectCell ? self.newCollectionButton.setTitle("Remove Selected Pictures", for: .normal) : self.newCollectionButton.setTitle( "New Collection", for: .normal)
        }
    }
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noImageLabel.isHidden = true
        
        configureMap()
        configureCollectionView()
        
        guard let album = pin?.photos else {
            print("no exite photos")
            return
        }
        
        if album.count == 0 {
            newCollectionButton.isEnabled = false
            downloadImages()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        delegate.stack.save()
    }
    
    
    @IBAction func newCollectionButtonPressed(_ sender: Any) {
        
        // delete existing photos
        if !isSelectCell {
            noImageLabel.isHidden = true
            newCollectionButton.isEnabled = false
            for photo in fetchedResultsController?.fetchedObjects as! [Photo] {
                fetchedResultsController!.managedObjectContext.delete(photo)
                
            }
            delegate.stack.save()
            downloadImages()
        }else{
            isSelectCell = false
            for photo in selectedPhotos{
                fetchedResultsController!.managedObjectContext.delete(photo)
            }
            selectedPhotos.removeAll()
            delegate.stack.save()
        }
    }
    
    
    
    func configureCollectionView(){
        
        self.isSelectCell = false
        
        self.collectionView?.allowsMultipleSelection = true
        self.collectionView?.selectItem(at: nil, animated: false, scrollPosition: UICollectionViewScrollPosition())
        
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        self.flowLayout.minimumInteritemSpacing = 0
        self.flowLayout.minimumLineSpacing = space
        self.flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func configureMap(){
        
        mapView.isScrollEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.isZoomEnabled = false
        
        let location = CLLocationCoordinate2D(
            latitude: (self.pin?.latitude)!,
            longitude: (self.pin?.longitude)!
        )
        
        let region = MKCoordinateRegionMakeWithDistance(location, 9000, 9000)
        mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        self.mapView.addAnnotation(annotation)
    }
    
    
    
    func downloadImages(){
        
        
        FlickrClient.sharedInstance().getPhotosByLocation(latitude: (self.pin?.latitude)!, longitude: (self.pin?.longitude)!, completionHandlerForGetPhotosByLocation: { (result, error) in
            
            if let error = error{
                print("Something is wrong with download: \(error.description)")
            }else{
                let stack = self.delegate.stack
                if (result?.count)! > 0 {
                    
                    stack.performBackgroundBatchOperation({ (workerContext) in
                        for photoFlickr in result! {
                            guard let imageURLString = photoFlickr[FlickrClient.FlickrResponseKeys.MediumURL] as? String else {
                                return
                            }
                            
                            DispatchQueue.main.async {
                                _ = Photo(photoData: nil, photoUrl: imageURLString, pin: self.pin!, context: stack.context)
                            }
                            
                            
                        }
                        stack.save()
                    })
                    
                    DispatchQueue.main.async {
                        self.newCollectionButton.isEnabled = true
                    }
                    
                }else{
                    self.noImageLabel.isHidden = false
                    self.newCollectionButton.isEnabled = false
                }
            }
        })
        
    }
}

// MARK: - PhotosViewController (Collection Data Source, UICollectionViewDelegate)
extension PhotosViewController: UICollectionViewDelegate {
    
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if !self.isSelectCell {
            self.isSelectCell = true
        }
        
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        self.selectedPhotos.append(photo)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        if let index = self.selectedPhotos.index(of: photo) {
            self.selectedPhotos.remove(at: index)
            print(" Cantidad Select: \(selectedPhotos.count)")
            if self.selectedPhotos.count == 0 {
                self.isSelectCell = false
            }
        }
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCell", for: indexPath) as! PhotosCollectionViewCell
        
        
        
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        
        
        // Configure the cell
        cell.imageView.autoresizingMask = [.flexibleBottomMargin, .flexibleHeight, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth]
        cell.imageView.contentMode = .scaleAspectFill
        
        
        
        if let photoData = photo.photoData as Data? {
            
            cell.imageView.image = UIImage(data: photoData)
            cell.indicator.stopAnimating()
            cell.indicator.isHidden = true
            
        } else {
            
            cell.imageView.image = UIImage(named: "placeholder")
            cell.indicator.isHidden = false
            cell.indicator.startAnimating()
            
            
            
            FlickrClient.downloadImage(imagePath: photo.url!) { (data, error) in
                if let error = error{
                    print("Something is wrong with download: \(error.description)")
                }else{
                    
                    DispatchQueue.main.async {
                        photo.photoData = data as NSData?
                        self.delegate.stack.save()
                    }
                }
            }
        }
        return cell
        
    }
}
