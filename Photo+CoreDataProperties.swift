//
//  Photo+CoreDataProperties.swift
//  VirtualFlickrTourist
//
//  Created by Erik Uecke on 8/11/17.
//  Copyright © 2017 Erik Uecke. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var photoData: NSData?
    @NSManaged public var url: String?
    @NSManaged public var pin: Pin?

}
