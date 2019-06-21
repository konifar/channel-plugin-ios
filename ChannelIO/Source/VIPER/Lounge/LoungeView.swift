//
//  LoungeView.swift
//  ChannelIO
//
//  Created by Haeun Chung on 23/04/2019.
//  Copyright © 2019 ZOYI. All rights reserved.
//

import UIKit
import RxSwift
import SnapKit
import SVProgressHUD

class LoungeView: BaseViewController, LoungeViewProtocol {
  struct Metrics {
    static let contentSide = 8.f
    static let contentBetween = 20.f
    static let dismissTop = 7.f
    static let dismissSize = 30.f
    static let dismissTrailing = 12.f
    static let externalHeight = 70.f
    static let headerHeight = 270.f
    static let scrollInsetTop = 140.f
    static let scrollInsetBottom = 20.f
    static let watermarkHeight = 40.f
  }
  
  var presenter: LoungePresenterProtocol?
  
  var scrollView = UIScrollView()
  let headerView = LoungeHeaderView()
  let mainView = LoungeMainView()
  let externalView = LoungeExternalAppsView()
  let watermarkView = WatermarkView()
  
  var dismissButton = CHButtonFactory.dismiss().then {
    $0.alpha = 1
  }
  
  var disposeBag = DisposeBag()
  
  var scrollTopConstraint: Constraint?
  var mainHeightConstraint: Constraint?
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return self.navigationController?.preferredStatusBarStyle ?? .lightContent
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    self.view.isHidden = true
    self.view.backgroundColor = CHColors.paleGreyFour
    
    self.initViews()
    self.initScrollView()
    self.presenter?.viewDidLoad()
    
    NotificationCenter.default
      .rx.notification(Notification.Name.Channel.enterForeground)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] (_) in
        if self?.isVisible() == true {
          self?.presenter?.prepare(fetch: true)
        }
      }).disposed(by: self.disposeBag)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.isNavigationBarHidden = true
    self.presenter?.prepare(fetch: false)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.presenter?.cleanup()
  }
  
  override func setupConstraints() {
    super.setupConstraints()
    
    self.headerView.snp.makeConstraints { (make) in
      make.height.equalTo(Metrics.headerHeight)
      make.top.equalToSuperview()
      make.leading.equalToSuperview()
      make.trailing.equalToSuperview()
    }
    
    self.dismissButton.snp.makeConstraints { [weak self] (make) in
      guard let `self` = self else { return }
      if #available(iOS 11.0, *) {
        make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(Metrics.dismissTop)
      } else {
        make.top.equalToSuperview().inset(Metrics.dismissTop)
      }
      make.height.equalTo(Metrics.dismissSize)
      make.width.equalTo(Metrics.dismissSize)
      make.trailing.equalToSuperview().inset(Metrics.dismissTrailing)
    }
    
    self.scrollView.snp.makeConstraints { [weak self] (make) in
      guard let `self` = self else { return }
      if #available(iOS 11.0, *) {
        self.scrollTopConstraint = make.top
          .equalTo(self.view.safeAreaLayoutGuide.snp.top).constraint
      } else {
        self.scrollTopConstraint = make.top
          .equalToSuperview().constraint
      }
      make.leading.equalToSuperview().inset(Metrics.contentSide)
      make.trailing.equalToSuperview().inset(Metrics.contentSide)
      make.bottom.equalToSuperview()
    }
    
    self.mainView.snp.makeConstraints { [weak self] (make) in
      make.top.equalToSuperview()
      make.leading.equalToSuperview()
      make.trailing.equalToSuperview()
      make.width.equalTo(UIScreen.main.bounds.width - Metrics.contentSide * 2)
      self?.mainHeightConstraint = make.height.equalTo(340).constraint
    }
    
    self.externalView.snp.makeConstraints { [weak self] (make) in
      guard let `self` = self else { return }
      make.height.equalTo(Metrics.externalHeight)
      make.top.equalTo(self.mainView.snp.bottom).offset(Metrics.contentBetween)
      make.leading.greaterThanOrEqualToSuperview()
      make.trailing.lessThanOrEqualToSuperview()
      make.centerX.equalToSuperview()
    }
    
    self.watermarkView.snp.makeConstraints { [weak self] (make) in
      guard let `self` = self else { return }
      if #available(iOS 11.0, *) {
        make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
      } else {
        make.bottom.equalToSuperview()
      }
      make.leading.equalToSuperview()
      make.trailing.equalToSuperview()
      make.height.equalTo(Metrics.watermarkHeight)
    }
  }
  
  func initViews() {
    self.view.addSubview(self.headerView)

    self.view.addSubview(self.scrollView)
    self.scrollView.addSubview(self.mainView)
    self.mainView.signalForChat().subscribe(onNext: { [weak self] (chat) in
      self?.presenter?.didClickOnChat(with: chat.chatId, animated: true, from: self)
    }).disposed(by: self.disposeBag)
    self.mainView.signalForNew().subscribe(onNext: { [weak self] (_) in
      self?.presenter?.didClickOnNewChat(from: self)
    }).disposed(by: self.disposeBag)
    self.mainView.signalForMore().subscribe(onNext: { [weak self] (_) in
      self?.presenter?.didClickOnSeeMoreChat(from: self)
    }).disposed(by: self.disposeBag)
    self.mainView.refreshSignal.subscribe(onNext: { [weak self] (_) in
      self?.presenter?.didClickOnRefresh(for: .mainContent)
    }).disposed(by: self.disposeBag)
    
    self.scrollView.addSubview(self.externalView)
    self.externalView.clickSignal.subscribe(onNext: { [weak self] (source) in
      self?.presenter?.didClickOnExternalSource(with: source, from: self)
    }).disposed(by: self.disposeBag)
    self.externalView.refreshSignal.subscribe(onNext: { [weak self] (_) in
      self?.presenter?.didClickOnRefresh(for: .externalSource)
    }).disposed(by: self.disposeBag)
    self.view.addSubview(self.dismissButton)
    
    self.view.addSubview(self.watermarkView)
    self.watermarkView.signalForClick().subscribe(onNext: { [weak self] _ in
      self?.presenter?.didClickOnWatermark()
    }).disposed(by: self.disposeBag)
  }
  
  func initScrollView() {
    self.scrollView.delegate = self
    self.scrollView.bounces = false
    self.scrollView.showsVerticalScrollIndicator = false
    self.scrollView.showsHorizontalScrollIndicator = false
    self.scrollView.contentInset = UIEdgeInsets(
      top: Metrics.scrollInsetTop,
      left: 0,
      bottom: Metrics.scrollInsetBottom,
      right: 0)
    self.scrollView.backgroundColor = .clear
    
    let gesture = UITapGestureRecognizer(target: self, action: #selector(tapCheck(_:)))
    gesture.delegate = self
    self.scrollView.addGestureRecognizer(gesture)
  }
}

extension LoungeView: UIGestureRecognizerDelegate {
  @objc func tapCheck(_ gesture: UITapGestureRecognizer) {
    if self.headerView.dismissButton.frame.contains(gesture.location(in: self.view)) {
      self.presenter?.didClickOnDismiss()
    }
    else if self.headerView.settingButton.frame.contains(gesture.location(in: self.view)) {
      self.presenter?.didClickOnSetting(from: self)
    }
    else if self.headerView.operationView.frame.contains(gesture.location(in: self.headerView.textContainerView)) &&
      self.headerView.operationView.isHidden == false {
      self.presenter?.didClickOnHelp(from: self)
    }
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    return touch.view?.isDescendant(of: self.mainView) == false
  }
}

extension LoungeView {
  func reloadContents() {
    self.headerView.reloadContent()
    self.mainView.reloadContent()
    self.externalView.reloadContent()
    self.watermarkView.reloadContent()
  }
  
  func displayReady() {
    self.view.isHidden = false
    SVProgressHUD.dismiss()
  }
  
  func displayHeader(with model: LoungeHeaderViewModel) {
    self.headerView.configure(model: model)
    self.watermarkView.isHidden = model.plugin.showPoweredBy == false
  }
  
  func displayMainContent(activeChats: [UserChatCellModel], inactiveChats: [UserChatCellModel], welcomeModel: UserChatCellModel?) {
    self.mainView.configure(activeChats: activeChats, inactiveChats: inactiveChats, welcomeModel: welcomeModel)
    self.mainHeightConstraint?.update(offset: self.mainView.viewHeight)
  }
  
  func displayExternalSources(with models: [LoungeExternalSourceModel]) {
    self.externalView.configure(with: models)
  }
  
  func displayError(for type: LoungeSectionType) {
    switch type {
    case .header: self.headerView.displayError()
    case .mainContent: self.mainView.displayError()
    case .externalSource: self.externalView.displayError()
    }
  }
}

extension LoungeView: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let progress = (Metrics.scrollInsetTop + scrollView.contentOffset.y)/Metrics.scrollInsetTop
    self.dismissButton.alpha = progress
    self.headerView.change(with: 1 - progress)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    var height: CGFloat = 0
    height += self.mainView.frame.size.height
    height += self.externalView.frame.size.height
    self.scrollView.contentSize = CGSize(width: self.scrollView.frame.width, height: height)
    //draw shadow once if watermark doesn't have one
  }
}