//
//  MyCategoryView.swift
//  EventPage
//
//  Created by scw on 2024/1/24.
//

import Foundation
import UIKit
import SnapKit
// extension   UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
class MyCategoryView:
  UIView {
  var tabCollectionView: UICollectionView? // 标签选项显示区域
  private var innerItemSpacing: CGFloat = 0 // 标签选项之间的间距记录
  var selectedIndex: Int = 0 // 设置和记录当前选中的标签选项
  var defaultSelectedIndex: Int = 0 { // 设置初始化时默认选中的标签选项
    didSet {
      selectedIndex = defaultSelectedIndex
      if containerViewList != nil {
        containerViewList?.defaultSelectedIndex = defaultSelectedIndex
      }
    }
  }

  weak var tabDataSource: CategoryViewBaseDataSourceProtocol? { // 标签选项的数据源
    didSet {
      // 当 dataSource 发生变化时，重新加载数据, 并刷新 collectionView
      self.tabDataSource?.reloadData(selectedIndex: self.selectedIndex)
    }
  }

  private var itemsDataSource = [CategoryViewBaseDataItemModel]() // 标签选项的数据源的引用, 方便获取数据源状态信息

  var delegate: CategoryViewDelegate? // 用于处理标签选项的点击事件和其他事件
  public var containerViewList: CategoryViewContainerListCollectionView? { // 用于显示内容区域的 UIScrollView
    willSet {
      self.containerViewList?.contentView.removeObserver(self, forKeyPath: "contentOffset")
    }
    didSet {
      self.containerViewList?.defaultSelectedIndex = self.defaultSelectedIndex
      self.containerViewList?.contentView.scrollsToTop = false
      self.containerViewList?.contentView.addObserver(
        self, forKeyPath: "contentOffset", options: .new, context: nil)
    }
  }

  var contentEdgeInsetLeft: CGFloat = 0 // 内容区域的左边距记录
  var contentEdgeInsetRight: CGFloat = 0 // 内容区域的右边距记录
  private var lastContentOffset: CGPoint = CGPoint.zero // 上一次滚动的位置记录
  private var scrollingTargetIndex: Int = -1 // 当前滚动的位置记录
  private var isFirstLayoutSubviews = true // 是否是第一次布局子视图

  override init(frame: CGRect) { // 初始化方法
    super.init(frame: frame)
    self.initUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    self.initUI()
  }

  deinit {
    self.containerViewList?.contentView.removeObserver(self, forKeyPath: "contentOffset")
  }

  private func initUI() {
    // 设置 collectionView 的布局
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    // 设置 collectionView 的属性
    self.tabCollectionView = UICollectionView(
      frame: CGRect.zero, collectionViewLayout: layout)
    self.tabCollectionView?.backgroundColor = .clear
    self.tabCollectionView?.showsHorizontalScrollIndicator = false
    self.tabCollectionView?.showsVerticalScrollIndicator = false
    self.tabCollectionView?.scrollsToTop = false
    self.tabCollectionView?.dataSource = self
    self.tabCollectionView?.delegate = self
    self.tabCollectionView?.register(
      CategoryViewBaseTabCell.self, forCellWithReuseIdentifier: "CategoryViewBaseTabCell")
    self.addSubview(self.tabCollectionView!)
  }

  override func layoutSubviews() { // 当视图的大小发生变化, 重新布局内部视图。如屏幕旋转，分屏，小窗口播放情况
    super.layoutSubviews()
    // 获取当前视图的大小
    let targetFrame = CGRect(
      x: 0, y: 0, width: bounds.size.width, height: floor(bounds.size.height))

    if self.isFirstLayoutSubviews {
      self.isFirstLayoutSubviews = false
      self.tabCollectionView?.frame = targetFrame
      self.reloadData()
    } else {
      if self.tabCollectionView?.frame != targetFrame {
        self.tabCollectionView?.frame = targetFrame
        self.tabCollectionView?.collectionViewLayout.invalidateLayout()
        self.tabCollectionView?.reloadData()
      }
    }
  }

  public func reloadData() {
    // 重新加载数据, 并初始化标签选项分布参数
    self.tabDataSource?.reloadData(selectedIndex: self.selectedIndex)
    self.tabDataSource?.registerCellClass(in: self) // 将与数据源关联的 cell 类注册到 collectionView

    if let itemsSource = tabDataSource?.items() {
      self.itemsDataSource = itemsSource
    }

    // 检查默认选中的索引是否合法, 如果不合法, 则设置为 0
    if self.selectedIndex < 0 || self.selectedIndex >= self.itemsDataSource.count {
      self.defaultSelectedIndex = 0
      self.selectedIndex = 0
    }

    // 计算获取标签选项之间的间距, 同时初始化标签选项的索引, 宽度, 选中状态
    // 标签选项的间距可以是固定值, 也可以是自适应宽度
    // 自适应宽度需要通过标签选项的总宽度和标签选项显示区域的总宽度来计算平均分布的间距大小
    self.innerItemSpacing = self.tabDataSource?.itemSpacing ?? 0
    var totalItemWidth: CGFloat = 0
    var totalContentWidth: CGFloat = self.getContentEdgeInsetLeft()

    for (index, itemModel) in self.itemsDataSource.enumerated() {
      itemModel.index = index // 设置标签选项的索引
      itemModel.itemWidth = (self.tabDataSource?.get(widthForItemAt: index) ?? 0)

      itemModel.isSelected = (index == self.selectedIndex)
      totalItemWidth += itemModel.itemWidth
      if index == self.itemsDataSource.count - 1 {
        totalContentWidth += itemModel.itemWidth + self.getContentEdgeInsetRight()
      } else {
        totalContentWidth += itemModel.itemWidth + self.innerItemSpacing
      }
    }

    if self.tabDataSource?.isItemSpacingAverageEnabled == true
      && totalContentWidth < bounds.size.width {
      // 注意: 需要考虑到内容区域的宽度是否大于标签选项的总宽度
      var itemSpacingCount = self.itemsDataSource.count - 1
      var totalItemSpacingWidth = bounds.size.width - totalItemWidth
      if self.contentEdgeInsetLeft == -1 {
        itemSpacingCount += 1
      } else {
        totalItemSpacingWidth -= self.contentEdgeInsetLeft
      }
      if self.contentEdgeInsetRight == -1 {
        itemSpacingCount += 1
      } else {
        totalItemSpacingWidth -= self.contentEdgeInsetRight
      }
      if itemSpacingCount > 0 {
        self.innerItemSpacing = totalItemSpacingWidth / CGFloat(itemSpacingCount) // 可用空白区域除以间距个数
      }
    }

    // 调整选中的标签选项的位置, 使其位于屏幕中间. 利用 collectionView 的偏移量来实现
    // 如果标签选项过少, 则不需要调整, 使得第一个标签选项位于屏幕左侧
    // 如果标签选项过多, 调整时保证最后一个标签选项不能左移出屏幕右侧边缘
    var selectedItemFrameX = self.innerItemSpacing // 预置左边距, 避免紧贴屏幕边缘
    var selectedItemWidth: CGFloat = 0 // 计算选中的标签选项的宽度
    totalContentWidth = self.getContentEdgeInsetLeft() // 重新计算选项显示区域的宽度
    for (index, itemModel) in self.itemsDataSource.enumerated() {
      if index < self.selectedIndex {
        selectedItemFrameX += itemModel.itemWidth + self.innerItemSpacing
      } else if index == self.selectedIndex {
        selectedItemWidth = itemModel.itemWidth
      }
      if index == self.itemsDataSource.count - 1 {
        totalContentWidth += itemModel.itemWidth + self.getContentEdgeInsetRight()
      } else {
        totalContentWidth += itemModel.itemWidth + self.innerItemSpacing
      }
    }

    let minX: CGFloat = 0
    let maxX = totalContentWidth - bounds.size.width
    let targetX = selectedItemFrameX - bounds.size.width / 2 + selectedItemWidth / 2
    self.tabCollectionView?.setContentOffset(
      CGPoint(x: max(min(maxX, targetX), minX), y: 0), animated: false)

    // 确保 listContainerScrollView 的父视图布局先于 listContainerScrollView 布局
    // 同时对 listContainerScrollView 内容根据选中的标签选项进行偏移, 使其显示选中的 tab 的内容
    if self.containerViewList?.contentView != nil {
      if self.containerViewList!.contentView.frame.equalTo(CGRect.zero)
        && self.containerViewList!.contentView.superview != nil {
        var parentView = self.containerViewList?.contentView.superview
        while parentView != nil && parentView?.frame.equalTo(CGRect.zero) == true {
          parentView = parentView?.superview
        }
        parentView?.setNeedsLayout()
        parentView?.layoutIfNeeded()
      }
      self.containerViewList!.contentView.setContentOffset(
        CGPoint(x: CGFloat(self.selectedIndex) * self.containerViewList!.contentView.bounds.size.width, y: 0),
        animated: true)
    }

    // 刷新标签选项区域和内容区域的数据
    self.tabCollectionView?.reloadData()
    self.tabCollectionView?.collectionViewLayout.invalidateLayout()
    self.containerViewList?.reloadData()
  }

  private func getContentEdgeInsetLeft() -> CGFloat {
    // 如果没有设置左边距, 则自动使用标签选项间距
    return self.contentEdgeInsetLeft == -1 ? self.innerItemSpacing : self.contentEdgeInsetLeft
  }

  private func getContentEdgeInsetRight() -> CGFloat {
    // 如果没有设置右边距, 则自动使用标签选项间距
    return self.contentEdgeInsetRight == -1 ? self.innerItemSpacing : self.contentEdgeInsetRight
  }

  // MARK: - KVO, K: Key, V: Value, O: Observer
  // observeValue 用于根据提供的 keyPath 来处理对应的事件.
  override func observeValue(
    forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
    context: UnsafeMutableRawPointer?) {
    // 当 contentScrollView 的 contentOffset 发生变化时, 重新布局标签选项. (左右滑动)
    if keyPath == "contentOffset" {
      let contentOffset = change?[NSKeyValueChangeKey.newKey] as! CGPoint // 获取 contentOffset 的新值
      if self.containerViewList?.contentView.isTracking == true
        || self.containerViewList?.contentView.isDecelerating == true {
        // 用户滚动引起的 contentOffset 变化, 才处理.
        if self.containerViewList?.contentView.bounds.size.width == 0 {
          // 如果 contentView Frame 为零, 说明还没有被添加到父视图上, 不需要处理
          return
        }
        var progress = contentOffset.x / self.containerViewList!.contentView.bounds.size.width
        if Int(progress) > self.itemsDataSource.count - 1 || progress < 0 {
          // 滑动偏移量超过了边界，不需要处理
          return
        }
        if contentOffset.x == 0 && self.selectedIndex == 0 && self.lastContentOffset.x == 0 {
          // 滚动到了最左边，且已经选中了第一个，且之前的 contentOffset.x 为0
          // 说明是在第一个 item 时继续向左滚动，不需要处理
          return
        }

        let maxContentOffsetX =
          self.containerViewList!.contentView.contentSize.width
            - self.containerViewList!.contentView.bounds.size.width
        if contentOffset.x == maxContentOffsetX
          && self.selectedIndex == self.itemsDataSource.count - 1
          && self.lastContentOffset.x == maxContentOffsetX {
          // 滚动到了最右边，且已经选中了最后一个，且之前的 contentOffset.x 为 maxContentOffsetX
          // 说明是在最后一个 item 时继续向右滚动，不需要处理
          return
        }

        // 计算当前滚动的位置
        progress = max(0, min(CGFloat(self.itemsDataSource.count - 1), progress))
        let baseIndex = Int(floor(progress))
        let remainderProgress = progress - CGFloat(baseIndex) // 进度余数

        let leftItemFrame = self.getItemFrameAt(index: baseIndex) // 获取滚动目的地标签选项的 frame
        let rightItemFrame = self.getItemFrameAt(index: baseIndex + 1) // 获取右边标签选项的 frame
        var rightItemContentWidth: CGFloat = 0 // 右边标签选项的宽度
        if baseIndex + 1 < self.itemsDataSource.count {
          // 如果右边还有标签选项, 则获取右边标签选项的宽度
          rightItemContentWidth = self.tabDataSource?.get(widthForItemContentAt: baseIndex + 1) ?? 0
        }

        if remainderProgress == 0 { // 滚动到了整数位置
          // 滑动翻页，需要更新选中状态, 滑动一小段距离，然后放开回到原位.
          // contentOffset 同样的值会回调多次。
          // 例如在 index 为 1 的情况，滑动放开回到原位，
          // contentOffset会多次回调 CGPoint(width, 0)
          if !(self.lastContentOffset.x == contentOffset.x && self.selectedIndex == baseIndex) {
            self.scrollSelectItemAt(index: baseIndex)
          }
        } else {
          // 快速滑动翻页，当 remainderRatio 没有变成 0，但是已经翻页了，需要通过下面的判断，触发选中.
          if abs(progress - CGFloat(self.selectedIndex)) > 1 {
            // 当前选中的标签选项和滚动的目的地标签选项的索引相差大于 1, 说明已经翻页了
            var targetIndex = baseIndex
            if progress < CGFloat(self.selectedIndex) {
              // 当前选中的标签选项的索引大于滚动的目的地标签选项的索引, 说明是向左翻页
              targetIndex = baseIndex + 1
            }
            self.scrollSelectItemAt(index: targetIndex)
          }
          // 记录当前滚动的位置.
          if self.selectedIndex == baseIndex {
            self.scrollingTargetIndex = baseIndex + 1
          } else {
            self.scrollingTargetIndex = baseIndex //
          }

          // 处理滚动过程中的标签选项的刷新
          self.tabDataSource?.refreshItemModel(leftItemModel: self.itemsDataSource[baseIndex],
                                               rightItemModel: self.itemsDataSource[baseIndex + 1], percent: remainderProgress)

          let leftCell =
            self.tabCollectionView?.cellForItem(at: IndexPath(item: baseIndex, section: 0))
              as? CategoryViewBaseTabCell

          leftCell?.reloadData(itemModel: self.itemsDataSource[baseIndex], selectedType: .unknown)

          let rightCell =
            self.tabCollectionView?.cellForItem(at: IndexPath(item: baseIndex + 1, section: 0))
              as? CategoryViewBaseTabCell

          rightCell?.reloadData(
            itemModel: self.itemsDataSource[baseIndex + 1], selectedType: .unknown)

          self.delegate?.categoryView(
            self, scrollingFrom: baseIndex, to: baseIndex + 1, percent: remainderProgress)
        }
      }
      self.lastContentOffset = contentOffset
    }
  }

  private func getItemFrameAt(index: Int) -> CGRect {
    guard index < self.itemsDataSource.count else {
      return CGRect.zero
    }
    var x = self.getContentEdgeInsetLeft()
    for i in 0 ..< index {
      let itemModel = self.itemsDataSource[i]
      var itemWidth: CGFloat = 0
      itemWidth = itemModel.itemWidth
      x += itemWidth + self.innerItemSpacing
    }
    var width: CGFloat = 0
    let selectedItemModel = self.itemsDataSource[index]
    width = selectedItemModel.itemWidth
    return CGRect(x: x, y: 0, width: width, height: bounds.size.height)
  }

  private func getSelectedItemFrameAt(index: Int) -> CGRect {
    guard index < self.itemsDataSource.count else {
      return CGRect.zero
    }
    var x = self.getContentEdgeInsetLeft()
    for i in 0 ..< index {
      let itemWidth = (tabDataSource?.get(widthForItemAt: i) ?? 0)
      x += itemWidth + self.innerItemSpacing
    }
    var width: CGFloat = 0
    let selectedItemModel = self.itemsDataSource[index]
    width = selectedItemModel.itemWidth
    return CGRect(x: x, y: 0, width: width, height: bounds.size.height)
  }

  private func selectItemAt(index: Int, selectedType: CategoryViewItemSelectedType) {
    guard index >= 0 && index < self.itemsDataSource.count else {
      return
    }

    if index == self.selectedIndex {
      if selectedType == .code {
        self.containerViewList?.didClickSelectedItem(at: index)
      } else if selectedType == .click {
        self.delegate?.categoryView(self, didClickSelectedItemAt: index)
        self.containerViewList?.didClickSelectedItem(at: index)
      } else if selectedType == .scroll {
        self.delegate?.categoryView(self, didScrollSelectedItemAt: index)
      }
      self.delegate?.categoryView(self, didSelectedItemAt: index)
      self.scrollingTargetIndex = -1
      return
    }

    let currentSelectedItemModel = self.itemsDataSource[self.selectedIndex]
    let willSelectedItemModel = self.itemsDataSource[index]
    self.tabDataSource?.refreshItemModel(currentSelectedItemModel: currentSelectedItemModel,
                                         willSelectedItemModel: willSelectedItemModel, selectedType: selectedType)

    let currentSelectedCell =
      self.tabCollectionView?.cellForItem(at: IndexPath(item: self.selectedIndex, section: 0))
        as? CategoryViewBaseTabCell

    currentSelectedCell?.reloadData(itemModel: currentSelectedItemModel, selectedType: selectedType)

    let willSelectedCell =
      self.tabCollectionView?.cellForItem(at: IndexPath(item: index, section: 0))
        as? CategoryViewBaseTabCell

    willSelectedCell?.reloadData(itemModel: willSelectedItemModel, selectedType: selectedType)

    if self.scrollingTargetIndex != -1 && self.scrollingTargetIndex != index {
      let scrollingTargetItemModel = self.itemsDataSource[self.scrollingTargetIndex]
      scrollingTargetItemModel.isSelected = false
      self.tabDataSource?.refreshItemModel(
        currentSelectedItemModel: scrollingTargetItemModel,
        willSelectedItemModel: willSelectedItemModel,
        selectedType: selectedType)
      let scrollingTargetCell =
        self.tabCollectionView?.cellForItem(at: IndexPath(item: self.scrollingTargetIndex, section: 0))
          as? CategoryViewBaseTabCell

      scrollingTargetCell?.reloadData(
        itemModel: scrollingTargetItemModel, selectedType: selectedType)
    }
    self.tabCollectionView?.scrollToItem(
      at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)

    if self.containerViewList?.contentView != nil && (selectedType == .click || selectedType == .code) {
      self.containerViewList!.contentView.setContentOffset(
        CGPoint(x: self.containerViewList!.contentView.bounds.size.width * CGFloat(index), y: 0),
        animated: false)
    }

    self.selectedIndex = index

    let currentSelectedItemFrame = self.getSelectedItemFrameAt(index: self.selectedIndex)

    self.scrollingTargetIndex = -1
    if selectedType == .code {
      self.containerViewList?.didClickSelectedItem(at: index)
    } else if selectedType == .click {
      self.delegate?.categoryView(self, didClickSelectedItemAt: index)
      self.containerViewList?.didClickSelectedItem(at: index)
    } else if selectedType == .scroll {
      self.delegate?.categoryView(self, didScrollSelectedItemAt: index)
    }
    self.delegate?.categoryView(self, didSelectedItemAt: index)
  }

  private func clickSelectItemAt(index: Int) {
    guard self.delegate?.categoryView(self, canClickItemAt: index) != false else {
      return
    }
    self.selectItemAt(index: index, selectedType: .click)
  }

  private func scrollSelectItemAt(index: Int) {
    self.selectItemAt(index: index, selectedType: .scroll)
  }
}

// MARK: - UICollectionViewDataSource

extension MyCategoryView: UICollectionViewDataSource {
  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  public func collectionView(
    _ collectionView: UICollectionView, numberOfItemsInSection section: Int
  ) -> Int {
    return self.itemsDataSource.count
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell {
    if let identifier = tabDataSource?.identifier {
      let reuseCell = self.tabCollectionView!.dequeueReusableCell(
        withReuseIdentifier: identifier, for: indexPath)
      guard reuseCell.isKind(of: CategoryViewBaseTabCell.self), let cell = reuseCell as? CategoryViewBaseTabCell else {
        fatalError("Cell class must be subclass of CategoryViewTabCell")
      }
      // 通过数据源获取 cell, 并刷新 cell 的显示. 刷新是因为 cell 可能会被重用, 需要重新设置显示内容
      cell.reloadData(itemModel: self.itemsDataSource[indexPath.item], selectedType: .unknown)
      return cell
    } else {
      return UICollectionViewCell(frame: CGRect.zero)
    }
  }
}

// MARK: - UICollectionViewDelegate

extension MyCategoryView: UICollectionViewDelegate {
  public func collectionView(
    _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath
  ) {
    self.clickSelectItemAt(index: indexPath.item)
  }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MyCategoryView: UICollectionViewDelegateFlowLayout {
  public func collectionView(
    _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAt section: Int
  ) -> UIEdgeInsets {
    return UIEdgeInsets(
      top: 0, left: self.getContentEdgeInsetLeft(), bottom: 0, right: self.getContentEdgeInsetRight())
  }

  public func collectionView(
    _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    return CGSize(
      width: self.itemsDataSource[indexPath.item].itemWidth, height: collectionView.bounds.size.height)
  }

  public func collectionView(
    _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
    minimumLineSpacingForSectionAt section: Int
  ) -> CGFloat {
    return self.innerItemSpacing
  }

  public func collectionView(
    _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
    minimumInteritemSpacingForSectionAt section: Int
  ) -> CGFloat {
    return self.innerItemSpacing
  }
}



protocol CategoryViewDelegate: AnyObject {
  func categoryView(_ categoryView: MyCategoryView, didSelectedItemAt index: Int)
  func categoryView(_ categoryView: MyCategoryView, didClickSelectedItemAt index: Int)
  func categoryView(_ categoryView: MyCategoryView, didScrollSelectedItemAt index: Int)
  func categoryView(
    _ categoryView: MyCategoryView, scrollingFrom leftIndex: Int, to rightIndex: Int,
    percent: CGFloat)
  func categoryView(_ categoryView: MyCategoryView, canClickItemAt index: Int) -> Bool
}

extension CategoryViewDelegate {
  func categoryView(_ categoryView: MyCategoryView, didSelectedItemAt index: Int) {}
  func categoryView(_ categoryView: MyCategoryView, didClickSelectedItemAt index: Int) {}
  func categoryView(_ categoryView: MyCategoryView, didScrollSelectedItemAt index: Int) {}
  func categoryView(
    _ categoryView: MyCategoryView, scrollingFrom leftIndex: Int, to rightIndex: Int,
    percent: CGFloat
  ) {}
  func categoryView(_ categoryView: MyCategoryView, canClickItemAt index: Int) -> Bool {
    return true
  }
}


/*
 标签选项数据源设计思路 CategoryViewTabDataSource
 ---
 考虑代码的可扩展性, 通过协议的方式先定义数据源必须实现的功能,
 通过基类的方式来实现数据源的基本功能, 提供默认值或默认实现方式
 最后通过继承基本数据源的方式来实现具体的数据源.

 数据源协议:
 - 数据源绑定
 - registerCellClass(in categoryView: MyCategoryView): 将与当前 多标签页控制器 相关联的 标签选项数据类型 注册到控制器的 collectionView 中, 以便在显示标签页时使用.
 - 数据管理
 - items(...): 返回包含所有标签选项数据的数据源数组, 数组元素必须是规定的类型, 保证包含所需的数据.
 - 数据信息获取
 - get(widthForItemAt index: Int): 返回指定索引处的标签选项的区域宽度.
 - get(widthForItemContentAt index: Int): 返回指定索引处的标签选项内部实际内容宽度.
 - get(cellForItemAt index: Int): 返回指定索引处的标签选项的实际元素对象.
 - 数据刷新
 - reloadData(): 重新加载数据源, 并刷新标签页的显示.
 - refreshItemModel(_ categoryView, _ itemModel, at index, selectedIndex): 根据当前选中的 selectedIndex，刷新目标 index 的 itemModel
 - refreshItemModel(_ categoryView, currentSelectedItemModel, willSelectedItemModel, selectedType): item选中的时候调用。当前选中的currentSelectedItemModel状态需要更新为未选中；将要选中的willSelectedItemModel状态需要更新为选中。
 - refreshItemModel(_ categoryView, leftItemModel, rightItemModel, percent): 左右滚动过渡时调用。根据当前的从左到右的百分比，刷新leftItemModel和rightItemModel

 数据源基类:
 - 数据元素管理
 - dataSource: 数据源数组, 用于存储所有标签选项的数据.
 - itemWidth: 标签选项的宽度, 默认为自适应宽度.
 - itemWidthIncrement: 开启自适应宽度时, 标签选项的宽度增量, 默认为 0.

 - 数据元素更新(子类需要重载的方法)
 - reloadData(selectedIndex: Int): 重新加载数据源, 并刷新标签页的显示.
 - preferredItemCount(): 返回标签选项的数量.
 - preferredItemModelInstance(): 返回标签选项的数据类型实例.
 - preferredSegmentedView(_ segmentedView: JXSegmentedView, widthForItemAt index: Int): 返回指定索引处的标签选项的区域宽度.
 - preferredRefreshItemModel(_ itemModel: CategoryViewBaseDataItemModel, at index: Int, selectedIndex: Int): 刷新指定索引处的标签页的显示.

 - 数据元素获取
 - items(): 返回包含所有标签选项数据的数据源数组.
 - segmentedView(_ segmentedView: JXSegmentedView, widthForItemAt index: Int): 返回指定索引处的标签选项的区域宽度.
 - segmentedView(_ segmentedView: JXSegmentedView, widthForItemContentAt index: Int): 返回指定索引处的标签选项内部实际内容宽度.
 - segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int): 返回指定索引处的标签选项的实际元素对象.
 - 数据元素刷新
 - refreshItemModel(_ segmentedView: JXSegmentedView, currentSelectedItemModel: CategoryViewBaseDataItemModel, willSelectedItemModel: CategoryViewBaseDataItemModel, selectedType: CategoryViewItemSelectedType): 刷新当前选中的标签页和将要选中的标签页的显示.
 - refreshItemModel(_ segmentedView: JXSegmentedView, leftItemModel: CategoryViewBaseDataItemModel, rightItemModel: CategoryViewBaseDataItemModel, percent: CGFloat): 刷新左右两个标签页的显示.
 - refreshItemModel(_ segmentedView: JXSegmentedView, _ itemModel: CategoryViewBaseDataItemModel, at index: Int, selectedIndex: Int): 刷新指定索引处的标签页的显示.

 ---
 */

protocol CategoryViewBaseDataSourceProtocol: AnyObject {
  var identifier: String { get }
  var itemSpacing: CGFloat { get }
  var isItemSpacingAverageEnabled: Bool { get }

  func registerCellClass(in categoryView: MyCategoryView)
  func items() -> [CategoryViewBaseDataItemModel]
  func get(widthForItemAt index: Int) -> CGFloat
  func get(widthForItemContentAt index: Int) -> CGFloat
  func get(cellForItemAt index: Int) -> CategoryViewBaseTabCell

  func reloadData(selectedIndex: Int)
  func refreshItemModel(
    _ itemModel: CategoryViewBaseDataItemModel, at index: Int, selectedIndex: Int)
  func refreshItemModel(
    currentSelectedItemModel: CategoryViewBaseDataItemModel,
    willSelectedItemModel: CategoryViewBaseDataItemModel, selectedType: CategoryViewItemSelectedType
  )
  func refreshItemModel(
    leftItemModel: CategoryViewBaseDataItemModel, rightItemModel: CategoryViewBaseDataItemModel,
    percent: CGFloat)
}

class CategoryViewBaseDataSource: CategoryViewBaseDataSourceProtocol {
  var identifier: String = ""
  var dataSource = [CategoryViewBaseDataItemModel]()
  var itemWidth: CGFloat = -1
  var itemWidthIncrement: CGFloat = 0
  var itemSpacing: CGFloat = 20
  var isItemSpacingAverageEnabled: Bool = true

  init() {}
  deinit {}

  func items() -> [CategoryViewBaseDataItemModel] {
    return self.dataSource
  }

  func count() -> Int {
    return self.dataSource.count
  }

  func itemModelInstance() -> CategoryViewBaseDataItemModel {
    return CategoryViewBaseDataItemModel()
  }

  func get(widthForItemAt index: Int) -> CGFloat {
    return self.itemWidthIncrement
  }

  func get(widthForItemContentAt index: Int) -> CGFloat {
    return self.get(widthForItemAt: index)
  }

  func get(cellForItemAt index: Int) -> CategoryViewBaseTabCell {
    return CategoryViewBaseTabCell()
  }

  func registerCellClass(in categoryView: MyCategoryView) {
  }

  func reloadData(selectedIndex: Int) {
    self.dataSource.removeAll()
    for index in 0 ..< self.count() {
      let itemModel = self.itemModelInstance()
      self.refreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)
      self.dataSource.append(itemModel)
    }
  }

  func refreshItemModel(
    _ itemModel: CategoryViewBaseDataItemModel, at index: Int, selectedIndex: Int
  ) {
    itemModel.index = index
    if index == selectedIndex {
      itemModel.isSelected = true
    } else {
      itemModel.isSelected = false
    }
  }

  func refreshItemModel(
    currentSelectedItemModel: CategoryViewBaseDataItemModel,
    willSelectedItemModel: CategoryViewBaseDataItemModel, selectedType: CategoryViewItemSelectedType
  ) {
    currentSelectedItemModel.isSelected = false
    willSelectedItemModel.isSelected = true
  }

  func refreshItemModel(
    leftItemModel: CategoryViewBaseDataItemModel, rightItemModel: CategoryViewBaseDataItemModel,
    percent: CGFloat
  ) {
  }
}

/*
 数据源实现: CategoryViewTitleTabDataSource
 属性
 - titles: 标签选项的标题数组
 - widthForTitleClosure: 标签选项的宽度闭包
 - titleNumberOfLines: 标签选项的标题行数
 - titleNormalColor: 标签选项的标题正常颜色
 - titleSelectedColor: 标签选项的标题选中颜色
 - titleNormalFont: 标签选项的标题正常字体
 - titleSelectedFont: 标签选项的标题选中字体

 自有方法
 - widthForTitle(_ title: String): 返回指定标题的宽度

 重载方法
 - preferredItemCount(): 返回标签选项的数量
 - preferredItemModelInstance(): 返回标签选项的数据类型实例
 - preferredRefreshItemModel(_ itemModel: CategoryViewBaseDataItemModel, at index: Int, selectedIndex: Int): 刷新指定索引处的标签页的显示
 - preferredSegmentedView(_ segmentedView: JXSegmentedView, widthForItemAt index: Int): 返回指定索引处的标签选项的区域宽度
 - registerCellClass(in segmentedView: JXSegmentedView): 将与当前 多标签页控制器 相关联的 标签选项数据类型 注册到控制器的 collectionView 中, 以便在显示标签页时使用.
 - segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int): 返回指定索引处的标签选项的实际元素对象.
 - segmentedView(_ segmentedView: JXSegmentedView, widthForItemContentAt index: Int): 返回指定索引处的标签选项内部实际内容宽度.
 - refreshItemModel(_ segmentedView: JXSegmentedView, leftItemModel: CategoryViewBaseDataItemModel, rightItemModel: CategoryViewBaseDataItemModel, percent: CGFloat): 刷新左右两个标签页的显示.
 - refreshItemModel(_ segmentedView: JXSegmentedView, currentSelectedItemModel: CategoryViewBaseDataItemModel, willSelectedItemModel: CategoryViewBaseDataItemModel, selectedType: CategoryViewItemSelectedType): 刷新当前选中的标签页和将要选中的标签页的显示.
 ---
 */

class CategoryViewTitleDataSource: CategoryViewBaseDataSource {
  var titles = [String]() // title 数组
  var titleNumberOfLines: Int = 1 // title 显示行数
  var titleNormalColor: UIColor = .black // title 普通状态的 textColor
  var titleSelectedColor: UIColor = .red // title 选中状态的 textColor
  var titleNormalFont: UIFont = UIFont.systemFont(ofSize: 15) // title 普通状态时的字体
  var titleSelectedFont: UIFont? // title 选中时的字体。如果不赋值，就默认与 titleNormalFont 一样
  // title 是否使用遮罩过渡
  var isTitleMaskEnabled: Bool = false

  override init() {
    super.init()
    self.identifier = "CategoryViewTitleTabCell"
  }

  override func count() -> Int {
    return self.titles.count
  }

  override func itemModelInstance() -> CategoryViewBaseDataItemModel {
    return CategoryViewTitleDataItemModel()
  }

  override func refreshItemModel(
    _ itemModel: CategoryViewBaseDataItemModel, at index: Int, selectedIndex: Int
  ) {
    super.refreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)
    guard let myItemModel = itemModel as? CategoryViewTitleDataItemModel else {
      return
    }

    myItemModel.title = self.titles[index]
    myItemModel.textWidth = self.widthForTitle(myItemModel.title ?? "")
    myItemModel.titleNumberOfLines = self.titleNumberOfLines
    myItemModel.titleNormalColor = self.titleNormalColor
    myItemModel.titleSelectedColor = self.titleSelectedColor
    myItemModel.titleNormalFont = self.titleNormalFont
    myItemModel.titleSelectedFont =
      self.titleSelectedFont != nil ? self.titleSelectedFont! : self.titleNormalFont

    myItemModel.isTitleMaskEnabled = self.isTitleMaskEnabled
    if index == selectedIndex {
      myItemModel.titleCurrentColor = self.titleSelectedColor
    } else {
      myItemModel.titleCurrentColor = self.titleNormalColor
    }
  }

  func widthForTitle(_ title: String) -> CGFloat {
    let textWidth = NSString(string: title).boundingRect(
      with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity),
      options: [.usesFontLeading, .usesLineFragmentOrigin],
      attributes: [NSAttributedString.Key.font: self.titleSelectedFont], context: nil
    ).size.width
    return CGFloat(ceilf(Float(textWidth)))
  }

  override func get(widthForItemAt index: Int) -> CGFloat {
    var width = super.get(widthForItemAt: index)
    if self.itemWidth == -1 {
      width += (self.dataSource[index] as! CategoryViewTitleDataItemModel).textWidth
    } else {
      width += self.itemWidth
    }
    return width
  }

  override func get(widthForItemContentAt index: Int) -> CGFloat {
    let model = self.dataSource[index] as! CategoryViewTitleDataItemModel
    return model.textWidth
  }

  override func refreshItemModel(
    leftItemModel: CategoryViewBaseDataItemModel, rightItemModel: CategoryViewBaseDataItemModel,
    percent: CGFloat
  ) {
    super.refreshItemModel(
      leftItemModel: leftItemModel, rightItemModel: rightItemModel, percent: percent)

    guard let leftModel = leftItemModel as? CategoryViewTitleDataItemModel,
          let rightModel = rightItemModel as? CategoryViewTitleDataItemModel
    else {
      return
    }
  }

  override func refreshItemModel(
    currentSelectedItemModel: CategoryViewBaseDataItemModel,
    willSelectedItemModel: CategoryViewBaseDataItemModel, selectedType: CategoryViewItemSelectedType
  ) {
    super.refreshItemModel(currentSelectedItemModel: currentSelectedItemModel, willSelectedItemModel: willSelectedItemModel, selectedType: selectedType)

    guard
      let myCurrentSelectedItemModel = currentSelectedItemModel as? CategoryViewTitleDataItemModel,
      let myWillSelectedItemModel = willSelectedItemModel as? CategoryViewTitleDataItemModel
    else {
      return
    }

    myCurrentSelectedItemModel.titleCurrentColor = myCurrentSelectedItemModel.titleNormalColor
    myWillSelectedItemModel.titleCurrentColor = myWillSelectedItemModel.titleSelectedColor
  }

  override func registerCellClass(in categoryView: MyCategoryView) {
    categoryView.tabCollectionView?.register(
      CategoryViewTitleTabCell.self, forCellWithReuseIdentifier: self.identifier)
  }
}


class CategoryViewBaseTabCell: UICollectionViewCell {
  var itemModel: CategoryViewBaseDataItemModel?

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.initUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)

    self.initUI()
  }

  deinit {}

  func initUI() {
  }

  func reloadData(
    itemModel: CategoryViewBaseDataItemModel, selectedType: CategoryViewItemSelectedType
  ) {
    self.itemModel = itemModel
  }
}

class CategoryViewTitleTabCell: CategoryViewBaseTabCell {
  public let titleLabel = UILabel()

  override func initUI() {
    super.initUI()

    self.titleLabel.textAlignment = .center
    self.contentView.addSubview(self.titleLabel)
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    guard let myItemModel = self.itemModel as? CategoryViewTitleDataItemModel else {
      return
    }

    let labelSize = self.titleLabel.sizeThatFits(self.contentView.bounds.size)
    var labelBounds = CGRect(x: 0, y: 0, width: labelSize.width, height: labelSize.height)

    labelBounds.size.width = myItemModel.textWidth

    self.titleLabel.bounds = labelBounds
    self.titleLabel.center = self.contentView.center

  }

  override func reloadData(
    itemModel: CategoryViewBaseDataItemModel, selectedType: CategoryViewItemSelectedType
  ) {
    super.reloadData(itemModel: itemModel, selectedType: selectedType)

    guard let myItemModel = itemModel as? CategoryViewTitleDataItemModel else {
      return
    }
    self.titleLabel.text = myItemModel.title ?? ""
    self.titleLabel.numberOfLines = myItemModel.titleNumberOfLines

    if myItemModel.isSelected {
      self.titleLabel.font = myItemModel.titleSelectedFont
      self.titleLabel.textColor = myItemModel.titleSelectedColor
    } else {
      self.titleLabel.font = myItemModel.titleNormalFont
      self.titleLabel.textColor = myItemModel.titleNormalColor
    }
    self.setNeedsLayout()
  }
}

/*
 标签页内容显示区域设计思路 CategoryViewListContainerCollectionView
 ---
 - 列表容器的基本接口设计: CategoryViewListContainer
 - 获取实际内容视图: contentView
 - 刷新显示数据: reloadData
 - 处理选中项: didClickSelectedItem

 - 视图生命周期事件管理:
 - 重写 shouldAutomaticallyForwardAppearanceMethods 属性，返回 false，使得当前控制器不自动转发生命周期事件
 - 重写 viewWillAppear、viewDidAppear、viewWillDisappear、viewDidDisappear 方法，将事件转发给 CategoryViewListContainerViewDelegate 处理
 - 重写 willMove(toSuperview newSuperview: UIView?) 方法，将 CategoryViewListContainerViewController 添加到父视图控制器中

 - 列表视图接口设计: CategoryViewListContainerViewDelegate
 - 获取列表视图
 - 列表视图生命周期事件处理
 - listWillAppear: viewWillAppear
 - listDidAppear: viewDidAppear
 - listWillDisappear: viewWillDisappear
 - listDidDisappear: viewDidDisappear

 - 列表视图数据源接口设计: CategoryViewListContainerViewDataSource
 - 获取列表数量: numberOfLists
 - 获取列表视图: listContainerView
 - 列表视图是否可以初始化: canInitListAt
 - 获取列表视图类型: scrollViewClass
 ---
 */

protocol CategoryViewListContainer {
  var defaultSelectedIndex: Int { get set }
  var contentView: UICollectionView { get }
  func reloadData()
  func didClickSelectedItem(at index: Int)
}

class CategoryViewContainerListCollectionView: UIView, CategoryViewListContainer {
  weak var dataSource: CategoryViewListContainerViewDataSource?

  var validListDict = [Int: CategoryViewListContainerViewDelegate]()
  var initListPercent: CGFloat = 0.01 {
    didSet {
      if self.initListPercent <= 0 || self.initListPercent >= 1 {
        assertionFailure("initListPercent 值范围为开区间(0,1)，即不包括 0 和 1")
      }
    }
  }

  var listCellBackgroundColor: UIColor = .white

  private var currentIndex: Int = 0
  var defaultSelectedIndex: Int = 0 {
    didSet {
      self.currentIndex = self.defaultSelectedIndex
    }
  }

  var contentView: UICollectionView { return self.collectionView }
  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    if let collectionViewClass = self.dataSource?.scrollViewClass?(in: self)
      as? UICollectionView.Type {
      return collectionViewClass.init(frame: CGRect.zero, collectionViewLayout: layout)
    } else {
      return UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
    }
  }()

  private lazy var containerVC = CategoryViewListContainerViewController()
  private var willAppearIndex: Int = -1
  private var willDisappearIndex: Int = -1

  init(dataSource: CategoryViewListContainerViewDataSource) {
    self.dataSource = dataSource
    super.init(frame: CGRect.zero)

    self.initUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func initUI() {
    self.containerVC.view.backgroundColor = .clear
    self.addSubview(self.containerVC.view)
    self.containerVC.viewWillAppearClosure = { [weak self] in
      self?.listWillAppear(at: self?.currentIndex ?? 0)
    }
    self.containerVC.viewDidAppearClosure = { [weak self] in
      self?.listDidAppear(at: self?.currentIndex ?? 0)
    }
    self.containerVC.viewWillDisappearClosure = { [weak self] in
      self?.listWillDisappear(at: self?.currentIndex ?? 0)
    }
    self.containerVC.viewDidDisappearClosure = { [weak self] in
      self?.listDidDisappear(at: self?.currentIndex ?? 0)
    }
    self.collectionView.isPagingEnabled = true
    self.collectionView.showsHorizontalScrollIndicator = false
    self.collectionView.showsVerticalScrollIndicator = false
    self.collectionView.scrollsToTop = false
    self.collectionView.bounces = false
    self.collectionView.dataSource = self
    self.collectionView.delegate = self
    self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    //    collectionView.isPrefetchingEnabled = false
    //    self.collectionView.contentInsetAdjustmentBehavior = .never
    self.containerVC.view.addSubview(self.collectionView)
  }

  override func willMove(toSuperview newSuperview: UIView?) {
    super.willMove(toSuperview: newSuperview)
    var next: UIResponder? = newSuperview
    while next != nil {
      if let vc = next as? UIViewController {
        vc.addChild(self.containerVC)
        break
      }
      next = next?.next
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    self.containerVC.view.frame = bounds
    guard let count = dataSource?.numberOfLists(in: self) else {
      return
    }
    if self.collectionView.frame == CGRect.zero || self.collectionView.bounds.size != bounds.size {
      self.collectionView.frame = bounds
      self.collectionView.collectionViewLayout.invalidateLayout()
      self.collectionView.setContentOffset(
        CGPoint(x: CGFloat(self.currentIndex) * self.collectionView.bounds.size.width, y: 0), animated: false)
    } else {
      self.collectionView.frame = bounds
    }
  }

  func scrolling(from leftIndex: Int, to rightIndex: Int, percent: CGFloat, selectedIndex: Int) {
  }

  func didClickSelectedItem(at index: Int) {
    guard self.checkIndexValid(index) else {
      return
    }
    self.willAppearIndex = -1
    self.willDisappearIndex = -1
    if self.currentIndex != index {
      self.listWillDisappear(at: self.currentIndex)
      self.listWillAppear(at: index)
      self.listDidDisappear(at: self.currentIndex)
      self.listDidAppear(at: index)
    }
  }

  func reloadData() {
    guard let dataSource = self.dataSource else { return }
    if self.currentIndex < 0 || self.currentIndex >= dataSource.numberOfLists(in: self) {
      self.defaultSelectedIndex = 0
      self.currentIndex = 0
    }
    self.validListDict.values.forEach { list in
      if let listVC = list as? UIViewController {
        listVC.removeFromParent()
      }
      list.listView().removeFromSuperview()
    }
    self.validListDict.removeAll()

    self.collectionView.reloadData()

    self.listWillAppear(at: self.currentIndex)
    self.listDidAppear(at: self.currentIndex)
  }

  func initListIfNeeded(at index: Int) {
    guard let dataSource = self.dataSource else { return }
    if dataSource.listContainerView?(self, canInitListAt: index) == false {
      return
    }
    var existedList = self.validListDict[index]
    if existedList != nil {
      // 列表已经创建好了
      return
    }
    existedList = dataSource.listContainerView(self, initListAt: index)
    guard let list = existedList else {
      return
    }
    if let vc = list as? UIViewController {
      self.containerVC.addChild(vc)
    }
    self.validListDict[index] = list
    let cell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0))
    cell?.contentView.subviews.forEach { $0.removeFromSuperview() }
    list.listView().frame = cell?.contentView.bounds ?? CGRect.zero
    cell?.contentView.addSubview(list.listView())
  }

  private func listWillAppear(at index: Int) {
    guard let dataSource = self.dataSource else { return }
    guard self.checkIndexValid(index) else {
      return
    }
    var existedList = self.validListDict[index]
    if existedList != nil {
      existedList?.listWillAppear?()
      if let vc = existedList as? UIViewController {
        vc.beginAppearanceTransition(true, animated: false)
      }
    } else {
      // 当前列表未被创建（页面初始化或通过点击触发的listWillAppear）
      guard dataSource.listContainerView?(self, canInitListAt: index) != false else {
        return
      }
      existedList = dataSource.listContainerView(self, initListAt: index)
      guard let list = existedList else {
        return
      }
      if let vc = list as? UIViewController {
        self.containerVC.addChild(vc)
      }
      self.validListDict[index] = list

      let cell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0))
      cell?.contentView.subviews.forEach { $0.removeFromSuperview() }
      list.listView().frame = cell?.contentView.bounds ?? CGRect.zero
      cell?.contentView.addSubview(list.listView())
      list.listWillAppear?()
      if let vc = list as? UIViewController {
        vc.beginAppearanceTransition(true, animated: false)
      }
    }
  }

  private func listDidAppear(at index: Int) {
    guard self.checkIndexValid(index) else {
      return
    }
    self.currentIndex = index
    let list = self.validListDict[index]
    list?.listDidAppear?()
    if let vc = list as? UIViewController {
      vc.endAppearanceTransition()
    }
  }

  private func listWillDisappear(at index: Int) {
    guard self.checkIndexValid(index) else {
      return
    }
    let list = self.validListDict[index]
    list?.listWillDisappear?()
    if let vc = list as? UIViewController {
      vc.beginAppearanceTransition(false, animated: false)
    }
  }

  private func listDidDisappear(at index: Int) {
    guard self.checkIndexValid(index) else {
      return
    }
    let list = self.validListDict[index]
    list?.listDidDisappear?()
    if let vc = list as? UIViewController {
      vc.endAppearanceTransition()
    }
  }

  private func checkIndexValid(_ index: Int) -> Bool {
    guard let dataSource = self.dataSource else { return false }
    let numberOfLists = dataSource.numberOfLists(in: self)
    if numberOfLists <= 0 || index >= numberOfLists {
      return false
    }
    return true
  }

  private func listDidAppearOrDisappear(scrollView: UIScrollView) {
    let currentIndexPercent = scrollView.contentOffset.x / scrollView.bounds.size.width
    if self.willAppearIndex != -1 || self.willDisappearIndex != -1 {
      let disappearIndex = self.willDisappearIndex
      let appearIndex = self.willAppearIndex
      if self.willAppearIndex > self.willDisappearIndex {
        // 将要出现的列表在右边
        if currentIndexPercent >= CGFloat(self.willAppearIndex) {
          self.willDisappearIndex = -1
          self.willAppearIndex = -1
          self.listDidDisappear(at: disappearIndex)
          self.listDidAppear(at: appearIndex)
        }
      } else {
        // 将要出现的列表在左边
        if currentIndexPercent <= CGFloat(self.willAppearIndex) {
          self.willDisappearIndex = -1
          self.willAppearIndex = -1
          self.listDidDisappear(at: disappearIndex)
          self.listDidAppear(at: appearIndex)
        }
      }
    }
  }
}

extension CategoryViewContainerListCollectionView: UICollectionViewDataSource,
  UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
    -> Int {
    guard let dataSource = dataSource else { return 0 }
    return dataSource.numberOfLists(in: self)
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    cell.contentView.backgroundColor = self.listCellBackgroundColor
    cell.contentView.subviews.forEach { $0.removeFromSuperview() }
    let list = self.validListDict[indexPath.item]
    if list != nil {
      list?.listView().frame = cell.contentView.bounds
      cell.contentView.addSubview(list!.listView())
    }
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    return bounds.size
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView.isTracking || scrollView.isDragging else {
      return
    }
    let percent = scrollView.contentOffset.x / scrollView.bounds.size.width
    let maxCount = Int(round(scrollView.contentSize.width / scrollView.bounds.size.width))
    var leftIndex = Int(floor(Double(percent)))
    leftIndex = max(0, min(maxCount - 1, leftIndex))
    let rightIndex = leftIndex + 1
    if percent < 0 || rightIndex >= maxCount {
      self.listDidAppearOrDisappear(scrollView: scrollView)
      return
    }
    let remainderRatio = percent - CGFloat(leftIndex)
    if rightIndex == self.currentIndex {
      // 当前选中的在右边，用户正在从右边往左边滑动
      if self.validListDict[leftIndex] == nil && remainderRatio < (1 - self.initListPercent) {
        self.initListIfNeeded(at: leftIndex)
      } else if self.validListDict[leftIndex] != nil {
        if self.willAppearIndex == -1 {
          self.willAppearIndex = leftIndex
          self.listWillAppear(at: self.willAppearIndex)
        }
      }

      if self.willDisappearIndex == -1 {
        self.willDisappearIndex = rightIndex
        self.listWillDisappear(at: self.willDisappearIndex)
      }
    } else {
      // 当前选中的在左边，用户正在从左边往右边滑动
      if self.validListDict[rightIndex] == nil && remainderRatio > self.initListPercent {
        self.initListIfNeeded(at: rightIndex)
      } else if self.validListDict[rightIndex] != nil {
        if self.willAppearIndex == -1 {
          self.willAppearIndex = rightIndex
          self.listWillAppear(at: self.willAppearIndex)
        }
      }
      if self.willDisappearIndex == -1 {
        self.willDisappearIndex = leftIndex
        self.listWillDisappear(at: self.willDisappearIndex)
      }
    }
    self.listDidAppearOrDisappear(scrollView: scrollView)
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    // 滑动到一半又取消滑动处理
    if self.willAppearIndex != -1 || self.willDisappearIndex != -1 {
      self.listWillDisappear(at: self.willAppearIndex)
      self.listWillAppear(at: self.willDisappearIndex)
      self.listDidDisappear(at: self.willAppearIndex)
      self.listDidAppear(at: self.willDisappearIndex)
      self.willDisappearIndex = -1
      self.willAppearIndex = -1
    }
  }
}

class CategoryViewListContainerViewController: UIViewController {
  var viewWillAppearClosure: (() -> Void)?
  var viewDidAppearClosure: (() -> Void)?
  var viewWillDisappearClosure: (() -> Void)?
  var viewDidDisappearClosure: (() -> Void)?
  override var shouldAutomaticallyForwardAppearanceMethods: Bool { return false }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewWillAppearClosure?()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.viewDidAppearClosure?()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.viewWillDisappearClosure?()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.viewDidDisappearClosure?()
  }
}

@objc
protocol CategoryViewListContainerViewDelegate {
  func listView() -> UIView
  @objc optional func listWillAppear()
  @objc optional func listDidAppear()
  @objc optional func listWillDisappear()
  @objc optional func listDidDisappear()
}

@objc
protocol CategoryViewListContainerViewDataSource {
  /// 返回list的数量
  func numberOfLists(in listContainerView: CategoryViewContainerListCollectionView) -> Int
  func listContainerView(
    _ listContainerView: CategoryViewContainerListCollectionView, initListAt index: Int
  ) -> CategoryViewListContainerViewDelegate
  @objc optional func listContainerView(
    _ listContainerView: CategoryViewContainerListCollectionView, canInitListAt index: Int
  ) -> Bool
  @objc optional func scrollViewClass(in listContainerView: CategoryViewContainerListCollectionView)
    -> AnyClass
}


/*
 标签选项数据模型设计思路 CategoryViewDataItemModel
 ---
 基本属性
 - index: 标签数据所在的索引
 - isSelected: 标签数据是否被选中
 - itemWidth: 标签数据的宽度
 - isTransitionAnimating: 当前标签数据是否正在进行过渡动画

 具体实现: CategoryViewTitleDataItemModel
 - title: 标签数据的标题
 - titleNumberOfLines: 标签数据的标题的行数
 - titleNormalColor: 标签数据的标题的正常颜色
 - titleCurrentColor: 标签数据的标题的当前颜色
 - titleSelectedColor: 标签数据的标题的选中颜色
 - titleNormalFont: 标签数据的标题的正常字体
 - titleSelectedFont: 标签数据的标题的选中字体
 - textWidth: 标签数据的标题的宽度
 ---
 */

public enum CategoryViewItemSelectedType {
  case unknown
  case code
  case click
  case scroll
}

class CategoryViewBaseDataItemModel {
  var index: Int = 0
  var isSelected: Bool = false
  var itemWidth: CGFloat = 0

  public init() {
  }
}

class CategoryViewTitleDataItemModel: CategoryViewBaseDataItemModel {
  var title: String?
  var titleNumberOfLines: Int = 0
  var titleNormalColor: UIColor = .black
  var titleCurrentColor: UIColor = .black
  var titleSelectedColor: UIColor = .red
  var titleNormalFont: UIFont = UIFont.systemFont(ofSize: 15)
  var titleSelectedFont: UIFont = UIFont.systemFont(ofSize: 15)
  var isTitleMaskEnabled: Bool = false
  var textWidth: CGFloat = 0
}

