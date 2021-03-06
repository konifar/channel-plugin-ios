//
//  ProfileCompletionView.swift
//  ChannelIO
//
//  Created by Haeun Chung on 13/04/2018.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import Foundation
import RxSwift
import UIKit
import PhoneNumberKit

class ProfileCompletionView: ProfileItemBaseView, ProfileContentProtocol {
  let contentView = CompleteActionView()
  var responder: UIView {
    return self
  }
  var didFirstResponder: Bool {
    return false
  }
  
  override var fieldView: Actionable? {
    get {
      return self.contentView
    }
  }
  
  override func initialize() {
    super.initialize()
  }
  
  override func setLayouts() {
    super.setLayouts()
  }
  
  override func configure(model: MessageCellModelType, index: Int?, presenter: UserChatPresenterProtocol?) {
    super.configure(model: model, index: index, presenter: presenter)
    self.indexLabel.isHidden = true
    
    if let index = index, let value = model.profileItems[index].value {
      let unwrapped = unwrap(any: value)
      if self.item?.fieldType == .mobileNumber {
        self.contentView.contentLabel.text = PartialFormatter().formatPartial("\(unwrapped)")
      } else {
        self.contentView.contentLabel.text = "\(unwrapped)"
      }
    }
  }
}
