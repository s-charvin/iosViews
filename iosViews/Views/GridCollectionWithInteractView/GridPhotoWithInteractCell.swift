//
//  GridPhotoWithInteractCell.swift
//  iosViews
//
//  Created by scw on 2024/2/4.
//

import UIKit

class GridPhotoWithInteractCell: UICollectionViewCell {
    static let reuseIdentifier = "GridPhotoWithInteractCell"
    let imageView = UIImageView()
    let activityIndicator = UIActivityIndicatorView(style: .medium)

    override var isSelected: Bool {
        didSet {
            self.imageView.layer.borderWidth = self.isSelected ? 10 : 0
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isSelected = false // 设置 isSelected 的默认值
        self.setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // 配置 imageView
        self.imageView.layer.borderColor = UIColor.blue.cgColor // 使用你的主题色
        self.imageView.layer.borderWidth = 0
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.imageView)

        // 配置 activityIndicator
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.activityIndicator)

        // 设置 Auto Layout 约束
        NSLayoutConstraint.activate([
            self.imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.imageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.imageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            self.imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),

            self.activityIndicator.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
            self.activityIndicator.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
        ])
    }
}

class GridHeaderWithInteractView: UICollectionReusableView {
    static let reuseIdentifier = "GridHeaderWithInteractView"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupViews()
    }

    private func setupViews() {
        self.backgroundColor = .gray
        // 配置 titleLabel
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 25)
        self.titleLabel.textColor = .black
        self.titleLabel.textAlignment = .center
        self.addSubview(self.titleLabel)

        // 设置 titleLabel 的约束
        NSLayoutConstraint.activate([
            self.titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
        ])
    }

    func setTitle(_ title: String) {
        self.titleLabel.text = title
    }
}
