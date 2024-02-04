//
//  ViewController.swift
//  iosViews
//
//  Created by scw on 2024/2/4.
//

import SnapKit
import UIKit

class AppViewController: UIViewController {
    var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.view.addSubview(self.flickrPhotosViewController.view)

        self.flickrPhotosViewController.view.snp.makeConstraints { make in
            make.height.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    lazy var flickrPhotosViewController: GridPhotosWithInteractViewController = {
        let layout = UICollectionViewLayout()
        let flickrPhotosViewController = GridPhotosWithInteractViewController(collectionViewLayout: layout)
        return flickrPhotosViewController
    }()
}
