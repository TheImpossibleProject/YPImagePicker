//
//  YPBottomPagerView.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 24/01/2018.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Stevia

final class YPBottomPagerView: UIView {
    
    var header = YPPagerMenu()
    var scrollView = UIScrollView()
    
    convenience init() {
        self.init(frame: .zero)
        backgroundColor = .clear
        
        subviews(
            scrollView,
            header
        )
        
        if #available(iOS 11, *) {
            NSLayoutConstraint.activate([
                header.topAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -44)
            ])
        }
        
        scrollView.fillContainer()
        
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: leadingAnchor),
            header.trailingAnchor.constraint(equalTo: trailingAnchor),
            header.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        header.heightConstraint?.constant = YPConfig.hidesBottomBar ? 0 : 44
        
        clipsToBounds = false
        setupScrollView()
    }

    private func setupScrollView() {
        scrollView.clipsToBounds = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.scrollsToTop = false
        scrollView.bounces = false
    }
}
