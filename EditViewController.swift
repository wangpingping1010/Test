//
//  EditViewController.swift
//  Wang_Test
//
//  Created by Admin on 4/30/19.
//  Copyright © 2019 Lokes Motwani. All rights reserved.
//

import UIKit
import Photos
import PryntTrimmerView
import AVKit
import AVFoundation
import MBProgressHUD

protocol EditVCDelegate {
    func setFinalAsset(asset : AVAsset)
}

class EditViewController: UIViewController {
    
    @IBOutlet weak var trimmerView: TrimmerView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var doneBtn: UINavigationItem!
    
    var delegate : EditVCDelegate?
    var videoAsset : AVAsset!
    var player: AVPlayer?
    var playbackTimeCheckerTimer: Timer?
    var trimmerPositionChangedTimer: Timer?
    var startTimeValue : Double!
    var endTimeValue : Double!
    var exportAsset : AVAsset!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        exportAsset = videoAsset
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadAVAsset(asset: exportAsset)
    }
    
    // Load Thumbnail asset
    func loadAVAsset(asset: AVAsset) {
        self.trimmerView.asset = asset
        self.trimmerView.delegate = self
        self.addVideoPlayer(with: asset, playerView: self.playerView)
        
        startTimeValue = 0.0
        endTimeValue = asset.duration.seconds
        if asset.duration.seconds > 10.0 {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    // MARK: - Button Actions
    @IBAction func onDone(_ sender: Any) {
        if isTrimmed() {
            self.cropVideo(isPlay: false)
        } else {
            self.delegate?.setFinalAsset(asset: self.exportAsset)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onPlay(_ sender: Any) {
        if isTrimmed() {
            self.cropVideo(isPlay: true)
        } else {
            if let urlAsset = self.exportAsset as? AVURLAsset {
                self.openAVPlayer(url: urlAsset.url)
            }
        }
    }
    
    // MARK: - Detect Trimmed
    func isTrimmed() -> Bool {
        if startTimeValue != self.trimmerView.startTime?.seconds || endTimeValue != self.trimmerView.endTime?.seconds {
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Open AVPlayer
    func openAVPlayer(url : URL) {
        let objAVPlayerVC = AVPlayerViewController()
        objAVPlayerVC.player = AVPlayer(url: url)
        self.present(objAVPlayerVC, animated: true, completion: {() -> Void in
            objAVPlayerVC.player?.play()
        })
    }
    
    // MARK: - Crop Video
    func cropVideo(isPlay:Bool) {
        let loadingNotification = MBProgressHUD.showAdded(to: view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Cropping..."
        
        let length = Float(exportAsset.duration.value) / Float(exportAsset.duration.timescale)
        let start = self.trimmerView.startTime?.seconds
        let end = self.trimmerView.endTime?.seconds
        
        //Create Video URL
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let finalURL = documentsURL.appendingPathComponent("cuttedvido.mp4")
        //make sure no other file where this one will be saved
        let manager = FileManager()
        do {
            try manager.removeItem(atPath: finalURL.path)
        } catch {
            print("file doesn't exist or couldn't remove file at path")
        }
        //Remove existing file
        _ = try? manager.removeItem(at: finalURL)
        //Exporting
        guard let exportSession = AVAssetExportSession(asset: exportAsset, presetName: AVAssetExportPresetMediumQuality) else {return}
        exportSession.outputURL = finalURL
        exportSession.outputFileType = AVFileType.mp4
        let startTime = CMTime(seconds: Double(start ?? 0), preferredTimescale: 1000)
        let endTime = CMTime(seconds: Double(end ?? Double(length)), preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        exportSession.timeRange = timeRange
        exportSession.exportAsynchronously{
            DispatchQueue.main.async() {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
            switch exportSession.status {
            case .completed:
                let outputURL = exportSession.outputURL!
                let finalAsset = AVAsset.init(url: outputURL)
                self.exportAsset = finalAsset
                if isPlay {
                    self.openAVPlayer(url: outputURL)
                } else {
                    DispatchQueue.main.async() {
                        self.delegate?.setFinalAsset(asset: self.exportAsset)
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            case .failed:
                print("failed")
            case .cancelled:
                print("cancelled")
            default: break
            }
        }
        
    }
    
    // MARK: - Play Video
    private func addVideoPlayer(with asset: AVAsset, playerView: UIView) {
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(EditViewController.itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        let layer: AVPlayerLayer = AVPlayerLayer(player: player)
        layer.backgroundColor = UIColor.white.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerView.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        playerView.layer.addSublayer(layer)
        
        
    }
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        if let startTime = trimmerView.startTime {
            player?.seek(to: startTime)
        }
    }
    func startPlaybackTimeChecker() {
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                                                        selector:
            #selector(EditViewController.onPlaybackTimeChecker), userInfo: nil, repeats: true)
    }
    func stopPlaybackTimeChecker() {
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    @objc func onPlaybackTimeChecker() {
        guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime, let player = player else {
            return
        }
        let playBackTime = player.currentTime()
        trimmerView.seek(to: playBackTime)
        
        if playBackTime >= endTime {
            player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
        }
    }
}

extension EditViewController : TrimmerViewDelegate {
    func didChangePositionBar(_ playerTime: CMTime) {
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        player?.play()
        startPlaybackTimeChecker()
    }
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        stopPlaybackTimeChecker()
        player?.pause()
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
        if duration < 10.0 {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
}
