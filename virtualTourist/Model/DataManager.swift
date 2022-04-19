//
//  DataManager.swift
//  virtualTourist
//
//  Created by Shir Bar Lev on 19/04/2022.
//

import Foundation
import CoreData

class DataManager {
    // MARK: Variables & Constants
    let persistentContainer: NSPersistentContainer
    var backgroundContext: NSManagedObjectContext!
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: Methods
    // init
    init(name: String) {
        persistentContainer = NSPersistentContainer(name: name)
        setUpContexts()
    }
    
    // setUpContexts
    // Responsible for setting up the ManagedObjectContexts to use
    func setUpContexts() {
        backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        backgroundContext.name = "Background Context"
        
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        viewContext.name = "UI Context"
    }
}
