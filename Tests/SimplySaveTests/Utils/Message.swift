//
//  Message.swift
//  
//
//  Created by Martin Lukacs on 05/05/2023.
//

import Foundation

struct Message: Codable {
    let title: String
    let body: String
}

// Conforms to Equatable so we can compare messages (i.e. message1 == message2)
extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.title == rhs.title && lhs.body == rhs.body
    }
}
