//
//  TriangleView.swift
//  EventPage
//
//  Created by scw on 2024/1/19.
//

import UIKit
import SnapKit
class TriangleView: UIView {
  var fillColor: CGColor?
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupViews()
  }
  private func setupViews() {
    // 设置气泡背景
    backgroundColor = .clear
  }
  override func draw(_ rect: CGRect) {
    super.draw(rect)
    if let fillColor = fillColor {
      guard let context = UIGraphicsGetCurrentContext() else { return }
      context.beginPath()
      context.move(to: CGPoint(x: 0, y: 0))
      context.addLine(to: CGPoint(x: 0 + bounds.width / 2, y: bounds.height))
      context.addLine(to: CGPoint(x: 0 + bounds.width, y: 0))
      context.closePath()
      context.setFillColor(fillColor)
      context.fillPath()
    }
  }
}
