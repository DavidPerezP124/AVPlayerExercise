//
//  ViewController.swift
//  AVPlayerExercise
//
//  Created by David Perez on 10/23/20.
//

import UIKit
import AVFoundation
/*
 En un nuevo proyecto crea un view controller, en el cual puedas visualizar un reproductor en la parte de arriba, justo debajo un text field y justo a la derecha del text field un botón y al final un text field en la parte de abajo.
 Una vista contenedora para el reproductor.
 Un text field para cargar nuevos url de videos en el reproductor
 Un botón para hacer la carga
 Un text field para registrar ciertos cambios en las propiedades.
 Internamente instala los siguientes observers a través de KVO, y en el TextField imprime los cambios que vayas recibiendo de cada uno.
 AVPlayer.rate
 AVPlayer.timeControlStatus
 AVPlayerItem.status
 AVPlayerItem.duration
 AVPlayerItem.isPlaybackBufferEmpty
 AVPlayerItem.isPlaybackBufferFull
 4:56
 Con esto te darás un idea del flujo que tiene el AVPlayer
 
 
 http://playertest.longtailvideo.com/adaptive/bipbop/gear4/prog_index.m3u8
 */
var initialUrl = "http://playertest.longtailvideo.com/adaptive/bipbop/gear4/prog_index.m3u8"
class PlayerViewController: UIViewController {
    
    //MARK: Stored Properties: &Context
    
    private var playerRateContext = 0
    
    private var playerTimeControlContext = 1
    
    private var itemStatusContext = 2
    
    private var itemDurationContext = 3
    
    private var itemBufferEmptyContext = 4
    
    private var itemBufferFullContext = 5
    
    private var timeObserverToken: Any?
    
    
  
    
    //MARK: Stored Property: String for UILabel
    
    var info : String = ""
    //MARK: Store Property: Map for Keys
    var keyMap = [String:String]()
    //MARK: Computed Properties: AVPlayer, AVPlayerLayer
    
    var playerLayer: AVPlayerLayer?
    
    var player: AVPlayer?
    
    var playerItem: AVPlayerItem?
    //MARK: @IBOutlet: Storyboard views
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var urlText: UITextField!
    @IBOutlet weak var playerData: UILabel!
    
    
    //MARK: ViewDidLoad
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        playerData.text = info
    }
    
    override func viewDidAppear(_ animated: Bool) {
        initialSetup()
        setObservers()
    }
    
    //MARK: Setup
    func initialSetup(){
        
        
        player = AVPlayer()
        setPlayerItem(initialUrl)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = containerView.bounds
        if let playerLayer = playerLayer {
            containerView.layer.addSublayer(playerLayer)
        }
        player?.play()
        urlText.text = initialUrl
        playerData.text = info
    }
    
    func setLabelString(){
        info = ""
        keyMap.forEach { (k,v) in
            info +=  "\(k) : \(v) \n"
        }
        playerData.text = info
    }
    
    func setObservers(){
        // Player Item
        setItemObservers(#keyPath(AVPlayerItem.status), context: &itemStatusContext)
        setItemObservers(#keyPath(AVPlayerItem.duration), context: &itemDurationContext)
        setItemObservers(#keyPath(AVPlayerItem.isPlaybackBufferEmpty), context: &itemBufferEmptyContext)
        setItemObservers(#keyPath(AVPlayerItem.isPlaybackBufferFull), context: &itemBufferFullContext)
        
        // Player
        setPlayerObservers(#keyPath(AVPlayer.rate), context: &playerRateContext)
        setPlayerObservers(#keyPath(AVPlayer.timeControlStatus), context: &playerTimeControlContext)
        setLabelString()
    }
    
    //MARK: Override: ObserveValue
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else {return}
        guard let value = change?[.newKey] else {return}
        handleChanges(keyPath, value: value)
        setLabelString()
    }
    
    func handleChanges(_ keyPath: String, value: Any?){
        
        guard let value = value else {return}
      //  print("keyPath: \(keyPath) : \(value)" )
        switch(keyPath){
        case #keyPath(AVPlayerItem.status):
            
            keyMap[keyPath] = handlePlayerItemStatus(value as! Int)
            
        case #keyPath(AVPlayerItem.duration):
            
            guard let duration = playerItem?.duration else {return}
            
            keyMap[keyPath] = handleDuration(time: duration)
            
        case #keyPath(AVPlayerItem.isPlaybackBufferEmpty):
            
            let keyValue = playerItem?.isPlaybackBufferEmpty
            
            keyMap[keyPath] = keyValue?.description
        
        case #keyPath(AVPlayerItem.isPlaybackBufferFull):
            
            let keyValue = playerItem?.isPlaybackBufferFull
            
            keyMap[keyPath] = keyValue?.description
        
        case #keyPath(AVPlayer.rate):
            
            print(keyPath)
            
            keyMap[keyPath] = "\(value)"
        
        case #keyPath(AVPlayer.timeControlStatus):
            
            keyMap[keyPath] = handlePlayerControlStatus(value as! Int)
        
        default:
            break
        }
    }
    
    func handlePlayerItemStatus(_ status:Int) -> String{
        switch (AVPlayerItem.Status(rawValue: status)) {
        case .failed:
            return "Failed"
        case .none:
            return "None"
        case .readyToPlay:
            return "Ready To Play"
        case .unknown:
            return "Unknown"
        case .some(_):
            return "Undetermined"
        }
    }
    
    func handlePlayerControlStatus(_ status:Int) -> String{
        switch (AVPlayer.TimeControlStatus.init(rawValue: status)) {
        case .none:
            return "None"
        case .paused:
            return "Paused"
        case .playing:
            return "Playing"
        case .waitingToPlayAtSpecifiedRate:
            return "Waiting for rate"
        case .some(_):
            return "Undetermined"
        }
    }
    
    func handleDuration( time: CMTime) -> String {
        let tseconds = Int(time.seconds)
        let hours = tseconds / 3600
        let minutes = tseconds % 3600 / 60
        let seconds = tseconds % 3600 % 60
        
        return "\(hours) hrs : \(minutes) min : \(seconds) sec"
    }
    
    
    @IBAction func loadUrlButton(_ sender: UIButton) {
        setPlayerItem(urlText.text)
    }
    
   
    func setPlayerItem(_ str: String?){

        guard let url = URL(string:str!) else {
            print("Not A Valid URL")
            return
        }
        playerItem = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: playerItem)
        player?.play()
        
        
        addTimeObserver()
        setObservers()
    }
    
    func addTimeObserver(){
        let timeScale = CMTimeScale(NSEC_PER_SEC)
           let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)

           timeObserverToken = player?.addPeriodicTimeObserver(forInterval: time,
                                                             queue: .main) {
               [weak self] time in
            self?.keyMap["time"] = self?.handleDuration(time: time)
            self?.setLabelString()
           }
    }
    
    func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    func removeAllObservers(){
        // Player Item
        removeItemObservers(#keyPath(AVPlayerItem.status), context: &itemStatusContext)
        removeItemObservers(#keyPath(AVPlayerItem.duration), context: &itemDurationContext)
        removeItemObservers(#keyPath(AVPlayerItem.isPlaybackBufferEmpty), context: &itemBufferEmptyContext)
        removeItemObservers(#keyPath(AVPlayerItem.isPlaybackBufferFull), context: &itemBufferFullContext)
        
        // Player
        removePlayerObservers(#keyPath(AVPlayer.rate), context: &playerRateContext)
        removePlayerObservers(#keyPath(AVPlayer.timeControlStatus), context: &playerTimeControlContext)
        setLabelString()
    }
    
    deinit {
        removePeriodicTimeObserver()
        removeAllObservers()
    }
}


extension PlayerViewController {
    func setItemObservers(_ keyPath: String, context: UnsafeMutableRawPointer){
       
        playerItem?.addObserver(self, forKeyPath: keyPath, options: [.old, .new], context: context)
        
    }
    func setPlayerObservers(_ keyPath: String, context: UnsafeMutableRawPointer){
       
        player?.addObserver(self, forKeyPath: keyPath, options: [.old, .new], context: context)
    
    }
    
    func removeItemObservers(_ keyPath: String, context: UnsafeMutableRawPointer){
       
        playerItem?.removeObserver(self, forKeyPath: keyPath,  context: context)
        
    }
    func removePlayerObservers(_ keyPath: String, context: UnsafeMutableRawPointer){
       
        player?.removeObserver(self, forKeyPath: keyPath, context: context)
    
    }
}
