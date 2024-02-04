//
//  GridPhotosWithInteractViewController.swift
//  iosViews
//
//  Created by scw on 2024/2/4.
//

import SnapKit
import UIKit

final class GridPhotosWithInteractViewController: UICollectionViewController {
    // MARK: - Properties

    // GridView 基本元素
    private var dataList: [FlickrSearchResults] = [] // 数据 Model 列表
    private let sectionInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0) // 元素四周间距限制
    private let itemsPerRow: CGFloat = 3 // 每行元素数目限制

    var selectedPhotos: [FlickrPhoto] = []
    let shareTextLabel = UILabel()

    var isSharing = false {
        didSet {
            collectionView.allowsMultipleSelection = self.isSharing

            collectionView.selectItem(at: nil, animated: true, scrollPosition: [])
            self.selectedPhotos.removeAll()

            guard let shareButton = navigationItem.rightBarButtonItems?.first else {
                return
            }

            guard self.isSharing else {
                navigationItem.setRightBarButton(shareButton, animated: true)
                return
            }

            if self.largePhotoIndexPath != nil {
                self.largePhotoIndexPath = nil
            }

            self.updateSharedPhotoCountLabel()

            let sharingItem = UIBarButtonItem(customView: shareTextLabel)
            let items: [UIBarButtonItem] = [
                shareButton,
                sharingItem,
            ]

            navigationItem.setRightBarButtonItems(items, animated: true)
        }
    }

    var largePhotoIndexPath: IndexPath? {
        didSet {
            var indexPaths: [IndexPath] = []
            if let largePhotoIndexPath = largePhotoIndexPath {
                indexPaths.append(largePhotoIndexPath)
            }

            if let oldValue = oldValue {
                indexPaths.append(oldValue)
            }

            collectionView.performBatchUpdates(
                {
                    self.collectionView.reloadItems(at: indexPaths) }, // 完成图片放大操作
                completion: { _ in
                    if let largePhotoIndexPath = self.largePhotoIndexPath {
                        self.collectionView.scrollToItem( // 滑动到图片位置
                            at: largePhotoIndexPath,
                            at: .centeredVertically,
                            animated: true)
                    }
                })
        }
    }

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
        self.collectionView.dragDelegate = self
        self.collectionView.dropDelegate = self
        self.collectionView.register(
            GridPhotoWithInteractCell.self,
            forCellWithReuseIdentifier: GridPhotoWithInteractCell.reuseIdentifier
        )
        self.collectionView.register(GridHeaderWithInteractView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GridHeaderWithInteractView.reuseIdentifier)

        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.dragInteractionEnabled = true
        self.collectionView.allowsMultipleSelection = true

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

// MARK: - Tools func

extension GridPhotosWithInteractViewController {
    func photo(for indexPath: IndexPath) -> FlickrPhoto {
        return self.dataList[indexPath.section].searchResults[indexPath.row]
    }

    func removePhoto(at indexPath: IndexPath) {
        self.dataList[indexPath.section].searchResults.remove(at: indexPath.row)
    }

    func insertPhoto(_ flickrPhoto: FlickrPhoto, at indexPath: IndexPath) {
        self.dataList[indexPath.section].searchResults.insert(
            flickrPhoto,
            at: indexPath.row)
    }

    func performLargeImageFetch(
        for indexPath: IndexPath,
        flickrPhoto: FlickrPhoto,
        cell: GridPhotoWithInteractCell) {
        cell.activityIndicator.startAnimating()

        flickrPhoto.loadLargeImage { [weak self] result in
            cell.activityIndicator.stopAnimating()

            guard let self = self else {
                return
            }

            switch result {
                case let .success(photo):
                    if indexPath == self.largePhotoIndexPath {
                        cell.imageView.image = photo.largeImage
                    }
                case .failure:
                    return
            }
        }
    }

    func updateSharedPhotoCountLabel() {
        if self.isSharing {
            self.shareTextLabel.text = "\(self.selectedPhotos.count) photos selected"
        } else {
            self.shareTextLabel.text = ""
        }

        self.shareTextLabel.textColor = UIColor(red: 0.01, green: 0.41, blue: 0.22, alpha: 1.0)

        UIView.animate(withDuration: 0.3) {
            self.shareTextLabel.sizeToFit()
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
}

// MARK: - Objc func

extension GridPhotosWithInteractViewController {
    @objc func searchButtonTapped() {
        if let textField = self.navigationBar.topItem?.titleView as? UITextField {
            self.performSearch(with: textField)
        }
    }

    @objc func shareButtonTapped(_ sender: Any) {
        guard !self.dataList.isEmpty else {
            return
        }

        guard !self.selectedPhotos.isEmpty else {
            self.isSharing.toggle()
            return
        }

        guard self.isSharing else {
            return
        }

        let images: [UIImage] = self.selectedPhotos.compactMap { photo in
            guard let thumbnail = photo.thumbnail else {
                return nil
            }

            return thumbnail
        }
        guard !images.isEmpty else {
            return
        }
        let shareController = UIActivityViewController(
            activityItems: images,
            applicationActivities: nil)
        shareController.completionWithItemsHandler = { _, _, _, _ in
            self.isSharing = false
            self.selectedPhotos.removeAll()
            self.updateSharedPhotoCountLabel()
        }
        guard let barButtonItem = sender as? UIBarButtonItem else {
            return
        }
        shareController.popoverPresentationController?.barButtonItem = barButtonItem
        shareController.popoverPresentationController?.permittedArrowDirections = .any
        present(shareController, animated: true, completion: nil)
    }
}

// MARK: - Text Field Delegate

extension GridPhotosWithInteractViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.startAnimating()

        guard let text = textField.text else {
            return false
        }

        self.flickr.searchFlickr(for: text) { searchResults in
            activityIndicator.removeFromSuperview()

            switch searchResults {
                case let .failure(error):
                    print("Error Searching: \(error)")
                case let .success(results):
                    print("Found \(results.searchResults.count) matching \(results.searchTerm)")
                    self.dataList.insert(results, at: 0)
                    self.collectionView?.reloadData()
            }
        }

        textField.text = nil
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UICollectionViewDelegate

extension GridPhotosWithInteractViewController {
    override func collectionView(
        _ collectionView: UICollectionView,
        shouldSelectItemAt indexPath: IndexPath
    ) -> Bool {
        guard !self.isSharing else {
            return true
        }

        if self.largePhotoIndexPath == indexPath {
            self.largePhotoIndexPath = nil
        } else {
            self.largePhotoIndexPath = indexPath
        }

        return false
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard self.isSharing else {
            return
        }

        let flickrPhoto = self.photo(for: indexPath)
        self.selectedPhotos.append(flickrPhoto)
        self.updateSharedPhotoCountLabel()
    }
}

// MARK: - UICollectionViewDataSource

extension GridPhotosWithInteractViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataList.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return self.dataList[section].searchResults.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: GridPhotoWithInteractCell.reuseIdentifier,
                for: indexPath
            ) as? GridPhotoWithInteractCell
        else {
            preconditionFailure("Invalid cell type")
        }

        let flickrPhoto = self.photo(for: indexPath)

        cell.activityIndicator.stopAnimating()

        guard indexPath == self.largePhotoIndexPath else {
            cell.imageView.image = flickrPhoto.thumbnail
            return cell
        }

        cell.isSelected = true
        guard flickrPhoto.largeImage == nil else {
            cell.imageView.image = flickrPhoto.largeImage
            return cell
        }

        cell.imageView.image = flickrPhoto.thumbnail

        self.performLargeImageFetch(for: indexPath, flickrPhoto: flickrPhoto, cell: cell)

        return cell
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        switch kind {
            case UICollectionView.elementKindSectionHeader:
                guard
                    let headerView = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: GridHeaderWithInteractView.reuseIdentifier,
                        for: indexPath
                    ) as? GridHeaderWithInteractView
                else {
                    return collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: GridHeaderWithInteractView.reuseIdentifier,
                        for: indexPath)
                }

                let searchTerm = self.dataList[indexPath.section].searchTerm
                headerView.setTitle(searchTerm)
                return headerView
            default:
                assert(false, "Invalid element type")
        }
    }
}

// MARK: - Collection View Flow Layout Delegate

extension GridPhotosWithInteractViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if indexPath == self.largePhotoIndexPath {
            let flickrPhoto = self.photo(for: indexPath)
            var size = collectionView.bounds.size
            size.height -= (self.sectionInsets.top + self.sectionInsets.right)
            size.width -= (self.sectionInsets.left + self.sectionInsets.right)
            return flickrPhoto.sizeToFillWidth(of: size)
        }

        let paddingSpace = self.sectionInsets.left * (self.itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / self.itemsPerRow

        return CGSize(width: widthPerItem, height: widthPerItem)
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

// MARK: - UICollectionViewDragDelegate

extension GridPhotosWithInteractViewController: UICollectionViewDragDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        let flickrPhoto = self.photo(for: indexPath)
        guard let thumbnail = flickrPhoto.thumbnail else {
            return []
        }
        let item = NSItemProvider(object: thumbnail)
        let dragItem = UIDragItem(itemProvider: item)
        return [dragItem]
    }
}

// MARK: - UICollectionViewDropDelegate

extension GridPhotosWithInteractViewController: UICollectionViewDropDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        canHandle session: UIDropSession
    ) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else {
            return
        }

        coordinator.items.forEach { dropItem in
            guard let sourceIndexPath = dropItem.sourceIndexPath else {
                return
            }

            collectionView.performBatchUpdates({
                let image = photo(for: sourceIndexPath)
                removePhoto(at: sourceIndexPath)
                insertPhoto(image, at: destinationIndexPath)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            }, completion: { _ in
                coordinator.drop(
                    dropItem.dragItem,
                    toItemAt: destinationIndexPath)
            })
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(
            operation: .move,
            intent: .insertAtDestinationIndexPath)
    }
}
