//
//  RewardBubbleView.swift
//  EventPage
//
//  Created by scw on 2024/1/19.
//

import UIKit
import SnapKit

class BubbleView: UIView {
  var label = UILabel()
  private let imageView = UIImageView()
  private let triangleView = TriangleView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setupViews()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    self.setupViews()
  }

  private func setupViews() {
    // 设置气泡背景
    self.backgroundColor = .clear

    // 设置标签
    self.label.text = "30"
    self.label.textColor = .red // 根据设计调整颜色
    self.label.font = UIFont.boldSystemFont(ofSize: 12) // 根据设计调整字体和大小

    let backgroundView = UIView()
    backgroundView.backgroundColor = UIColor(
      red: 0xEB / 255.0,
      green: 0x5E / 255.0,
      blue: 0x2F / 255.0,
      alpha: 0.1)
    backgroundView.layer.cornerRadius = 12

    let infoView = UIView()
    infoView.backgroundColor = .clear
    self.addSubview(backgroundView)
    backgroundView.addSubview(infoView)
    infoView.addSubview(label)

    backgroundView.snp.makeConstraints { make in
      make.top.equalToSuperview()
      make.height.equalToSuperview().offset(-4)
      make.width.equalToSuperview()
    }
    infoView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview()
      make.height.equalToSuperview()
    }
    self.label.snp.makeConstraints { make in
      make.left.equalToSuperview()
      make.right.equalToSuperview()
      make.centerY.equalToSuperview()
    }

    self.triangleView.backgroundColor = .clear
    self.triangleView.fillColor = infoView.layer.backgroundColor
    self.addSubview(self.triangleView)

    self.triangleView.snp.makeConstraints { make in
      make.top.equalTo(backgroundView.snp.bottom) // 根据设计调整
      make.centerX.equalToSuperview()
      make.width.equalTo(8)
      make.height.equalTo(4)
    }
  }
}
