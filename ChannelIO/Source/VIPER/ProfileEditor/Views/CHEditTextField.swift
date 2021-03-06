//
//  CHEditTextField.swift
//  ChannelIO
//
//  Created by R3alFr3e on 4/24/19.
//  Copyright © 2019 ZOYI. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

protocol CHFieldDelegate: class {
  var field: UITextField { get }
  func getText() -> String
  func setText(_ value: String)
  func isValid() -> Observable<Bool>
  func hasChanged() -> Observable<String>
}

enum EditFieldType {
  case name
  case phone
  case text
  case number
}

enum EntityType {
  case user
  case none
}

final class CHEditTextField : BaseView {
  let topDivider = UIView().then {
    $0.backgroundColor = CHColors.dark20
  }
  
  let field = UITextField().then {
    $0.font = UIFont.systemFont(ofSize: 17)
    $0.textColor = CHColors.dark
    $0.clearButtonMode = .whileEditing
  }
  
  let botDivider = UIView().then {
    $0.backgroundColor = CHColors.dark20
  }
  
  let changeSubject = PublishRelay<String>()
  let validSubject = PublishSubject<Bool>()
  var fieldType: EditFieldType = .text
  
  convenience init(text: String = "", type: EditFieldType = .text, placeholder: String) {
    self.init(frame: CGRect.zero)
    self.field.text = text
    self.field.placeholder = placeholder
    self.fieldType = type
    
    if type == .number {
      self.field.keyboardType = .decimalPad
    }
  }
  
  override func initialize() {
    super.initialize()
    
    self.field.addTarget(
      self,
      action: #selector(textFieldDidChange(_:)),
      for: .editingChanged)
    
    self.backgroundColor = UIColor.white
    self.addSubview(self.field)
    self.addSubview(self.topDivider)
    self.addSubview(self.botDivider)
  }
  
  override func setLayouts() {
    super.setLayouts()
    
    self.topDivider.snp.makeConstraints { (make) in
      make.leading.equalToSuperview()
      make.trailing.equalToSuperview()
      make.top.equalToSuperview()
      make.height.equalTo(0.33)
    }
    
    self.field.snp.makeConstraints { (make) in
      make.leading.equalToSuperview().inset(20)
      make.trailing.equalToSuperview()
      make.top.equalToSuperview()
      make.bottom.equalToSuperview()
    }
    
    self.botDivider.snp.makeConstraints { (make) in
      make.leading.equalToSuperview()
      make.trailing.equalToSuperview()
      make.bottom.equalToSuperview()
      make.height.equalTo(0.33)
    }
  }
}

extension CHEditTextField: CHFieldDelegate {
  func getText() -> String {
    return self.field.text ?? ""
  }
  
  func setText(_ value: String) {
    self.field.text = value
  }
  
  func isValid() -> Observable<Bool> {
    return self.validSubject
  }
  
  @objc func textFieldDidChange(_ textField: UITextField) {
    self.validSubject.onNext(true)
    if let text = textField.text {
      self.changeSubject.accept(text)
    }
  }
  
  func hasChanged() -> Observable<String> {
    return self.changeSubject.asObservable()
  }
}

