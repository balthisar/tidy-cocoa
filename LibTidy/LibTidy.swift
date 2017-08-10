//
//  LibTidy.swift
//  LibTidy
//
//  Created by Jim Derry on 8/10/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import Foundation
import CLibTidy

public func tidyLibraryVersion() -> String {
    let result = String( cString: CLibTidy.tidyLibraryVersion() )
    return result
}

