//
//  AudioData.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 28/12/24.
//

import SwiftUI

// Model for JSON decoding
struct AudioData: Codable {
    struct AudioInfo: Codable {
        let comments: [String]
        let dirty: [String]
    }

    struct TextInfo: Codable {
        let comments: [String]
        let dirty: [String]
    }

    struct NumberData: Codable {
        let audio: AudioInfo
        let text: TextInfo
    }

    let numbers: [Int: NumberData]
    let genericComments: [String: [String]]
}
