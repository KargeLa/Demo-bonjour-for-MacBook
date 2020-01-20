//
//  ViewController.swift
//  bonjour-demo-mac
//
//  Created by James Zaghini on 8/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import Cocoa

struct TrackInformation: Codable {
    var trackName: String
    var albumName: String
    var imageData: Data
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
}

class ViewController: NSViewController {
    
    //MARK: - Propeties
    
    var tracksInformation: [TrackInformation] = []
    private var bonjourServer: BonjourServer! {
        didSet {
            bonjourServer.delegate = self
        }
    }
    private var bonjourClient: BonjourClient! {
        didSet {
            bonjourClient.delegate = self
        }
    }
    
    //MARK: - Outlets
    
    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private weak var commandFromRemote: NSTextField!
    @IBOutlet private weak var trackImage: NSImageView!
    @IBOutlet private weak var trackNameLabel: NSTextField!
    @IBOutlet private weak var albumNameLabel: NSTextField!
    @IBOutlet private weak var connectedToLabel: NSTextField!
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let firstTrack = TrackInformation(trackName: "FirstTrack", albumName: "FitsrAlbum", imageData: (NSImage(named: "image_1")?.tiffRepresentation)! )
        tracksInformation.append(firstTrack)
        
        let secondTrack = TrackInformation(trackName: "SecondTrack", albumName: "SecondAlbum", imageData: (NSImage(named: "image_2")?.tiffRepresentation)! )
        tracksInformation.append(secondTrack)
        
        let thirdTrack = TrackInformation(trackName: "ThirdTrack", albumName: "ThirdAlbum", imageData: (NSImage(named: "image_3")?.tiffRepresentation)! )
        tracksInformation.append(thirdTrack)
        
        
        
        bonjourServer = BonjourServer()
        bonjourClient = BonjourClient()
        
    }
    
    private func createJson(with titleSound: String, with titleAlbum: String, with image: NSImage) -> Data? {
        guard let imageData = image.tiffRepresentation else { return Data() }
        let soundPlayer = TrackInformation(trackName: titleSound, albumName: titleAlbum, imageData: imageData)
        return try? JSONEncoder().encode(soundPlayer)
    }
}

//MARK: - BonjourServerDelegate, BonjourClientDelegate

extension ViewController: BonjourServerDelegate, BonjourClientDelegate {
    func didChangeServices() {
        print("didChangeServices in bonjour demo mac ")
    }
    
    func connected() {
        print("connected in bonjour demo mac ")
    }
    
    func disconnected() {
        print("disconnected in bonjour demo mac ")
    }
    
    func connectedTo(_ socket: GCDAsyncSocket!) {
        connectedToLabel.stringValue = "Connected to " + (socket.connectedHost ?? "-")
    }
    
    func handleBody(_ body: Data?) {
        guard let body = body else { return }
        if let command = String(data: body, encoding: .utf8) {
            commandFromRemote.stringValue = command
        }
        
        if commandFromRemote.stringValue == "PLAY" {
            configOutletsFromModel(trackInformation: tracksInformation[0])
            if let dataToSend = tracksInformation[0].json {
                bonjourClient.send(dataToSend)
            }
        } else {
            let emptyTrack = TrackInformation(trackName: "", albumName: "", imageData: (NSImage(named: "pause")?.tiffRepresentation)!)
            configOutletsFromModel(trackInformation: emptyTrack)
            if let dataToSend = emptyTrack.json {
                bonjourClient.send(dataToSend)
            }
        }
        
    }
    
    private func configOutletsFromModel(trackInformation: TrackInformation) {
        trackNameLabel.stringValue = trackInformation.trackName
        albumNameLabel.stringValue = trackInformation.albumName
        trackImage.image = NSImage(data: trackInformation.imageData)
    }
}

//MARK: - NSTableViewDelegate, NSTableViewDataSource

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in aTableView: NSTableView) -> Int {
        return bonjourServer.devices.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any?{
        var result = ""
        
        let columnIdentifier = tableColumn!.identifier.rawValue
        if columnIdentifier == "bonjour-device" {
            let device = bonjourServer.devices[row]
            result = device.name
        }
        return result
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("notification: \(String(describing: notification.userInfo))")
        
        if !bonjourServer.devices.isEmpty {
            let service = bonjourServer.devices[tableView.selectedRow]
            bonjourServer.connectTo(service)
        }
    }
}
