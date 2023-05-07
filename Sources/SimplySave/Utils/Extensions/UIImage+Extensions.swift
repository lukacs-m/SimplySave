//
//  UIImage+Extensions.swift
//  
//
//  Created by Martin Lukacs on 07/05/2023.
//

import UIKit
import Foundation

extension UIImage {
    func computeDataAndName(with baseName: String = "") -> (name: String, data: Data)? {
        if let data = self.pngData() {
            return (name: "\(baseName).png", data: data)
        } else if let data = self.jpegData(compressionQuality: 1) {
            return (name: "\(baseName).jpg", data: data)
        }
        return nil
    }
}
