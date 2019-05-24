//
//  HomeViewController.swift
//  Wang_Test
//
//  Created by Admin on 4/30/19.
//  Copyright © 2019 Lokes Motwani. All rights reserved.
//

import UIKit
import Hero
import Photos
import AVKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var thumbImgV: UIImageView!
    @IBOutlet weak var selectBtn: UIButton!
    @IBOutlet weak var uploadBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var novideoLbl: UILabel!
    
    var selectedAsset : AVAsset!
    var finalAsset : AVAsset?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Custom UI
        selectBtn.layer.cornerRadius = selectBtn.frame.height / 2
        selectBtn.layer.borderWidth = 2.0
        selectBtn.layer.borderColor = UIColor.cyan.cgColor
        
        uploadBtn.layer.cornerRadius = selectBtn.frame.height / 2
        uploadBtn.layer.borderWidth = 2.0
        uploadBtn.layer.borderColor = UIColor.cyan.cgColor
        
        if finalAsset != nil {
            self.loadAsset()
        } else {
            self.playBtn.isHidden = true
            self.novideoLbl.isHidden = false
        }
    }
    
    // MARK: - Load Asset
    func loadAsset() {
        self.thumbImgV.image = self.generateThumbnail()
        self.playBtn.isHidden = false
        self.novideoLbl.isHidden = true
    }
    
    // MARK: - Generate Thumbnail
    func generateThumbnail() -> UIImage? {
        do {
            let imgGenerator = AVAssetImageGenerator(asset: self.finalAsset!)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Button Actions
    @IBAction func onSelectVideo(_ sender: Any) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "goSelectScene", sender: self)
        }
    }
    
    @IBAction func onUploadVideo(_ sender: Any) {
        //Proceed uploading with finalAsset here
        print("Upload button clicked")
    }
    
    @IBAction func onPlayVideo(_ sender: Any) {
        if let urlAsset = self.finalAsset as? AVURLAsset {
            let objAVPlayerVC = AVPlayerViewController()
            objAVPlayerVC.player = AVPlayer(url: urlAsset.url)
            self.present(objAVPlayerVC, animated: true, completion: {() -> Void in
                objAVPlayerVC.player?.play()
            })
        }
    }
    
    // MARK: - Prepare
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goSelectScene" {
            let selectVC = segue.destination as! SelectViewController
            selectVC.delegate = self
        } else if segue.identifier == "goEditScene" {
            let editVC = segue.destination as! EditViewController
            editVC.videoAsset = selectedAsset
            editVC.delegate = self
        }
    }
}

extension HomeViewController : SelectVCDelegate {
    func gotoEditScene(asset: AVAsset) {
        self.selectedAsset = asset
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "goEditScene", sender: self)
        }
    }
}

extension HomeViewController : EditVCDelegate {
    func setFinalAsset(asset: AVAsset) {
        self.finalAsset = asset
        self.loadAsset()
    }
}
