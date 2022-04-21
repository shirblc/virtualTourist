//
//  FlickrPhoto.swift
//  virtualTourist
//
//  Created by Shir Bar Lev on 20/04/2022.
//

import Foundation

struct FlickrPhoto: Codable {
    var id: String
    var owner: String
    var secret: String
    var server: String
    var farm: Int
    var title: String
    var ispublic: Int
    var isfriend: Int
    var isfamily: Int
}

struct FlickrRequestData: Codable {
    var page: Int
    var pages: String
    var perpage: Int
    var total: String
    var photo: [FlickrPhoto]
}

struct GetImagesResponse: Codable {
    var photos: FlickrRequestData
    var stat: String
}
