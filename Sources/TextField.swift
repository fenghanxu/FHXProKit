//
//  TextField.swift
//  B7iOSShop
//
//  Created by 膳品科技 on 2016/11/26.
//  Copyright © 2016年 spzjs.b7iosshop.com. All rights reserved.
//

import UIKit
import FHXFoundation

@IBDesignable
open class TextField: UITextField {
  fileprivate var inputHelp: TextFieldHelp?

  override open var delegate: UITextFieldDelegate? {
    get { return inputHelp }
    set { inputHelp = TextFieldHelp(inputDelegate: newValue)
      super.delegate = inputHelp
    }
  }



  /// 禁用项
  public var disable = [InputDisableState.none]
  /// 字数限制
  @IBInspectable public var wordLimit = Int.max

  public var regexs = [RegexPattern](){
    didSet{
      if regexs == oldValue { return }
      regexs = regexs.filter({ (item) -> Bool in
        return !item.pattern.isEmpty
      })
      clear()
    }
  }

  /// 可被观察属性
  public struct DynamicIvar {
    public var text = Dynamic<String>("")
  }

  public var sp = DynamicIvar()

  /// 文本框文本
  open override var text: String?{
    set {
      if newValue == text { return }
      super.text = newValue
      lastText = newValue ?? ""
    }
    get {
      return super.text
    }
  }

  /// 历史文本
  fileprivate var lastText = ""{
    didSet{
      if lastText == oldValue { return }
      sp.text.value = lastText
    }
  }

  open override var isEditing: Bool {
    if placeholderRect != CGRect.zero {
      placeholderLabel.frame = placeholderRect
    }
    return super.isEditing
  }

  var placeholderRect = CGRect.zero

  lazy var placeholderLabel: UILabel = {
    guard let label = self.value(forKey: "_placeholderLabel") as? UILabel else{
      return UILabel()
    }
    return label
  }()

  override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if TextInput.deal(self, disable: disable, action: action) {
      return super.canPerformAction(action, withSender: sender)
    }
    return false
  }

  func clear() {
    text?.removeAll()
    lastText.removeAll()
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    buildConfig()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    buildConfig()
  }

  public var placeholderAlignment: PlaceholderAlignment = .none

  public enum PlaceholderAlignment {
    case top(CGFloat)
    case bottom(CGFloat)
    case centerY
    case none
  }

  open override func drawPlaceholder(in rect: CGRect) {
    super.drawPlaceholder(in: rect)
    var labelFarme = placeholderLabel.frame
    switch placeholderAlignment {
    case .top(let margin):
      labelFarme.origin.y = margin
    case .bottom(let margin):
      labelFarme.origin.y = frame.height - placeholderLabel.frame.height - margin
    case .centerY:
      labelFarme.origin.y = frame.height / 2
    case .none:
      return
    }
    placeholderLabel.frame = labelFarme
    placeholderRect = labelFarme
  }

  //MARK: - Deinitialized
  deinit {
    NotificationCenter.default.removeObserver(self)
  }

}

// MARK: - Config
extension TextField{

  func buildConfig() {
    autocorrectionType = .no
    delegate = nil
    buildNotifications()
  }

  fileprivate func buildNotifications() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(textField(changed:)),
                                           name: Notification.Name.UITextFieldTextDidChange,
                                           object: nil)
  }

}

extension TextField {
  @objc fileprivate func textField(changed not: Notification) {
    guard markedTextRange == nil else { return }
    let range = selectedTextRange
    guard let textField = not.object as? UITextField else { return }
    if self != textField { return }
    guard let text = textField.text else { return }
    let result1 = TextInput.deal(illegal: text)
    let result2 = TextInput.deal(changed: result1.text,
                                 lastText: lastText,
                                 limit: wordLimit)
    let result3 = TextInput.inputedMatch(text: result2.text, regexs: regexs)
    if result1.isChanged { sendMsg(type: .isillegal) }
    if result2.isOverLimit { sendMsg(type: .isOverLimited) }
    switch result3 {
    case .unMatch: sendMsg(type: .isUnmatch)
    case .match: sendMsg(type: .isMatch)
    case .inputing: break
    }
    self.text = result2.text
    self.lastText = result2.lastText
    selectedTextRange = range
  }

  fileprivate func sendMsg(type: InputKitMessage) {
    guard let delegate = self.inputHelp,
      let inputDelegate = inputHelp?.inputDelegate else {
        return
    }
    delegate.sendMsgTo(obj: inputDelegate, with: self, sel: type.selector)
  }
}

fileprivate class TextFieldHelp: InputDelegate, UITextFieldDelegate {

  @available(iOS 2.0, *)
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
   return inputDelegate?.textFieldShouldBeginEditing?(textField) ?? true
  }

  @available(iOS 2.0, *)
  func textFieldDidBeginEditing(_ textField: UITextField) {
    inputDelegate?.textFieldDidBeginEditing?(textField)
  }

  @available(iOS 2.0, *)
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
    return inputDelegate?.textFieldShouldEndEditing?(textField) ?? true
  }

  @available(iOS 2.0, *)
  func textFieldDidEndEditing(_ textField: UITextField) {
    inputDelegate?.textFieldDidEndEditing?(textField)
  }

  @available(iOS 2.0, *)
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    return inputDelegate?.textFieldShouldClear?(textField) ?? true
  }

  @available(iOS 2.0, *)
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    return inputDelegate?.textFieldShouldReturn?(textField) ?? true
  }

  @available(iOS 10.0, *)
  func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
    inputDelegate?.textFieldDidEndEditing?(textField, reason: reason)
    inputDelegate?.textFieldDidEndEditing?(textField)
  }

  @available(iOS 2.0, *)
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let flag = inputDelegate?.textField?(textField,shouldChangeCharactersIn: range, replacementString: string) ?? true

    guard let input = textField as? TextField else { return flag }
    if input.markedTextRange != nil { return flag }
    if TextInput.deal(illegal: string).isChanged {
      input.sendMsg(type: .isillegal)
      return false
    }
    var isMatch   = true
    let isDelete  = range.length > 0 && string.isEmpty
    let currentText = TextInput.deal(changed:  input,
                                     lastText: input.lastText,
                                     string:   string,
                                     range:    range)
    // 字符限制
    if TextInput.deal(changed:  currentText,
                      lastText: input.lastText,
                      limit:    input.wordLimit).isOverLimit {
      input.sendMsg(type: .isOverLimited)
      return isDelete
    }

    // 字符串匹配
    isMatch = TextInput.inputingMatch(text: currentText, regexs: input.regexs)
    let result = flag && ( isMatch || isDelete)
    if !result { input.sendMsg(type: .isUnmatch) }
    return result
  }
}

