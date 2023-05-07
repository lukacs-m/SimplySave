//
//  String+Extensions.swift
//  
//
//  Created by Martin Lukacs on 03/05/2023.
//

import Foundation

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    var removeSlashesAtBeginning: String {
        var newString = self.deletingPrefix("/")
        while newString.first == "/" {
            newString = newString.deletingPrefix("/")
        }

        return newString
    }
}
