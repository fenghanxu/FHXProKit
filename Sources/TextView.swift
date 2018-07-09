//
//  TextView.swift
//  Extensions
//
//  Created by BigL on 2017/7/17.
//

import UIKit
import FHXFoundation
import FHXKit

public class TextView: UITextView {
  
  fileprivate var inputHelp: TextViewHelp?
  
  fileprivate let limitLabel = UILabel()
  fileprivate let placeHolderLabel = UILabel()
  
  override open var delegate: UITextViewDelegate? {
    get { return inputHelp }
    set { inputHelp = TextViewHelp(inputDelegate: newValue)
      super.delegate = inputHelp
    }
  }
  
  /// 可被观察属性
  public struct DynamicIvar {
    public var text = Dynamic<String>("")
  }
  
  public var sp = DynamicIvar()
  
  /// 文本框文本
  public override var text: String!{
    set {
      if newValue == text { return }
      super.text = newValue
      lastText = newValue
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
      placeHolderLabel.isHidden = !lastText.isEmpty
      guard wordLimit != Int.max else { return }
      limitLabel.attributedText = attr(beforeStr: "\(lastText.count)", backStr: "/\(wordLimit)字")
    }
  }
  
  /// 禁用项
  public var disable = [InputDisableState.none]
  /// 字数限制
  public var wordLimit = Int.max{
    didSet{ limitLabel.text = "0/\(wordLimit)字" }
  }
  
  /// 占位文字
  public var placeHolder: String?{
    set{ placeHolderLabel.text = newValue }
    get{ return placeHolderLabel.text }
  }
  
  /// 占位文字Font
  public var placeHolderFont: UIFont?{
    set{ placeHolderLabel.font = newValue }
    get{ return placeHolderLabel.font }
  }
  
  /// 限制字体Font
  public var limitFont: UIFont?{
    set{ limitLabel.font = newValue }
    get{ return limitLabel.font }
  }
  
  
  /// 占位文字颜色
  public var placeHolderColor: UIColor{
    set{ placeHolderLabel.textColor = newValue }
    get{ return placeHolderLabel.textColor }
  }
  
  /// 字数限制文字颜色
  public var limitColor: UIColor?
  
  /// 当前字数颜色
  public var currentNumColor: UIColor?
  
  
  /// 是否显示字数限制
  public var isShowWordLimit = false{
    didSet{
      
      limitLabel.isHidden = !isShowWordLimit
    }
  }
  
  public var regexs = [RegexPattern](){
    didSet{
      if regexs == oldValue { return }
      regexs = regexs.filter({ (item) -> Bool in
        return !item.pattern.isEmpty
      })
      clear()
    }
  }
  
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
  
  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    buildUI()
    buildConfig()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    buildUI()
    buildConfig()
  }
  
  //MARK: - Deinitialized
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
}

extension TextView {
  
  fileprivate func buildUI() {
    addSubview(placeHolderLabel)
    addSubview(limitLabel)
    limitLabel.translatesAutoresizingMaskIntoConstraints = false
    placeHolderLabel.translatesAutoresizingMaskIntoConstraints = false
    buildLayout()
    buildSubView()
  }
  
  fileprivate func buildLayout() {
    do {
      let top = NSLayoutConstraint(item: placeHolderLabel,
                                   attribute: .top,
                                   relatedBy: .equal,
                                   toItem: placeHolderLabel.superview,
                                   attribute: .top,
                                   multiplier: 1,
                                   constant: 5)
      let left = NSLayoutConstraint(item: placeHolderLabel,
                                    attribute: .left,
                                    relatedBy: .equal,
                                    toItem: placeHolderLabel.superview,
                                    attribute: .left,
                                    multiplier: 1,
                                    constant: 5)
      let width = NSLayoutConstraint(item: placeHolderLabel,
                                     attribute: .width,
                                     relatedBy: .lessThanOrEqual,
                                     toItem: placeHolderLabel.superview,
                                     attribute: .width,
                                     multiplier: 1,
                                     constant: 0)
      let height = NSLayoutConstraint(item: placeHolderLabel,
                                      attribute: .height,
                                      relatedBy: .lessThanOrEqual,
                                      toItem: placeHolderLabel.superview,
                                      attribute: .height,
                                      multiplier: 1,
                                      constant: 0)
      width.priority = UILayoutPriority(rawValue: 750)
      height.priority = UILayoutPriority(rawValue: 750)
      self.addConstraints([top,left,width,height])
      
    }
    
    do {
      let bottom = NSLayoutConstraint(item: limitLabel,
                                      attribute: .bottom,
                                      relatedBy: .equal,
                                      toItem: limitLabel.superview,
                                      attribute: .centerY,
                                      multiplier: 2,
                                      constant: -10)
      let left = NSLayoutConstraint(item: limitLabel,
                                    attribute: .right,
                                    relatedBy: .equal,
                                    toItem: limitLabel.superview,
                                    attribute: .centerX,
                                    multiplier: 2,
                                    constant: -15)
      let width = NSLayoutConstraint(item: limitLabel,
                                     attribute: .width,
                                     relatedBy: .lessThanOrEqual,
                                     toItem: limitLabel.superview,
                                     attribute: .width,
                                     multiplier: 1,
                                     constant: 0)
      let height = NSLayoutConstraint(item: limitLabel,
                                      attribute: .height,
                                      relatedBy: .lessThanOrEqual,
                                      toItem: limitLabel.superview,
                                      attribute: .height,
                                      multiplier: 1,
                                      constant: 0)
      bottom.priority = UILayoutPriority(rawValue: 800)
      left.priority = UILayoutPriority(rawValue: 800)
      width.priority = UILayoutPriority(rawValue: 750)
      height.priority = UILayoutPriority(rawValue: 750)
      self.addConstraints([bottom,left,width,height])
    }
    
  }
  
  private func buildSubView() {
    placeHolderLabel.textColor = UIColor(value: 0xe5e5e5)
    limitLabel.textAlignment = .right
    limitLabel.textColor = UIColor(value: 0xe5e5e5)
  }
  
}

// MARK: - Config
extension TextView{
  
  func buildConfig() {
    autocorrectionType = .no
    //delegate = nil
    buildNotifications()
  }
  
  fileprivate func buildNotifications() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(textView(changed:)),
                                           name: Notification.Name.UITextViewTextDidChange,
                                           object: nil)
  }
  
  /// 富文本的设置
  func attr(beforeStr: String, backStr: String) -> NSMutableAttributedString {
    var currentColor = currentNumColor ?? UIColor(value: 0xe5e5e5)
    let limitTmpColor = limitColor ?? UIColor(value: 0xe5e5e5)
    if (Int(beforeStr) ?? 0) == 0 { currentColor = UIColor(value: 0xe5e5e5) }
    let beforeColor = [NSAttributedStringKey.foregroundColor: currentColor]
    let backColor   = [NSAttributedStringKey.foregroundColor: limitTmpColor]
    
    let priceAttr = NSMutableAttributedString(string: beforeStr,
                                              attributes: beforeColor)
    let unitAttr = NSAttributedString(string: backStr,
                                      attributes: backColor )
    priceAttr.append(unitAttr)
    return priceAttr
  }
}

extension TextView {
  @objc fileprivate func textView(changed not: Notification) {
    guard markedTextRange == nil else { return }
    let range = selectedTextRange
    guard let textView = not.object as? TextView else { return }
    if self != textView { return }
    guard let text = textView.text else { return }
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

fileprivate class TextViewHelp: InputDelegate, UITextViewDelegate {
  
  @available(iOS 2.0, *)
  func textViewShouldBeginEditing(_ textView: UITextView) -> Bool{
    if let input = textView as? TextView {
      input.placeHolderLabel.isHidden = true
    }
    return inputDelegate?.textViewShouldBeginEditing?(textView) ?? true
  }
  
  @available(iOS 2.0, *)
  public func textViewShouldEndEditing(_ textView: UITextView) -> Bool{
    if let input = textView as? TextView {
      input.placeHolderLabel.isHidden = !input.lastText.isEmpty
    }
    return inputDelegate?.textViewShouldEndEditing?(textView) ?? true
  }
  
  @available(iOS 2.0, *)
  public func textViewDidBeginEditing(_ textView: UITextView){
    inputDelegate?.textViewDidBeginEditing?(textView)
  }
  
  @available(iOS 2.0, *)
  public func textViewDidEndEditing(_ textView: UITextView){
    inputDelegate?.textViewDidEndEditing?(textView)
  }
  
  @available(iOS 2.0, *)
  public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool{
    let flag = inputDelegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true
    
    guard let input = textView as? TextView else { return flag }
    if input.markedTextRange != nil {
      input.placeHolderLabel.isHidden = true
      return flag
    }
    if TextInput.deal(illegal: text).isChanged {
      input.sendMsg(type: .isillegal)
      return false
    }
    var isMatch   = true
    let isDelete  = range.length > 0 && text.isEmpty
    let currentText = TextInput.deal(changed:  input,
                                     lastText: input.lastText,
                                     string:   text,
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
  
  @available(iOS 2.0, *)
  public func textViewDidChange(_ textView: UITextView){
    inputDelegate?.textViewDidChange?(textView)
  }
  
  @available(iOS 2.0, *)
  public func textViewDidChangeSelection(_ textView: UITextView){
    inputDelegate?.textViewDidChangeSelection?(textView)
  }
  
  @available(iOS 10.0, *)
  public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool{
    return inputDelegate?.textView?(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) ?? true
  }
  
  @available(iOS 10.0, *)
  public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool{
    return inputDelegate?.textView?(textView, shouldInteractWith: textAttachment, in: characterRange, interaction: interaction) ?? true
    
  }
  
  
  @available(iOS, introduced: 7.0, deprecated: 10.0, message: "Use textView:shouldInteractWithURL:inRange:forInteractionType: instead")
  public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool{
    return inputDelegate?.textView?(textView, shouldInteractWith: URL, in: characterRange) ?? true
  }
  
  @available(iOS, introduced: 7.0, deprecated: 10.0, message: "Use textView:shouldInteractWithTextAttachment:inRange:forInteractionType: instead")
  public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange) -> Bool{
    return inputDelegate?.textView?(textView, shouldInteractWith: textAttachment, in: characterRange) ?? true
  }
}





