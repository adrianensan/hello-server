import Foundation

protocol IPHeader {
  var version: IPVersion { get }
  var headerSize: Int { get }
  var `protocol`: IPProtocol { get }
}
