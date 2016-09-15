//
//  CoreDataManager.swift
//  DataOperationKit
//
//  Created by Mykhailo Vorontsov on 18/03/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import UIKit
import CoreData

enum CoreDataError : Int {
  case Unknown = 1000
  case StoreCoordinatorCreation
  case SavingChanges
}

private let Consts = (
  defaultDBName : "",
  defaultModel : "",
  errorDomain : "error.dataoperationkit.database"
)

/**
 Protocol for any object designated to work with core data.
 */
public protocol DataPresenter:NSObjectProtocol {
  var coreDataManager: CoreDataManager! {get set}
}

/**
 Class responsible for storing and retriving data from local database
 */
public class CoreDataManager: NSObject {
  
  /**
   CoreDataManager error domain
   */
  static let errorDomain = Consts.errorDomain
  
  /**
   Shared instance of Data Manager be accessible in different part of application
   */
  static let sharedManager = CoreDataManager()
  
  /**
   Init CoreDataManager with specified database name
   */
  public init(databaseName aDatabaseName: String = Consts.defaultDBName, modelName: String = Consts.defaultModel, bundle:NSBundle? = nil) {
    databaseName = aDatabaseName
    dataModel = modelName
    super.init()
    modelBundle = bundle
  }
  
  /**
   NSManagedObject context dedicated for UI operations working on main thread
   */
  public lazy var mainContext: NSManagedObjectContext = {
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    managedObjectContext.parentContext = self.persistentContext
    return managedObjectContext
  }()
  
  /**
   NSManagedObject context dedicated for synchronous data parsing operations working on background thread
   */
  public lazy var dataContext: NSManagedObjectContext = {
    return self.backContext()
  }()
  
  /**
   Creating separate background context to above main context to perfrom backgound data operations
   */
  public func backContext() -> NSManagedObjectContext {
    let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    managedObjectContext.parentContext = self.mainContext
    return managedObjectContext
  }
  
  /**
   Delete sqlite database file from disk
   */
  public func wipeDatabase(reloadStores reloadStores:Bool = true) {
    do {
      for store in persistentStoreCoordinator.persistentStores {
        let storeURL = store.URL!
        try persistentStoreCoordinator.removePersistentStore(store)
        _ = try NSFileManager.defaultManager().removeItemAtURL(storeURL)
      }
      
      persistentContext.reset()
      mainContext.reset()
      if true == reloadStores {
        let url = NSFileManager.applicationDocumentsDirectory.URLByAppendingPathComponent("\(self.databaseName).sqlite")
        try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
      }
    } catch {
      print("Error occured while trying to wipe persistent store")
      assert(false)
    }
  }

  // MARK: - Private methods
  
  private let databaseName: String
  private let dataModel: String
  private lazy var modelBundle: NSBundle! =  {
   return NSBundle.mainBundle()
  }()
  
  public private(set) lazy var managedObjectModel: NSManagedObjectModel = {
    let modelURL = self.modelBundle.URLForResource(self.dataModel, withExtension: "momd")!
    let model = NSManagedObjectModel(contentsOfURL: modelURL)
    return model!
  }()
  
  public private(set)  lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
    let url = NSFileManager.applicationDocumentsDirectory.URLByAppendingPathComponent("\(self.databaseName).sqlite")
    var failureReason = "There was an error creating or loading the application's saved data."
    do {
      try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
    } catch {
      // Report any error we got.
      var dict = [String: AnyObject]()
      dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
      dict[NSLocalizedFailureReasonErrorKey] = failureReason
      dict[NSUnderlyingErrorKey] = error as NSError
      let wrappedError = NSError(domain: CoreDataManager.errorDomain, code: CoreDataError.StoreCoordinatorCreation.rawValue, userInfo: dict)
      print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
      
      // If error - try to delete database and create it from scratch
      do {
        try NSFileManager.defaultManager().removeItemAtURL(url!)
        try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
      } catch {
        print("Error occured while trying recreate database")
        abort();
      }
    }
    return coordinator
  }()
  
  /**
   Private context working in background thread with persisten store directly
   */
  private lazy var persistentContext: NSManagedObjectContext = {
    let coordinator = self.persistentStoreCoordinator
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
  }()
}
