//
//  PlaySoundsViewController+Audio.swift
//  PitchPerfect
//
//  Created by Zhang, Angie on 6/23/16.
//  Copyright © 2016 Zhang, Angie. All rights reserved.
//

import UIKit
import AVFoundation

extension PlaySoundsViewController: AVAudioPlayerDelegate {
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled your app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }
    
    //raw values corresponding to sender tag
    enum PlayingState {case Playing, NotPlaying}
    
    // MARK: Audio Functions
    
    func setupAudio() {
        //initialize (recording) audio file
        do {
            try audioFile = AVAudioFile(forReading: recordedAudioURL)
        } catch {
            showAlert(Alerts.AudioFileError, message: String(error))
        }
        print("Audio has been set up")
    }
    
    func playSound(rate rate: Float? = nil, pitch: Float? = nil, echo: Bool? = false, reverb: Bool? = false) {
        // Initialize audio engine components
        audioEngine = AVAudioEngine()
        
        // node for playing audio
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attachNode(audioPlayerNode)
        
        // node for adjusting rate/pitch
        let changedRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changedRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changedRatePitchNode.rate = rate
        }
        audioEngine.attachNode(changedRatePitchNode)
        
        // node for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.MultiEcho1)
        audioEngine.attachNode(echoNode)
        
        // node for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.Cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attachNode(reverbNode)
        
        // connect nodes
        if echo == true && reverb == true {
            connectAudioNodes(audioPlayerNode, changedRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        } else if echo == true {
            connectAudioNodes(audioPlayerNode, changedRatePitchNode, echoNode, audioEngine.outputNode)
        } else if reverb == true {
            connectAudioNodes(audioPlayerNode, changedRatePitchNode, reverbNode, audioEngine.outputNode)
        } else {
            connectAudioNodes(audioPlayerNode, changedRatePitchNode, audioEngine.outputNode)
        }
        
        // schedule to play and start the engine
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, atTime: nil) {
            var delayInSeconds: Double = 0
            if let lastRenderTime = self.audioPlayerNode.lastRenderTime,
                let playerTime = self.audioPlayerNode.playerTimeForNodeTime(lastRenderTime) {
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                }
            }
            
            // schedule a stop timer for when audio finishes playing
            self.stopTimer = NSTimer(timeInterval: delayInSeconds, target: self, selector: #selector(PlaySoundsViewController.stopAudio), userInfo: nil, repeats: false)
            NSRunLoop.mainRunLoop().addTimer(self.stopTimer!, forMode: NSDefaultRunLoopMode)
        }
        
        do {
            try audioEngine.start()
        } catch {
            showAlert(Alerts.AudioEngineError, message: String(error))
            return
        }
        
        // play the recording!
        audioPlayerNode.play()
    }
    
    // MARK: Connect List of Audio Nodes
        
    func connectAudioNodes(nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }
        
    func stopAudio() {
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        
        configureUI(.NotPlaying)
        
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
        
    // MARK: UI functions
        
    func configureUI(playState: PlayingState) {
        switch(playState) {
        case .Playing:
            setPlayButtonEnabled(false)
            stopButton.enabled = true
        case .NotPlaying:
            setPlayButtonEnabled(true)
            stopButton.enabled = false
        }
    }
    
    func setPlayButtonEnabled(enabled: Bool!) {
        snailButton.enabled = enabled
        rabbitButton.enabled = enabled
        chipmunkButton.enabled = enabled
        darthVaderButton.enabled = enabled
        echoButton.enabled = enabled
        reverbButton.enabled = enabled
    }
        
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}
