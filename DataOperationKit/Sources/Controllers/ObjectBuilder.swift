//
//  ObjectBuilder.swift
//  SwiftWeather
//
//  Created by Mykhailo Vorontsov on 10/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

public enum BuilderErrors:ErrorType {
  case NoContextAvailable
  case CoreDataError
  case RemoteError(errorInfo:AnyObject)
  case WrongData(dataInfo:[String : AnyObject])
  case IncompleteData
}

/**
 Class represents builder for NSManagedObjects.
 
 Each creation of each managed object determine by specific extensions of builder.
 ManagedObject DataRetrieval operation contains builder with coreDataManager injected in it by OperationManager, and
 specific builder selector to be called determine by specific subclass.
 */
public class ObjectBuilder: NSObject, DataPresenter {
  
  public var coreDataManager: CoreDataManager!
  
  public init(dataManager:CoreDataManager) {
    coreDataManager = dataManager
    super.init()
  }
  
}
