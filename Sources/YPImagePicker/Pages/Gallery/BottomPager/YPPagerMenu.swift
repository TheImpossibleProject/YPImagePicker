//
//  YPPagerMenu.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 24/01/2018.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Stevia

final class YPPagerMenu: UIView {
    
    var didSetConstraints = false
    var menuItems = [YPMenuItem]()
    
    convenience init() {
        self.init(frame: .zero)
        backgroundColor = .clear
        clipsToBounds = true
    }
    
    var separators = [UIView]()
    
    func setUpMenuItemsConstraints() {
        let menuItemWidth: CGFloat = UIScreen.main.bounds.width / CGFloat(menuItems.count)
        var previousMenuItem: YPMenuItem?
        for m in menuItems {
            
            subviews(
                m
            )
            
            m.fillVertically().width(menuItemWidth)
            if let pm = previousMenuItem {
                pm-0-m
            } else {
                |m
            }
            
            layout(0,
                   m
            )
            
            previousMenuItem = m
            m.height(44)
        }
        
        if #available(iOS 10, *) {
            let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
            blurView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(blurView)
            sendSubviewToBack(blurView)
            NSLayoutConstraint.activate([
                blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
                blurView.topAnchor.constraint(equalTo: topAnchor),
                blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
                ]
            )
        }
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        if !didSetConstraints {
            setUpMenuItemsConstraints()
        }
        didSetConstraints = true
    }
    
    func refreshMenuItems() {
        didSetConstraints = false
        updateConstraints()
    }
}
