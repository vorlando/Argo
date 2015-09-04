public enum DecodeError: ErrorType {
  case TypeMismatch(expected: String, actual: String)
  case MissingKey(String)
}

extension DecodeError: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .TypeMismatch(expected, actual): return "TypeMismatch(Expected \(expected), got \(actual))"
    case let .MissingKey(s): return "MissingKey(\(s))"
    }
  }
}

public enum Decoded<T> {
  case Success(T)
  case Failure(DecodeError)

  public var value: T? {
    switch self {
    case let .Success(value): return value
    default: return .None
    }
  }
}

public extension Decoded {
  static func optional<T>(x: Decoded<T>) -> Decoded<T?> {
    switch x {
    case let .Success(value): return .Success(.Some(value))
    case .Failure(.MissingKey): return .Success(.None)
    case let .Failure(.TypeMismatch(x)): return .Failure(.TypeMismatch(x))
    }
  }

  static func fromOptional<T>(x: T?) -> Decoded<T> {
    switch x {
    case let .Some(value): return .Success(value)
    case .None: return .typeMismatch(".Some(\(T.self))", actual: ".None")
    }
  }
}

public extension Decoded {
  static func typeMismatch<T, U: CustomStringConvertible>(expected: String, actual: U) -> Decoded<T> {
    return .typeMismatch(expected, actual: "\(actual)")
  }

  static func typeMismatch<T>(expected: String, actual: String) -> Decoded<T> {
    return .Failure(.TypeMismatch(expected: expected, actual: "\(actual)"))
  }

  static func missingKey<T>(name: String) -> Decoded<T> {
    return .Failure(.MissingKey(name))
  }
}

extension Decoded: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .Success(value): return "Success(\(value))"
    case let .Failure(error): return "Failure(\(error))"
    }
  }
}

public extension Decoded {
  func map<U>(f: T -> U) -> Decoded<U> {
    switch self {
    case let .Success(value): return .Success(f(value))
    case let .Failure(error): return .Failure(error)
    }
  }

  func apply<U>(f: Decoded<T -> U>) -> Decoded<U> {
    switch f {
    case let .Success(function): return self.map(function)
    case let .Failure(error): return .Failure(error)
    }
  }

  func flatMap<U>(f: T -> Decoded<U>) -> Decoded<U> {
    switch self {
    case let .Success(value): return f(value)
    case let .Failure(error): return .Failure(error)
    }
  }
}

public func pure<A>(a: A) -> Decoded<A> {
  return .Success(a)
}

// MARK: Monadic Operators

/**
  flatMap a function over a `Decoded` value (right associative)
  
  - If the value is `.Failure`, the function will not be evaluated and this will return the failure info
  - If the value is `.Success`, the function will be applied to the unwrapped value

  - parameter a: A value of type `Decoded<A>`
  - parameter f: A transformation function from type `A` to type `Decoded<B>`

  - returns: A value of type `Decoded<U>`
*/
public func >>- <A, B>(a: Decoded<A>, f: A -> Decoded<B>) -> Decoded<B> {
  return a.flatMap(f)
}

/**
  map a function over a `Decoded` value

  - If the value is `.Failure`, the function will not be evaluated and this will return the failure info
  - If the value is `.Success`, the function will be applied to the unwrapped value

  - parameter f: A transformation function from type `A` to type `B`
  - parameter a: A value of type `Decoded<A>`

  - returns: A value of type `Decoded<B>`
*/
public func <^> <A, B>(f: A -> B, a: Decoded<A>) -> Decoded<B> {
  return a.map(f)
}

/**
  apply a `Decoded` function to a `Decoded` value
  - If the function is `.Failure`, this will return the function's failure info
  - If the function is a `.Success` case and the value is `Failure`, this will return the value's failure info
  - If both self and the function are `.Success`, the function will be applied to the unwrapped value

  - parameter f: A `Decoded` transformation function from type `A` to type `B`

  - returns: A value of type `Decoded<B>`
*/
public func <*> <A, B>(f: Decoded<A -> B>, a: Decoded<A>) -> Decoded<B> {
  return a.apply(f)
}
