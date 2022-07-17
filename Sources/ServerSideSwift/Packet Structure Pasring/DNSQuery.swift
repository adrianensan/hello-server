import Foundation

enum DNSRecordType: Hashable {
  case a
  case aaaa
  case cname
  case mx
  case other(UInt16)
  
  static func infer(from value: UInt16) -> Self {
    switch value {
    case 1: return .a
    case 28: return .aaaa
    case 5: return .cname
    case 15: return .mx
    default: return .other(value)
    }
  }
}

enum DNSRecordClass: Hashable {
  case internet
  case other(UInt16)
  
  static func infer(from value: UInt16) -> Self {
    switch value {
    case 1: return .internet
    default: return .other(value)
    }
  }
}

public struct DNSQuery: Hashable {
  var domain: String
  var recordType: DNSRecordType
  var recordClass: DNSRecordClass
}

public struct DNSAnswer: Hashable {
  var domain: String
  var recordType: DNSRecordType
  var recordClass: DNSRecordClass
  var value: String
}
