import Foundation

//  Data Structure
//
//         B I T S
//
//        |1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8|
//        _________________________________________________________________
//  B     |                               |                               |
//  Y  0  |               ID              |             Flags             |
//  T     |_______________________________|_______________________________|
//  E     |                               |                               |
//  S  4  |         # of questions        |          # of answers         |
//        |_______________________________|_______________________________|
//        |                               |                               |
//     8  |        # of authorities       |       # of extra records      |
//        |_______________________________|_______________________________|
//
public struct DNSHeader {
  
  public enum QueryType {
    case query
    case response
    
    static func infer(from int: UInt8) -> QueryType {
      switch int {
      case 0: return .query
      default: return .response
      }
    }
  }
  
  public static var size: Int { 12 }
  
  public var queryType: QueryType
  public var questionCount: Int
  public var answerCount: Int
  
  public static func parse(from dataReader: DataReader) -> DNSHeader? {
    guard let queryTypeByte = dataReader.bit(at: 2),
          let questionCount = dataReader.uint16(at: 4),
          let answerCount = dataReader.uint16(at: 6)
    else { return nil }
     
    return DNSHeader(queryType: .infer(from: queryTypeByte),
                     questionCount: Int(questionCount),
                     answerCount: Int(answerCount))
  }
}
