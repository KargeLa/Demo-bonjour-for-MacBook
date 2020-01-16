//
//  ViewController.swift
//  bonjour-demo-mac
//
//  Created by James Zaghini on 8/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, BonjourServerDelegate, BonjourClientDelegate {
    
    //MARK: - Propeties
    
    var informationAboutSoundTrack: Dictionary<String, Any> = [:]
    var trackInformationArray: [InformationAboutTrack] = []
    
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
    
    @IBOutlet private var tableView: NSTableView!
    @IBOutlet private var commandFromRemote: NSTextField!
    @IBOutlet weak var trackImage: NSImageView!
    @IBOutlet weak var trackNameLabel: NSTextField!
    @IBOutlet weak var albumNameLabel: NSTextField!
    @IBOutlet weak var connectedToLabel: NSTextField!
    
    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let trackNumberOne = InformationAboutTrack()
        trackNumberOne.trackName = "trackNumberOne"
        trackNumberOne.albumName = "albumNumberOne"
        trackInformationArray.append(trackNumberOne)
        let trackNumberTwo = InformationAboutTrack()
        trackNumberTwo.trackName = "trackNumberTwo"
        trackNumberTwo.albumName = "albumNumberTwo"
        trackInformationArray.append(trackNumberTwo)
        let trackNumberThird = InformationAboutTrack()
        trackNumberThird.trackName = "trackNumberThird"
        trackNumberThird.albumName = "albumNumberThird"
        trackInformationArray.append(trackNumberThird)
        
        bonjourServer = BonjourServer()
        bonjourClient = BonjourClient()
       
    }
    
    //MARK: Bonjour server delegates
    func didChangeServices() {
        //        tableView.reloadData()
    }
    
    func connected() {
    }
    
    func disconnected() {
    }
    
    //MARK: - For client delegate
    func connectedTo(_ socket: GCDAsyncSocket!) {
        connectedToLabel.stringValue = "Connected to " + (socket.connectedHost ?? "-")
    }
    
    func handleBody(_ body: Data?) {
        guard let body = body else { return }
        if let command = String(data: body, encoding: .utf8) {
             commandFromRemote.stringValue = command
        }
        
        if commandFromRemote.stringValue == "PLAY" {
            trackNameLabel.stringValue = trackInformationArray[0].trackName!
            albumNameLabel.stringValue = trackInformationArray[0].albumName!
            trackImage.image = NSImage(named: "image_1")
        } else {
            trackNameLabel.stringValue = " "
            albumNameLabel.stringValue = " "
            trackImage.image = NSImage(named: "pause")
        }
        
        if let image = trackImage.image,
            let dataToSend = createJson(with: trackNameLabel.stringValue, with: albumNameLabel.stringValue, with: image) {
            bonjourClient.send(dataToSend)
        }    }
    
    //MARK: TableView Delegates
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
    
    private func createJson(with titleSound: String, with titleAlbum: String, with image: NSImage) -> Data? {
        guard let imageData = image.tiffRepresentation else { return Data() }
        let soundPlayer = TrackInformation(titleSound: titleSound, titleAlbum: titleAlbum, imageData: imageData)
        return try? JSONEncoder().encode(soundPlayer)
    }
    
    
    
    //    //MARK: - Private
    //
    //    @IBAction private func sendData(_ sender: NSButton) {
    //        if let data = toSendTextField.stringValue.data(using: String.Encoding.utf8) {
    //            bonjourServer.send(data)
    //        }
    //    }
}
struct TrackInformation: Codable {
    var titleSound: String
    var titleAlbum: String
    var imageData: Data
}
