//
//  CoreDataManagerTests.swift
//  SwiftWeather
//
//  Created by Mykhailo Vorontsov on 05/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import XCTest
import CoreData
@testable import DataOperationKit


class SampleManagedObject: NSManagedObject {
  
  @NSManaged var sid: NSNumber?
  @NSManaged var userId: NSNumber?
  @NSManaged var title: String?
  @NSManaged var body: String?
  // Insert code here to add functionality to your managed object subclass
  
}

class CoreDataManagerTests: XCTestCase {
  
  func testCustomPersistentStore() {
    let bundle = NSBundle(forClass: CoreDataManagerTests.self)
    let dataManager = CoreDataManager(databaseName: "TestDB", modelName: "TestModel", bundle: bundle)
    
    let persistentStoreCoordinator = dataManager.mainContext.persistentStoreCoordinator!
    XCTAssertNotNil(persistentStoreCoordinator)
    XCTAssertEqual(persistentStoreCoordinator.persistentStores.count, 1)
    let persitentStore  = persistentStoreCoordinator.persistentStores.first;
    XCTAssertEqual(persitentStore?.URL?.lastPathComponent, "TestDB.sqlite")
    XCTAssertNotEqual(CoreDataManager(), dataManager)
  }
  
//  func testSharedManagerStore() {
//    let dataManager = CoreDataManager.sharedManager
//    let persistentStoreCoordinator = dataManager.mainContext.persistentStoreCoordinator!
//    XCTAssertNotNil(persistentStoreCoordinator)
//    XCTAssertEqual(persistentStoreCoordinator.persistentStores.count, 1)
//    
//    let persitentStore  = persistentStoreCoordinator.persistentStores.first;
//    
//    XCTAssertEqual(persitentStore?.URL?.lastPathComponent, "SwiftWeatherDB.sqlite")
//    
//    XCTAssertEqual(dataManager, CoreDataManager.sharedManager)
//    XCTAssertNotEqual(CoreDataManager(), CoreDataManager.sharedManager)
//  }
  
  func testDefaultPersistentStore() {
//    let dataManager = CoreDataManager(databaseName: "TestDB")
    let bundle = NSBundle(forClass: CoreDataManagerTests.self)
    let dataManager = CoreDataManager(databaseName: "TestDB", modelName: "TestModel", bundle: bundle)

    let persistentStoreCoordinator = dataManager.mainContext.persistentStoreCoordinator!
    XCTAssertNotNil(persistentStoreCoordinator)
    XCTAssertEqual(persistentStoreCoordinator.persistentStores.count, 1)
    
    let persitentStore  = persistentStoreCoordinator.persistentStores.first;
    
    XCTAssertEqual(persitentStore?.URL?.lastPathComponent, "TestDB.sqlite")
  }
  
  func testPersistentContext() {
//    let dataManager = CoreDataManager(databaseName: "TestDB")
    let bundle = NSBundle(forClass: CoreDataManagerTests.self)
    let dataManager = CoreDataManager(databaseName: "TestDB", modelName: "TestModel", bundle: bundle)

    let persistentContext = dataManager.mainContext.parentContext!
    XCTAssertNotNil(persistentContext)
    XCTAssertEqual(persistentContext.concurrencyType, NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
    XCTAssertNil(persistentContext.parentContext)
  }
  
  func testMainContext() {
//    let dataManager = CoreDataManager(databaseName: "TestDB")
    let bundle = NSBundle(forClass: CoreDataManagerTests.self)
    let dataManager = CoreDataManager(databaseName: "TestDB", modelName: "TestModel", bundle: bundle)

    XCTAssertNotNil(dataManager);
    XCTAssertNotNil(dataManager.mainContext)
    XCTAssertEqual(dataManager.mainContext, dataManager.mainContext)
    XCTAssertEqual(dataManager.mainContext.concurrencyType, NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
    let persistentContext = dataManager.mainContext.parentContext!
    XCTAssertNotNil(persistentContext)
  }
  
  func testDataContext() {
//    let dataManager = CoreDataManager(databaseName: "TestDB")
    
    let bundle = NSBundle(forClass: CoreDataManagerTests.self)
    let dataManager = CoreDataManager(databaseName: "TestDB", modelName: "TestModel", bundle: bundle)

    XCTAssertNotNil(dataManager);
    XCTAssertNotNil(dataManager.dataContext)
    XCTAssertEqual(dataManager.dataContext, dataManager.dataContext)
    XCTAssertEqual(dataManager.dataContext.concurrencyType, NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
    XCTAssertEqual(dataManager.dataContext.parentContext, dataManager.mainContext)
  }
  
  func testBackContextFunc() {
//    let dataManager = CoreDataManager(databaseName: "TestDB", )
    let bundle = NSBundle(forClass: CoreDataManagerTests.self)
    let dataManager = CoreDataManager(databaseName: "TestDB", modelName: "TestModel", bundle: bundle)

    XCTAssertNotNil(dataManager);
    let backContext1 = dataManager.backContext()
    XCTAssertNotNil(backContext1)
    XCTAssertNotEqual(backContext1, dataManager.dataContext)
    XCTAssertEqual(backContext1.concurrencyType, NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
    XCTAssertEqual(backContext1.parentContext, dataManager.mainContext)
    XCTAssertNotEqual(backContext1, dataManager.backContext())
  }
  
  func testDBWipe() {
    
    let fileManager = NSFileManager.defaultManager()
    
    let url = NSFileManager.applicationDocumentsDirectory.URLByAppendingPathComponent("TestDB-Wipe.sqlite")
    let filePath = url.relativePath!
    XCTAssertNotNil(filePath)
    XCTAssertFalse(fileManager.fileExistsAtPath(filePath))

    let bundle = NSBundle(forClass: CoreDataManagerTests.self)
    let dataManager = CoreDataManager(databaseName: "TestDB-Wipe", modelName: "TestModel", bundle: bundle)

    XCTAssertNotNil(dataManager);
    
    let sampleObject = NSEntityDescription.insertNewObjectForEntityForName("SampleObject", inManagedObjectContext: dataManager.mainContext) as? SampleManagedObject
    
    XCTAssertNotNil(sampleObject)
    
    sampleObject?.title = "Some Title"
    dataManager.mainContext.save(recursive: true)
    XCTAssertTrue(fileManager.fileExistsAtPath(filePath))
    
    let fetchRequest = NSFetchRequest(entityName: "SampleObject")
    let results = try? dataManager.mainContext.executeFetchRequest(fetchRequest)

    XCTAssertNotNil(results)
    XCTAssertEqual(results?.count, 1)
    XCTAssertTrue(fileManager.fileExistsAtPath(filePath))
    XCTAssertEqual(dataManager.mainContext.registeredObjects.count, 1)
    
    dataManager.wipeDatabase()
    
    XCTAssertEqual(dataManager.mainContext.registeredObjects.count, 0)
    XCTAssertTrue(fileManager.fileExistsAtPath(filePath))
    let wipedResults = try? dataManager.mainContext.executeFetchRequest(fetchRequest)
    XCTAssertNotNil(wipedResults)
    XCTAssertEqual(wipedResults?.count, 0)
    
    NSEntityDescription.insertNewObjectForEntityForName("SampleObject", inManagedObjectContext: dataManager.mainContext)
    dataManager.mainContext.save(recursive: true)

    dataManager.wipeDatabase(reloadStores:false)
    XCTAssertFalse(fileManager.fileExistsAtPath(filePath))
  }
  
}
