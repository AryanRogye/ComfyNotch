//
//  MessagesManager+Audio.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/29/25.
//

import Cocoa
import ObjectiveC.runtime
import AVFoundation

extension MessagesManager {
    /// Function will play audio which is set in the
    ///     Settings model, I have to resarch where the audio
    ///     files are stored, and trigger that for the messages
    internal func playAudio() {
        /// Make Sure we are not playing audio already
        if self.isPlayingAudio { return }
        self.isPlayingAudio = true
        defer { self.isPlayingAudio = false }
        
        /// TODO: Impliment
    }
}
