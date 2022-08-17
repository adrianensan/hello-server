import Foundation

import HelloCore

public enum DNSPacketParser {
  
  public struct DomainMappings {
    public var domains: Set<String> = []
    public var ipv4Addresses: Set<String> = []
    public var ipv6Addresses: Set<String> = []
  }
    
  
  // Parse minimal data needed to check DNS packets
  private static func parseHeaders(from dataReader: DataReader, isRequest: Bool) -> DNSHeader? {
    // Parse IPVersion from IPHeader
    guard let ipVersion: IPVersion = .infer(fromFirstHeaderByte: dataReader.byte()) else {
      return nil
    }
    
    let ipHeader: IPHeader?
    switch ipVersion {
    case .ipv4: ipHeader = IPV4Header.parse(from: dataReader)
    case .ipv6: ipHeader = IPV6Header.parse(from: dataReader)
    }
    
    guard let ipHeader = ipHeader else { return nil }
    dataReader.advanceCursor(by: ipHeader.headerSize)
    
    let protocolHeader: ProtocolHeader?
    switch ipHeader.protocol {
    case .udp: protocolHeader = UDPHeader.parse(from: dataReader)
    case .tcp: protocolHeader = TCPHeader.parse(from: dataReader)
    default: return nil
    }
    
    guard let protocolHeader = protocolHeader,
          (isRequest && protocolHeader.destinationPort == 53 ||
           !isRequest && protocolHeader.sourcePort == 53)
    else { return nil }
    dataReader.advanceCursor(by: protocolHeader.size)
    
    guard let dnsHeader = DNSHeader.parse(from: dataReader) else { return nil }
    dataReader.advanceCursor(by: DNSHeader.size)
    
    return dnsHeader
  }
  
  public static func parseRequest(from data: Data) -> [DNSQuery]? {
    let dataReader = DataReader(data)
    guard let dnsHeader = parseHeaders(from: dataReader, isRequest: true),
          dnsHeader.queryType == .query && dnsHeader.questionCount > 0,
          let dnsRequest = DNSRequestBody.parse(from: dataReader, header: dnsHeader)
    else { return nil }
    
    return dnsRequest
  }
  
  public static func parseResponse(from data: Data) throws -> [DomainMappings]? {
    let dataReader = DataReader(data)
    guard let dnsHeader = parseHeaders(from: dataReader, isRequest: false),
          dnsHeader.queryType == .response && dnsHeader.answerCount > 0,
          let dnsAnswers = try DNSResponseBody.parse(from: dataReader, header: dnsHeader)
    else { return nil }
    
    var aliases: [String: String] = [:]
    var ipAddresses: [String: DomainMappings] = [:]
    
    for dnsAnswer in dnsAnswers {
      switch dnsAnswer.recordType {
      case .a:
        var mappings = ipAddresses[dnsAnswer.domain] ?? DomainMappings(domains: [dnsAnswer.domain])
        mappings.ipv4Addresses.insert(dnsAnswer.value)
        ipAddresses[dnsAnswer.domain] = mappings
      case .aaaa:
        var mappings = ipAddresses[dnsAnswer.domain] ?? DomainMappings(domains: [dnsAnswer.domain])
        mappings.ipv6Addresses.insert(dnsAnswer.value)
        ipAddresses[dnsAnswer.domain] = mappings
      case .cname, .mx:
        aliases[dnsAnswer.domain] = dnsAnswer.value
      case .other: break
      }
    }
    
    // Flatten domain aliases into their final resolved ip address
    while let alias = aliases.first(where: { ipAddresses[$0.value] != nil }) {
      Log.debug("Loop 10", context: "Loop")
      guard var mappings = ipAddresses[alias.value] else { break }
      mappings.domains.insert(alias.key)
      ipAddresses[alias.value] = mappings
      if let outerPointer = aliases.first(where: { $0.value == alias.key }) {
        
        aliases[outerPointer.key] = alias.value
      }
      
      aliases.removeValue(forKey: alias.key)
    }
    
    return [DomainMappings](ipAddresses.values)
  }
}
