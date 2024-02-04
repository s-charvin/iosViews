//
//  FlickrPhotosViewController.swift
//  iosViews
//
//  Created by scw on 2024/2/4.
//

import SnapKit
import UIKit

final class GridPhotosViewController: UICollectionViewController {
    // MARK: - Properties

    // GridView 基本元素
    private var dataList: [FlickrSearchResults] = [] // 数据 Model 列表
    private let sectionInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0) // 元素四周间距限制
    private let itemsPerRow: CGFloat = 3 // 每行元素数目限制

    // 测试用的可选元素
    private let flickr = Flickr() // 图片搜索服务示例
    // navigationBar

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewFlowLayout()
        )

        self.collectionView.backgroundColor = .white
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(
            GridPhotoCell.self,
            forCellWithReuseIdentifier: GridPhotoCell.reuseIdentifier
        )
        self.collectionView.register(GridHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GridHeaderView.reuseIdentifier)

      self.collectionView.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(self.navigationBar)
        self.view.addSubview(self.collectionView)

        self.setupViews()
    }

    private func setupViews() {
        self.navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(55)
            make.height.equalTo(44)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.bottom.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    @objc func searchButtonTapped() {
        if let textField = self.navigationBar.topItem?.titleView as? UITextField {
            self.performSearch(with: textField)
        }
    }

    func performSearch(with textField: UITextField) {
        guard
            let text = textField.text,
            !text.isEmpty
        else { return }

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.startAnimating()

        self.flickr.searchFlickr(for: text) { searchResults in
            DispatchQueue.main.async {
                activityIndicator.removeFromSuperview()

                switch searchResults {
                    case let .failure(error):
                        print("Error Searching: \(error)")
                    case let .success(results):
                        print("""
                        Found \(results.searchResults.count) \
                        matching \(results.searchTerm)
                        """)
                        self.dataList.insert(results, at: 0)

                        self.collectionView?.reloadData()
                }
            }
        }

        textField.text = nil
        textField.resignFirstResponder()
    }

    lazy var navigationBar: UINavigationBar = {
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44))
        let navItem = UINavigationItem()

        let searchTextField = UITextField()
        searchTextField.placeholder = "Search    " // 空格用于填充
        searchTextField.returnKeyType = .search
        searchTextField.delegate = self
        navItem.titleView = searchTextField

        let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchButtonTapped))
        navItem.rightBarButtonItem = searchButton
        navBar.setItems([navItem], animated: false)
        navBar.layer.cornerRadius = 10
        navBar.layer.masksToBounds = true
        navBar.layer.shadowColor = UIColor.black.cgColor
        navBar.layer.shadowOffset = CGSize(width: 0, height: 2)
        navBar.layer.shadowRadius = 4
        navBar.layer.shadowOpacity = 0.5
        return navBar
    }()
}

// MARK: - Private

private extension GridPhotosViewController {
    func photo(for indexPath: IndexPath) -> FlickrPhoto {
        return self.dataList[indexPath.section].searchResults[indexPath.row]
    }
}

// MARK: - Text Field Delegate

extension GridPhotosViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.performSearch(with: textField)
        return true
    }
}

// MARK: - UICollectionViewDataSource

extension GridPhotosViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataList.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return self.dataList[section].searchResults.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: GridPhotoCell.reuseIdentifier,
            for: indexPath
        ) as? GridPhotoCell else {
            preconditionFailure("Invalid cell type")
        }

        let flickrPhoto = self.photo(for: indexPath)
        cell.backgroundColor = .white
        cell.imageView.image = flickrPhoto.thumbnail
        return cell
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        switch kind {
            case UICollectionView.elementKindSectionHeader:
                let headerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: "\(GridHeaderView.self)",
                    for: indexPath)

                guard let typedHeaderView = headerView as? GridHeaderView else { return headerView }
                let searchTerm = self.dataList[indexPath.section].searchTerm
                typedHeaderView.setTitle(searchTerm)
                return headerView
            default:
                assert(false, "Invalid element type")
        }
    }
}

// MARK: - Collection View Flow Layout Delegate

extension GridPhotosViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let paddingSpace = self.sectionInsets.left * (self.itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / self.itemsPerRow

        return CGSize(width: widthPerItem, height: widthPerItem)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 50)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return self.sectionInsets
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return self.sectionInsets.left
    }
}
