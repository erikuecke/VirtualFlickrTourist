
# VirtualTourist
Tour the world from the comfort of your couch! You can drop pins on a map and pull up Flickr images associated with that location in a collection view. You can also refresh the collection view, which downloads a new set of photos from Flickr. Locations and images are persisted using Core Data. 

## Approach
Virtual Tourist follows the MVC pattern. The model contains networking code for the Flickr API, as well as the NSManagedObject subclasses for Core Data.

The app has 2 main view controllers:
1. Map View Controller
2. Photos View Controller

### Map View Controller
In the map view, users drag the map to any desired location, and long-press on the map to add a pin to that location. That pin location is then saved to the Core Data managed object context. If the user previously added other pins, all those pins are persisted and load on the map view upon app launch. The user can tap any pin, which presents the Photos View Controller.

### Photos View Controller
In the photos view, users can view a collection view of photos downloaded from Flickr associated with the pin that they tapped in the map view. These photos are saved to Core Data, so that each time the user taps the pin, they do not have to wait for the app to re-download photos from Flickr. However, the user can choose to refresh the collection (by tapping the Refresh Collection) button, at which point the app downloads a fresh set of photos from Flickr. These photos are then saved to Core Data. The user can also tap on any of the photos to delete them. The photos are then removed from both the UI and the Core Data database.

## Usage
Virtual Tourist is written in Swift 3. You can download it and run it in any version of Xcode and Simulator.

## Contributing
1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request.
