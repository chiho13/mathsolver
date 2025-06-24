//
//  Usage.swift
//  videoeditor
//
//  Created by Anthony Ho on 19/06/2025.
//



import Foundation
import SwiftData


@Model
class Usage: Identifiable {
    @Attribute var id: UUID = UUID() // Unique identifier for the usage record
    var timestamp: Date = Date()       // The time when the transcription occurred
    var duration: Int = 0              // Duration in seconds of the transcription process

    init(timestamp: Date = Date(), duration: Int = 0) {
        self.timestamp = timestamp
        self.duration = duration
    }
}
