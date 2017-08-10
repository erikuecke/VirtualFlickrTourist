//
//  FlickrClient.swift
//  VirtualFlickrTourist
//
//  Created by Erik Uecke on 8/9/17.
//  Copyright © 2017 Erik Uecke. All rights reserved.
//

import Foundation



class FlickrClient: NSObject {
    
    // MARK: Properties
    
    // shared session
    var session = URLSession.shared
    
    // MARK: Shared Instance
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    // MARK: GET
    
    func taskForGETMethod(_ parameters: [String : AnyObject], completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        /* 2/3. Build the URL, Configure the request */
        let method = flickrURLFromParameters(parameters)
        let request = NSMutableURLRequest(url: method)
        
        /* 4. Make the request */
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(String(describing: error))")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    //MARK: given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: [String:AnyObject]! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult as AnyObject, nil)
    }
    
    // MARK: Helper for Creating a URL from Parameters
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Flickr.APIScheme
        components.host = Flickr.APIHost
        components.path = Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    
    private func bboxString(latitude: Double, longitude: Double ) -> String {
        
        let minimumLon = max(longitude - Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    
    
    // MARK: Get photod by location
    func getPhotosByLocation(latitude: Double, longitude: Double,  completionHandlerForGetPhotosByLocation: @escaping (_ result: [[String: AnyObject]]?, _ error: NSError?) -> Void) {
        
        let methodParameters = [
            FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
            FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey,
            FlickrParameterKeys.BoundingBox: bboxString(latitude: latitude, longitude: longitude),
            FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
            FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
            FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
            FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback,
            FlickrParameterKeys.PerPage: FlickrParameterValues.PerPage
        ]
        
        let _ = taskForGETMethod(methodParameters as [String : AnyObject]) { (result, error) in
            
            if let errorMessage = error {
                completionHandlerForGetPhotosByLocation(nil,errorMessage)
                
            }else{
                func sendError(error: String) {
                    let userInfo = [NSLocalizedDescriptionKey : error]
                    completionHandlerForGetPhotosByLocation(nil,NSError(domain: "getPhotoByLocation", code: 1, userInfo: userInfo))
                }
                
                guard let dictionary = result as? [String: Any] else {
                    sendError(error: "Cannot Parse Dictionary")
                    return
                }
                
                /* GUARD: Did Flickr return an error (stat != ok)? */
                guard let stat = dictionary[FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
                    sendError(error: "Flickr API returned an error. See error code and message in \(dictionary)")
                    return
                }
                
                /* GUARD: Is "photos" key in our result? */
                guard let photosDictionary = dictionary[FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    sendError(error: "Cannot find keys '\(FlickrResponseKeys.Photos)' in \(dictionary)")
                    return
                }
                
                /* GUARD: Is "pages" key in the photosDictionary? */
                guard let totalPages = photosDictionary[FlickrResponseKeys.Pages] as? Int else {
                    sendError(error: "Cannot find key \(FlickrResponseKeys.Pages) in \(photosDictionary)")
                    return
                }
                
                // pick a random page!
                let pageLimit = min(totalPages, Flickr.MaximumNumberOfPages)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                
                self.displayImageFromFlickrBySearch(methodParameters as [String : AnyObject], withPageNumber: randomPage, completionHandlerForImageFromFlickrBySearch: completionHandlerForGetPhotosByLocation)
            }
            
        }
    }
    
    func displayImageFromFlickrBySearch(_ methodParameters: [String: AnyObject], withPageNumber: Int,  completionHandlerForImageFromFlickrBySearch: @escaping (_ result: [[String: AnyObject]]?, _ error: NSError?) -> Void) {
        
        // add the page to the method's parameters
        var methodParametersWithPageNumber = methodParameters
        methodParametersWithPageNumber[FlickrParameterKeys.Page] = withPageNumber as AnyObject?
        
        let _ = taskForGETMethod(methodParametersWithPageNumber as [String : AnyObject]) { (result, error) in
            
            if let errorMessage = error {
                completionHandlerForImageFromFlickrBySearch(nil,errorMessage)
                
            }else{
                func sendError(error: String) {
                    let userInfo = [NSLocalizedDescriptionKey : error]
                    completionHandlerForImageFromFlickrBySearch(nil,NSError(domain: "getPhotoByLocation", code: 1, userInfo: userInfo))
                }
                
                guard let dictionary = result as? [String: Any] else {
                    sendError(error: "Cannot Parse Dictionary")
                    return
                }
                
                /* GUARD: Did Flickr return an error (stat != ok)? */
                guard let stat = dictionary[FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
                    sendError(error: "Flickr API returned an error. See error code and message in \(dictionary)")
                    return
                }
                
                /* GUARD: Is "photos" key in our result? */
                guard let photosDictionary = dictionary[FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    sendError(error: "Cannot find keys '\(FlickrResponseKeys.Photos)' in \(dictionary)")
                    return
                }
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    sendError(error: "Cannot find key '\(FlickrResponseKeys.Photo)' in \(photosDictionary)")
                    return
                }
                
                completionHandlerForImageFromFlickrBySearch(photosArray,nil)
                
            }
        }
    }
    
    
    // MARK: Utilities
    
    static func downloadImage( imagePath:String, completionHandler: @escaping (_ imageData: Data?, _ errorString: String?) -> Void){
        
        let session = URLSession.shared
        let imgURL = NSURL(string: imagePath)
        let request: NSURLRequest = NSURLRequest(url: imgURL! as URL)
        
        let task = session.dataTask(with: request as URLRequest) {data, response, downloadError in
            
            if downloadError != nil {
                completionHandler(nil, "Could not download image \(imagePath)")
            } else {
                
                completionHandler(data, nil)
            }
        }
        
        task.resume()
    }
}
