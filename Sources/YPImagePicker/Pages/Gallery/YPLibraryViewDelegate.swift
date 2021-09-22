//
//  YPLibraryViewDelegate.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import Foundation

@objc
public protocol YPLibraryViewDelegate: AnyObject {
    func libraryViewStartedLoading()
    func libraryViewFinishedLoading()
    func libraryViewDidToggleMultipleSelection(enabled: Bool)
    func noPhotosForOptions()
}
