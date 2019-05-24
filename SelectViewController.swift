//
//  SelectViewController.swift
//  Wang_Test
//
//  Created by Admin on 4/30/19.
//  Copyright © 2019 Lokes Motwani. All rights reserved.
//

import UIKit
import Hero
import Photos
import AVKit

protocol SelectVCDelegate {
    func gotoEditScene(asset : AVAsset)
}

class SelectViewController: UIViewController {

    @IBOutlet weak var collectionV: UICollectionView!
    
    var photos: PHFetchResult<PHAsset>!
    var delegate: SelectVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Get all videos from Photo Library
        self.getAssetFromPhotoLibrary()
    }
    
    func getAssetFromPhotoLibrary() {
        PHPhotoLibrary.requestAuthorization({status in
            if status == .authorized{
                let options = PHFetchOptions()
                options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: true) ]
                options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
                self.photos = PHAsset.fetchAssets(with: options)
                print(self.photos.count)
                DispatchQueue.main.async {
                    self.collectionV.delegate = self
                    self.collectionV.dataSource = self
                    self.collectionV.reloadData()
                }
            } else {
                // Create Alert
                let alert = UIAlertController(title: "Photo Library", message: "Photo Library access is absolutely necessary to use this app", preferredStyle: .alert)
                
                // Add "OK" Button to alert, pressing it will bring you to the settings app
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }))
                // Show the alert with animation
                self.present(alert, animated: true)
            }
        })
    }
    
    // MARK: - Button Action
    @IBAction func onBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension SelectViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectCollectionViewCell", for: indexPath) as! SelectCollectionViewCell
        let asset = photos!.object(at: indexPath.row)
        let width: CGFloat = (UIScreen.main.bounds.size.width - 70) / 3
        let height: CGFloat = width
        let size = CGSize(width:width, height:height)
        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: PHImageContentMode.aspectFill, options: nil) { (image, userInfo) -> Void in
            cell.thumbCellImgV.image = image
            cell.durationLbl.text = String(format: "%02d:%02d",Int((asset.duration / 60)),Int(asset.duration) % 60)
        }
        return cell
    }
}

extension SelectViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = photos!.object(at: indexPath.row)
        PHImageManager.default().requestAVAsset(forVideo: asset, options: nil, resultHandler: { (asset, audioMix, info) in
            if let urlAsset = asset as? AVURLAsset {
                let localVideoUrl = urlAsset.url
                let localAsset = AVAsset.init(url: localVideoUrl)
                self.dismiss(animated: true, completion: {
                    self.delegate?.gotoEditScene(asset: localAsset)
                })
            } else {
                //Error
                let alert = UIAlertController(title: "", message: "Something went wrong", preferredStyle: .alert)
                let dismiss = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alert.addAction(dismiss)
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
}

extension SelectViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.size.width - 70) / 3
        let height = width
        return CGSize(width: width, height: height)
    }
}
