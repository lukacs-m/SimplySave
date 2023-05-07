//
//  URL+Extensions.swift
//  
//
//  Created by Martin Lukacs on 03/05/2023.
//

import Foundation

extension URL {
    var fileNameToInt: Int? {
        let fileExtension = self.pathExtension
        let filePath = self.lastPathComponent
        let fileName = filePath.replacingOccurrences(of: fileExtension, with: "")
        return Int(fileName.filter(("0"..."9").contains))
    }
}
