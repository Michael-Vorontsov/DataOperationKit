//
//  OAuthDataRetrievalOperationProtocol.swift
//  SwiftWeather
//
//  Created by Mykhailo Vorontsov on 08/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

/**
 Operations with specified protocol require key to be injected from OperationManager
 */
public protocol AccessKeyOperationProtocol: NetworkDataRetrievalOperationProtocol {}

