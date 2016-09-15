//
//  ManagedObjectRetrievalOperationProtocol.swift
//  DataOperationKit
//
//  Created by Mykhailo Vorontsov on 08/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
import CoreData

/**
 Operations with specified protocol require dataManager instance to be injected from OperationManager
 */
public protocol ManagedObjectRetrievalOperationProtocol: DataRetrievalOperationProtocol {
  
  var dataManager:CoreDataManager! {get set}
  
}
