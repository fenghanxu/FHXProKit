//
//  Dynamic.swift
//  Pods
//
//  Created by BigL on 2017/7/17.
//
//

import UIKit

public struct Dynamic<T> {
  public typealias Listener = (T) -> Void
  public var listener: Listener?

  public mutating func bind(listener: Listener?) {
    self.listener = listener
  }

  public mutating func bindAndFire(listener: Listener?) {
    self.listener = listener
    listener?(value)
  }

  public var value: T {
    didSet {
      listener?(value)
    }
  }

  public init(_ v: T) {
    value = v
  }
}
