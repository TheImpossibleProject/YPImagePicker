//
//  YPLibrary+LibraryChange.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos

extension YPLibraryVC: PHPhotoLibraryChangeObserver {
    func registerForLibraryChanges() {
        PHPhotoLibrary.shared().register(self)
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            let fetchResult = (self.mediaManager as! LibraryMediaManager).fetchResult!
            let collectionChanges = changeInstance.changeDetails(for: fetchResult)
            if collectionChanges != nil {
                let fetchResultAfterChanges = collectionChanges!.fetchResultAfterChanges
                self.mediaManager.set(fetchResult: fetchResultAfterChanges)
                // We receive photo library update
                // We need to check whether it has assets or no
                let isNotEmpty = fetchResultAfterChanges.count > 0
                guard isNotEmpty else {
                    // if it doesn't - we should close image picker
                    self.delegate?.noPhotosForOptions()
                    return
                }
                // if it has some - we should update our presentation and select the first one
                let indexPath = IndexPath(row: 0, section: 0)
                self.currentlySelectedIndex = indexPath.row
                let asset = self.mediaManager.asset(
                    at: indexPath.row,
                    inverseSorted: self.requiresInverseSorting
                )
                self.changeAsset(asset)
                self.selection.removeAll()
                self.addToSelection(indexPath: indexPath)

                let collectionView = self.v.collectionView!
                if !collectionChanges!.hasIncrementalChanges || collectionChanges!.hasMoves {
                    collectionView.reloadData()
                } else {
                    collectionView.performBatchUpdates({
                        let removedIndexes = collectionChanges!.removedIndexes
                        if (removedIndexes?.count ?? 0) != 0 {
                            collectionView.deleteItems(at: removedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        let insertedIndexes = collectionChanges!.insertedIndexes
                        if (insertedIndexes?.count ?? 0) != 0 {
                            collectionView.insertItems(at: insertedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                    }, completion: { finished in
                        if finished {
                            let changedIndexes = collectionChanges!.changedIndexes
                            if (changedIndexes?.count ?? 0) != 0 {
                                collectionView.reloadItems(at: changedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                            }
                        }
                    })
                }
                (self.mediaManager as! LibraryMediaManager).resetCachedAssets()
            }
        }
    }
}
