//
//  ObjectBuildeOperationProtocol.swift
//  DataOperationKit
//
//  Created by Mykhailo Vorontsov on 10/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

/**
 Operations with specified protocol require Onject Builde instance to be injected from OperationManager
 */
public protocol ObjectBuildeOperationProtocol: DataRetrievalOperationProtocol {
  
  var objectBuilder:ObjectBuilder! {get set}
  
}
