//
//  LibraryMediaManager.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos

class LibraryMediaManager {
    
    weak var v: YPLibraryView?
    var collection: PHAssetCollection?
    internal var fetchResult: PHFetchResult<PHAsset>!
    internal var previousPreheatRect: CGRect = .zero
    internal var imageManager: PHCachingImageManager?
    internal var exportTimer: Timer?
    internal var currentExportSessions: [AVAssetExportSession] = []
    
    func initialize() {
        imageManager = PHCachingImageManager()
        resetCachedAssets()
        
        collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject
    }
    
    func resetCachedAssets() {
        imageManager?.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    func updateCachedAssets(in collectionView: UICollectionView) {
        let size = UIScreen.main.bounds.width/4 * UIScreen.main.scale
        let cellSize = CGSize(width: size, height: size)
        
        var preheatRect = collectionView.bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)
        
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        if delta > collectionView.bounds.height / 3.0 {
            
            var addedIndexPaths: [IndexPath] = []
            var removedIndexPaths: [IndexPath] = []
            
            previousPreheatRect.differenceWith(rect: preheatRect, removedHandler: { removedRect in
                let indexPaths = collectionView.aapl_indexPathsForElementsInRect(removedRect)
                removedIndexPaths += indexPaths
            }, addedHandler: { addedRect in
                let indexPaths = collectionView.aapl_indexPathsForElementsInRect(addedRect)
                addedIndexPaths += indexPaths
            })
            
            let assetsToStartCaching = fetchResult.assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = fetchResult.assetsAtIndexPaths(removedIndexPaths)
            
            imageManager?.startCachingImages(for: assetsToStartCaching,
                                             targetSize: cellSize,
                                             contentMode: .aspectFill,
                                             options: nil)
            imageManager?.stopCachingImages(for: assetsToStopCaching,
                                            targetSize: cellSize,
                                            contentMode: .aspectFill,
                                            options: nil)
            previousPreheatRect = preheatRect
        }
    }
    
    func fetchVideoUrlAndCrop(for videoAsset: PHAsset, cropRect: CGRect, callback: @escaping (URL) -> Void) {
        let videosOptions = PHVideoRequestOptions()
        videosOptions.isNetworkAccessAllowed = true
        videosOptions.deliveryMode = .highQualityFormat
        imageManager?.requestAVAsset(forVideo: videoAsset, options: videosOptions) { asset, _, _ in
            do {
                guard let asset = asset else { print("⚠️ PHCachingImageManager >>> Don't have the asset"); return }
                
                let assetComposition = AVMutableComposition()
                let trackTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
                
                // 1. Inserting audio and video tracks in composition
                
                guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first,
                    let videoCompositionTrack = assetComposition
                        .addMutableTrack(withMediaType: .video,
                                         preferredTrackID: kCMPersistentTrackID_Invalid) else {
                                            print("⚠️ PHCachingImageManager >>> Problems with video track")
                                            return
                                            
                }
                if let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first,
                    let audioCompositionTrack = assetComposition
                        .addMutableTrack(withMediaType: AVMediaType.audio,
                                         preferredTrackID: kCMPersistentTrackID_Invalid) {
                    try audioCompositionTrack.insertTimeRange(trackTimeRange, of: audioTrack, at: CMTime.zero)
                }
                
                try videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: CMTime.zero)
                
                // 2. Create the instructions
                
                let mainInstructions = AVMutableVideoCompositionInstruction()
                mainInstructions.timeRange = trackTimeRange
                
                // 3. Adding the layer instructions. Transforming
                
                let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
                layerInstructions.setTransform(videoTrack.getTransform(cropRect: cropRect), at: CMTime.zero)
                layerInstructions.setOpacity(1.0, at: CMTime.zero)
                mainInstructions.layerInstructions = [layerInstructions]
                
                // 4. Create the main composition and add the instructions
                
                let videoComposition = AVMutableVideoComposition()
                videoComposition.renderSize = cropRect.size
                videoComposition.instructions = [mainInstructions]
                videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
                
                // 5. Configuring export session
                
                let exportSession = AVAssetExportSession(asset: assetComposition,
                                                         presetName: YPConfig.video.compression)
                exportSession?.outputFileType = YPConfig.video.fileType
                exportSession?.shouldOptimizeForNetworkUse = true
                exportSession?.videoComposition = videoComposition
                exportSession?.outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingUniquePathComponent(pathExtension: YPConfig.video.fileType.fileExtension)
                
                // 6. Exporting
                DispatchQueue.main.async {
                    self.exportTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                                            target: self,
                                                            selector: #selector(self.onTickExportTimer),
                                                            userInfo: exportSession,
                                                            repeats: true)
                }
                
                self.currentExportSessions.append(exportSession!)
                exportSession?.exportAsynchronously(completionHandler: {
                    DispatchQueue.main.async {
                        if let url = exportSession?.outputURL, exportSession?.status == .completed {
                            callback(url)
                            if let index = self.currentExportSessions.firstIndex(of:exportSession!) {
                                self.currentExportSessions.remove(at: index)
                            }
                        } else {
                            let error = exportSession?.error
                            print("error exporting video \(String(describing: error))")
                        }
                    }
                })
            } catch let error {
                print("⚠️ PHCachingImageManager >>> \(error)")
            }
        }
    }
    
    @objc func onTickExportTimer(sender: Timer) {
        if let exportSession = sender.userInfo as? AVAssetExportSession {
            if let v = v {
                if exportSession.progress > 0 {
                    v.updateProgress(exportSession.progress)
                }
            }
            
            if exportSession.progress > 0.99 {
                sender.invalidate()
                v?.updateProgress(0)
                self.exportTimer = nil
            }
        }
    }
    
    func forseCancelExporting() {
        for s in self.currentExportSessions {
            s.cancelExport()
        }
    }
    
    func inverseAsset(at index: Int) -> PHAsset {
        let inverseIndex = self.inverseIndex(for: index)
        return fetchResult[inverseIndex]
    }
    
    func inverseIndex(for index: Int) -> Int {
        var inverseIndex = index
        guard let last = fetchResult.lastObject else { return inverseIndex }
        inverseIndex = fetchResult.index(of: last) - index
        
        return inverseIndex
    }
}

extension LibraryMediaManager: AssetProvider {
    var hasFetchResults: Bool { return self.fetchResult != nil }
    
    var currentCollection: PHAssetCollection? { return self.collection }
    
    var fetchCount: Int { return self.fetchResult.count }
    
    var currentFetchResult: PHFetchResult<PHAsset> { return self.fetchResult }
    
    func set(collection: PHAssetCollection?) { self.collection = collection }
    
    func set(libraryView: YPLibraryView) { self.v = libraryView }
    
    func set(fetchResult: PHFetchResult<PHAsset>) { self.fetchResult = fetchResult }
    
    func asset(at index: Int, inverseSorted: Bool) -> PHAsset {
        if inverseSorted {
            return inverseAsset(at: index)
        } else {
            return fetchResult[index]
        }
    }
    
    func collectionIsAllPhotos(_ collection: PHAssetCollection) -> Bool {
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject == collection
    }
    
    func indexPathForAsset(_ asset: PHAsset, isInverseIndexed: Bool) -> IndexPath? {
        var indexPath: IndexPath? = nil
        fetchResult.enumerateObjects { (enumeratedAsset, index, shouldStop) in
            if enumeratedAsset.localIdentifier == asset.localIdentifier {
                indexPath = IndexPath(item: isInverseIndexed ? self.inverseIndex(for: index) : index, section: 0)
                shouldStop.pointee = true
            }
        }
        
        return indexPath
    }
}
