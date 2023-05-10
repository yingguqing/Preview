//
//  CatalogReader.swift
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Bartosz Janda
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import CoreUI

enum AssetsCatalogError: Error {
    case FileDoesntExists
    case CannotOpenAssetsCatalog
}

struct AssetsCatalog {
    // MARK: Properties
    let filePath: String
    let catalog: CUICatalog

    /**
     Returns all image sets from assets catalog.

     - returns: List of image sets.
     */
    var imageSets: [ImageSet] {
        let array = self.catalog.allImageNames()
        var swiftArray = [ImageSet]()
        for string in array {
            swiftArray.append(imageSet(withName: String(string)))
        }        
        return swiftArray
    }

    // MARK: Initialization
    init(path: String) throws {
        let fp = (path as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: fp) else {
            throw AssetsCatalogError.FileDoesntExists
        }

        let url = NSURL(fileURLWithPath: fp)
        self.filePath = fp

        do {
            self.catalog = try CUICatalog(url: url as URL)
        } catch {
            throw AssetsCatalogError.CannotOpenAssetsCatalog
        }
    }

    // MARK: Methods
    /**
     Return image set with given name.

     - parameter name: Name of image set.

     - returns: Image set with given name.
     */
    func imageSet(withName name: String) -> ImageSet {
        let images = self.catalog.images(withName: name)
        var swiftArray = [CUINamedImage]()
        for item in images {
            if let image = item as? CUINamedImage {
                swiftArray.append(image)
            }
        }
        return ImageSet(name: name, namedImages: swiftArray)
    }
}

extension AssetsCatalog {
    func performOperation(operation: Operation) throws {
        try operation.read(catalg: self)
    }

    func performOperations(operations: [Operation]) throws {
        let compundOperation = CompoundOperation(operations: operations)
        try performOperation(operation: compundOperation)
    }
}
