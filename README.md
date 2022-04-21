# Virtual Tourist

## Description

Virtual Tourist allows you to view photos from all around the world by location when you can't travel to view things yourself.

## Requirements

- macOS
- Xcode
- Optional: an iPhone/iPad running iOS/iPadOS 15 or above, if you want to test it on an actual device (rather than the simulator).

The app was tested in the Xcode simulator, running iOS 15.

## Installaton and Usage

1. Download or clone the repo.
2. cd into the project directory.
3. Open virtualTourist.xcodeproj.
4. Add your Flickr API key to the [Image Fetcher](https://github.com/shirblc/virtualTourist/blob/main/virtualTourist/API%20Client/ImageFetcher.swift#L62).
5. Click the build button and use the app on your device / in the built-in simulator.
6. Start travelling the world!

## Contents

The project currently contains two ViewControllers, with two custom classes, and a custom CollectionCellView:

1. **MapViewController** - The root view controller. Contains a map that lets users add pins to it.
2. **LocationDetailViewController** - Contains a map, centred on a pin's location, and a collection view. The collection view displays the albums associated with the pin, and once an album is clicked, it presents the photos in it. Contains two extensions:
    - **CollectionView** - The extension that contains the CollectionView's delegate and data source methods.
    - **FetchedResultsController** - The extension responsible for setting up and subscribing to the NSFetchedResultsControllers.
3. **AlbumViewCell** - A single cell for the UICollectionView in LocationDetailViewController.

The project also contains the following non-view-related files:

1. **ImageFetcher.swift** - The class responsible for fetching the image data and images from flickr.
2. **virtualTourist.xcdatamodeld** - The Data Model for the app.
3. **DataManager.swift** - The class responsible for setting the NSPersistentContainer and its associated contexts up. Also contains helpers for saving the context and for loading the store.
4. **FlickrPhoto.swift** - Models for the flickr API's expected response.

## Known Issues

There are no current issues at the time.
