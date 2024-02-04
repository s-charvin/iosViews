//
//  FlickrPhotoCell.swift
//  iosViews
//
//  Created by scw on 2024/2/4.
//

import UIKit

import UIKit

class GridPhotoCell: UICollectionViewCell {
    static let reuseIdentifier = "GridPhotoCell"
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.imageView.contentMode = .scaleAspectFit
        contentView.addSubview(self.imageView)
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            self.imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            self.imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            self.imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class GridHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "GridHeaderView"

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
