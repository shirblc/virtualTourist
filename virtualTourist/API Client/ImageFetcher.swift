//
//  ImageFetcher.swift
//  virtualTourist
//
//  Created by Shir Bar Lev on 20/04/2022.
//

import Foundation

struct ImageData {
    var name: String
    var photo: Data
}

struct HTTPError: Error {
    var statusCode: Int
    var description: String
    var localizedDescription: String
}

typealias ErrorCallback = (Error, (() -> Void)?) -> Void

class ImageFetcher {
    // MARK: Variables & Constants
    var images: [ImageData] = []
    var errorCallback: ErrorCallback
    var imageCallback: ([ImageData]) -> Void
    let apiBase = "https://www.flickr.com/services/rest/"
    let perPage = 25
    let urlSession = URLSession.shared
    
    // Init
    init(errorCallback: @escaping ErrorCallback, imageSuccessCallback: @escaping ([ImageData]) -> Void) {
        self.errorCallback = errorCallback
        self.imageCallback = imageSuccessCallback
    }
    
    // MARK: Image fetching
    // getImages
    // Triggers the images fetch
    func getImages(page: Int, longitude: Double, latitude: Double) {
        let url = self.getImagesRequestURL(page: page, longitude: longitude, latitude: latitude)
        
        if let url = url {
            self.executeNetworkRequest(url: url, successCallback: decodeImagesData(requestData:), errorCallback: self.errorCallback)
        }
    }
    
    // getImagesRequestURL
    // Generates the URL for the GET photos request
    private func getImagesRequestURL(page: Int, longitude: Double, latitude: Double) -> URL? {
        var requestUrl = URLComponents(string: apiBase)
        requestUrl?.queryItems = [
            URLQueryItem(name: "method", value: "flickr.photos.search"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "accuracy", value: "8"),
            URLQueryItem(name: "privacy_filter", value: "1"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "bbox", value: "\(longitude-5),\(latitude-5),\(longitude+5), \(latitude+5)"),
            URLQueryItem(name: "api_key", value: "")
        ]
        
        return requestUrl?.url
    }
    
    // decodeImagesData
    // Decodes the response from flickr and triggers the fetch for each photo in the response
    private func decodeImagesData(requestData: Data) {
        do {
            let photosData = try JSONDecoder().decode(GetImagesResponse.self, from: requestData)
            
            // loop over the images and fetch each image
            for imageData in photosData.photos.photo {
                self.fetchImage(imageData: imageData)
            }
        } catch {
            self.errorCallback(error, nil)
        }
    }
    
    // fetchImage
    // Fetches a single image from Flickr
    private func fetchImage(imageData: FlickrPhoto) {
        // Compile the URL as per https://www.flickr.com/services/api/misc.urls.html
        let imgUrlStr = "https://live.staticflickr.com/\(imageData.server)/\(imageData.id)_\(imageData.secret).jpg"
        let imgUrl = URL(string: imgUrlStr)
        
        // If the URL compiled, make the request
        if let imgUrl = imgUrl {
            self.executeNetworkRequest(url: imgUrl, successCallback: { data in
                let img = ImageData(name: imageData.title, photo: data)
                self.images.append(img)
                
                // if this is the final image, call the callback
                if(self.images.count == self.perPage) {
                    self.imageCallback(self.images)
                }
            }, errorCallback: self.errorCallback)
        }
    }
    
    // MARK: Utils
    // executeNetworkRequest
    // Executes a network request
    private func executeNetworkRequest(url: URL, successCallback: @escaping (Data) -> Void, errorCallback: @escaping ErrorCallback) {
        let dataTask = urlSession.dataTask(with: url) { data, response, error in
            guard let response = response, error == nil else {
                errorCallback(error!, nil)
                return
            }
            
            guard (200...399).contains((response as? HTTPURLResponse)!.statusCode) else {
                let err = self.generateError(requestData: data, statusCode: (response as? HTTPURLResponse)!.statusCode)
                errorCallback(err, nil)
                return
            }
            
            if let data = data {
                successCallback(data)
            }
        }
        dataTask.resume()
    }
    
    // generateError
    // Generates the error from the HTTP Error message
    private func generateError(requestData: Data?, statusCode: Int) -> HTTPError {
        var errorData: [String: Any]?
        var errorString: String = ""
        
        // Try getting the error message from the request data
        if let requestData = requestData {
            errorData = try? JSONSerialization.jsonObject(with: requestData) as? [String: Any]
            errorString = errorData?["message"] as? String ?? "There was a \(statusCode) error making the request to the server"
        } else {
            errorString = "There was a \(statusCode) error making the request to the server"
        }
        
        return HTTPError(statusCode: statusCode, description: errorString, localizedDescription: errorString)
    }
}
