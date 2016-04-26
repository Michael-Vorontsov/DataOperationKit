//
//  CoreDataRetrievelOperation.swift
//  eBayWeather
//
//  Created by Mykhailo Vorontsov on 07/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import UIKit

/** 
 Protocol for operation that works with core data managed objects.
 
 Allows Data Retrival Operation Manager, that executing operation to configure dedicated Core Data Manager to work with.
 */
protocol CoreDataRetrievalOperationProtocol: DataRetrievalOperationProtocol {
  
  var coreDataManager:CoreDataManager {get set}
  
}
