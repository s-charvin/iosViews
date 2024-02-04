//
//  TimeLineView.swift
//  EventPage
//
//  Created by scw on 2024/1/19.
//

import UIKit
import SnapKit
enum TimeLineViewType: Int {
  case all
  case bottom
  case top
  case none
}

enum TimeLineOrientation: Int {
  case horizontal
  case vertical
}

class TimeLineView: UIView {
  var type: TimeLineViewType = .none // 节点类型, 顶部, 中部, 底部
  var orientation: TimeLineOrientation = .vertical

  var lineColor: UIColor = .init(red: 220 / 255, green: 231 / 255, blue: 255 / 255, alpha: 1.0) // 连接线颜色
  var lineWidth: CGFloat = 2 // 连接线宽度

  var nodeBackgroundColor: UIColor = .white // 节点背景
  var nodeColor: UIColor = .init(red: 65 / 255, green: 129 / 255, blue: 254 / 255, alpha: 1.0) // 节点颜色
  var nodeBorderWidth: CGFloat = 2 // 节点线宽
  var nodeOffset: CGFloat? // 节点相对父节点或顶部的距离偏移
  var nodeGap: CGFloat = 0 // 节点与连接线的缝隙
  var nodeImage: UIImage? // 节点底图

  override func draw(_ rect: CGRect) {
    super.draw(rect)
    drawWithFrame(frame: bounds)
  }

  private func drawWithFrame(frame: CGRect) {
    let nodeOffsetValue = nodeOffset ?? (orientation == .vertical ? frame.height / 2.0 : frame.width / 2.0)

    let lineY = (frame.height - lineWidth) / 2.0 // 计算连接线垂直位置
    let leftLineRect = CGRect(
      x: 0,
      y: lineY,
      width: nodeOffsetValue - nodeGap - frame.height / 2.0,
      height: lineWidth
    ) // 节点左侧线
    let rightLineX = nodeOffsetValue + nodeGap + frame.height / 2.0
    let rightLineRect = CGRect(x: rightLineX, y: lineY, width: frame.width - rightLineX, height: lineWidth) // 节点右侧线

    let lineX = (frame.width - lineWidth) / 2.0 // 计算连接线水平位置(左上角的点)
    let topLineRect = CGRect(
      x: lineX,
      y: 0,
      width: lineWidth,
      height: nodeOffsetValue - nodeGap - frame.width / 2.0
    ) // 绘制节点顶部线s
    let bottomLineY = nodeOffsetValue + nodeGap + frame.width / 2.0 // 计算底部线的垂直位置(右下角的点)
    let bottomLineRect = CGRect(x: lineX, y: bottomLineY, width: lineWidth, height: frame.height - bottomLineY) // 节点底部线

    switch type {
    case .bottom:
      switch orientation {
      case .horizontal:
        drawLine(frame: rightLineRect)
      case .vertical:
        drawLine(frame: bottomLineRect)
      }
    case .top:
      switch orientation {
      case .horizontal:
        drawLine(frame: leftLineRect)
      case .vertical:
        drawLine(frame: topLineRect)
      }
    case .all:
      switch orientation {
      case .horizontal:
        drawLine(frame: leftLineRect)
        drawLine(frame: rightLineRect)
      case .vertical:
        drawLine(frame: topLineRect)
        drawLine(frame: bottomLineRect)
      }
    case .none:
      break
    }

    if orientation == .vertical {
      if let nodeImage = nodeImage {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        let imageRect = CGRect(x: 0, y: nodeOffsetValue - frame.width / 2.0, width: frame.width, height: frame.width)
        nodeImage.draw(in: imageRect)
        context?.restoreGState()
      } else {
        if nodeBorderWidth > 0 {
          // 空心圆
          let nodeSize = frame.width - nodeBorderWidth

          let nodeRect = CGRect(
            x: nodeBorderWidth / 2.0,
            y: nodeOffsetValue + nodeBorderWidth / 2.0 - frame.width / 2.0,
            width: nodeSize,
            height: nodeSize
          )
          let nodeBezierPath = UIBezierPath(ovalIn: nodeRect)
          nodeBezierPath.lineWidth = nodeBorderWidth
          nodeColor.setStroke()
          nodeBezierPath.stroke()
        } else {
          // 实心圆
          let nodeRect = CGRect(x: 0, y: nodeOffsetValue - frame.width / 2.0, width: frame.width, height: frame.width)
          let nodeBezierPath = UIBezierPath(ovalIn: nodeRect)
          nodeColor.setFill()
          nodeBezierPath.fill()
        }
      }
    } else if orientation == .horizontal {
      if let nodeImage = nodeImage {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        let imageRect = CGRect(x: nodeOffsetValue - frame.height / 2.0, y: 0, width: frame.height, height: frame.height)
        nodeImage.draw(in: imageRect)
        context?.restoreGState()
      } else {
        if nodeBorderWidth > 0 {
          // 空心圆
          let nodeSize = frame.height - nodeBorderWidth
          let nodeRect = CGRect(
            x: nodeOffsetValue + nodeBorderWidth / 2.0 - frame.height / 2.0,
            y: nodeBorderWidth / 2.0,
            width: nodeSize,
            height: nodeSize
          )
          let nodeBezierPath = UIBezierPath(ovalIn: nodeRect)
          nodeBezierPath.lineWidth = nodeBorderWidth
          nodeColor.setStroke()
          nodeBezierPath.stroke()
        } else {
          // 实心圆
          let nodeRect = CGRect(
            x: nodeOffsetValue - frame.height / 2.0,
            y: 0,
            width: frame.height,
            height: frame.height
          )
          let nodeBezierPath = UIBezierPath(ovalIn: nodeRect)
          nodeColor.setFill()
          nodeBezierPath.fill()
        }
      }
    }
  }

  private func drawLine(frame: CGRect) {
    let rectanglePath = UIBezierPath(rect: frame)
    lineColor.setFill()
    rectanglePath.fill()
  }
}
