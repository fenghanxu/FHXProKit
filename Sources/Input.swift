//
//  Input.swift
//  Pods
//
//  Created by BigL on 2017/7/13.
//
//

import UIKit
import FHXFoundation

/// 禁用状态
///
/// - none: 默认, 不禁用
/// - all: 全部禁用
/// - cut: 剪切
/// - copy: 复制
/// - paste: 粘贴
/// - select: 选择
/// - selectAll: 全选
/// - delete: 删除
public enum InputDisableState {
  case none
  case all
  case cut
  case copy
  case paste
  case select
  case selectAll
  case delete
}

enum InputKitMessage {
  case isOverLimited
  case isillegal
  case isUnmatch
  case isMatch

  var selector: Selector {
    switch self {
    case .isMatch:       return Selector(("textInputWithIsMatch:"))
    case .isUnmatch:     return Selector(("textInputWithIsUnmatch:"))
    case .isillegal:     return Selector(("textInputWithIsillegal:"))
    case .isOverLimited: return Selector(("textInputWithIsOverLimited:"))
    }
  }
}

enum MatchState: Int{
  case inputing
  case match
  case unMatch
}

public protocol TextInputDeledate {
  /// 超过字符限制回调
  func textInput(isOverLimited target: AnyObject)
  /// 非法输入回调
  func textInput(isillegal target: AnyObject)
  /// 规则不匹配回调
  func textInput(isUnmatch target: AnyObject)
  /// 规则匹配回调
  func textInput(isMatch   target: AnyObject)
}

class InputDelegate: NSObject {
  private(set) var inputDelegate: AnyObject?

  init(inputDelegate: AnyObject?) {
    self.inputDelegate = inputDelegate
  }

  func sendMsgTo(obj: AnyObject, with component: AnyObject, sel: Selector) {
    guard obj.responds(to: sel) else { return }
    let _ = obj.perform(sel, with: component)
  }
}

/// 文本输入辅助处理类
class TextInput {
  /// 处理工具条
  ///
  /// - Parameters:
  ///   - respoder: textView & textfield
  ///   - disable: 禁用项
  ///   - action: 执行方法名
  /// - Returns: 能否执行
  class func deal(_ respoder: UIResponder,
                  disable: [InputDisableState],
                  action: Selector) -> Bool {
    if disable.contains(.all) { return false }
    if disable.contains(.cut), action == #selector(respoder.cut(_:)) { return false }
    if disable.contains(.copy), action == #selector(respoder.copy(_:)) { return false }
    if disable.contains(.paste), action == #selector(respoder.paste(_:)) { return false }
    if disable.contains(.select), action == #selector(respoder.select(_:)) { return false }
    if disable.contains(.selectAll), action == #selector(respoder.selectAll(_:)) { return false }
    if disable.contains(.delete), action == #selector(respoder.delete(_:)) { return false }
    return true
  }

  /// 非法字符过滤
  ///
  /// - Parameter text: 文本
  /// - Returns: 是否含有非法字符,过滤后文本
  class func deal(illegal text: String) -> (isChanged: Bool,text: String) {
    var result = text
    if text.has(.emojis)  { result = text.removed(.emojis) }
    if text.has(.illegal) { result = text.removed(.illegal) }
    return (result != text, result)
  }

  /// 字符限制
  ///
  /// - Parameters:
  ///   - text: 当前文本
  ///   - lastText: 历史文本
  ///   - limit: 字数限制
  /// - Returns: 是否超过限制,处理后的当前文本,处理后的历史文本
  class func deal(changed text: String,
                  lastText: String,
                  limit: Int) -> (isOverLimit: Bool,text: String,lastText: String) {
    let isOverLimit = text.count > limit
    return  isOverLimit ? (true,lastText,lastText) : (false,text,text)
  }

  /// 获取当前文本
  ///
  /// - Parameters:
  ///   - input: textView & textfield
  ///   - lastText: 历史文本
  ///   - string: 输入字符
  ///   - range: 输入字符范围
  /// - Returns: 当前文本
  class func deal(changed input: UITextInput,
                  lastText: String,
                  string: String,
                  range: NSRange) -> String {
    var result = ""
    if range.length > 0 && string.isEmpty {
      var start = ""
      var end = ""
      if range.location == 0 { start = "" }
      else{ start = lastText[0..<range.location] }
      if range.length == lastText.count { end = "" }
      else{ end = lastText[range.location + range.length..<lastText.count] }
      result = start + end
    }else{
      if input.markedTextRange == nil {
        var start = ""
        var end = ""
        if range.location == 0 { start = "" }
        else{ start = lastText[0..<range.location] }
        if range.length == lastText.count { end = "" }
        // 手写键盘不符合该判断
        else if lastText.count > range.location + range.length {
          end = lastText[range.location + range.length..<lastText.count]
        }
        result = start + string + end
      }else{
        result = lastText
      }
    }
    return result
  }

  class func inputingMatch(text: String, regexs: [RegexPattern]) -> Bool {
    if regexs.isEmpty { return true }
    for item in regexs{
      if !inputing(text: text, match: item) { return false }
    }
    return true
  }

  private class func inputing(text: String, match: RegexPattern) -> Bool {
    switch match {
    case .none: return true
    case .double:
      guard text.double != nil else { return false }
      if text.hasPrefix("00") { return false }
      return text =~ match
    case .isPositiveInteger,.custom:
      return text =~ match
    case .phone:
      guard text.int != nil, text.count <= 11 else{ return false }
      return true
    default: return true
    }
  }

 class func inputedMatch(text: String, regexs: [RegexPattern]) -> MatchState {
    if regexs.isEmpty { return .match }
    for item in regexs{
      switch inputed(text: text, match: item) {
      case .inputing: return .inputing
      case .unMatch:  return .unMatch
      case .match:    break
      }
    }
    return .match
  }

  private class func inputed(text: String, match: RegexPattern) -> MatchState {
    switch match {
    case .double:
      guard text.double != nil else { return .unMatch }
      if text.hasPrefix("00") { return .unMatch }
      return text =~ match ? .match : .unMatch
    case .isPositiveInteger,.custom:
      return text =~ match ? .match : .unMatch
    case .phone:
      if text.count < 11 { return .inputing }
      if text.count == 11 { return text =~ match ? .match : .unMatch }
      return .unMatch
    default: return .inputing
    }
  }

}













