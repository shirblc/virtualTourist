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
    
    // loadStore
    // Loads the persistent store
    func loadStore(successHandler: (() -> Void)?, errorHandler: ((Error) -> Void)?) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                errorHandler?(error!)
                return
            }
            
            successHandler?()
            self.setUpContexts()
        }
    }
    
    // saveContext
    // Saves the given context
    func saveContext (useViewContext: Bool, errorHandler: @escaping (Error) -> Void) {
        // if the user chose to use the view context, use it. Otherwise use the background context
        let context = useViewContext ? self.viewContext : self.backgroundContext!
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                DispatchQueue.main.async {
                    errorHandler(error)
                }
            }
        }
    }
    
}
