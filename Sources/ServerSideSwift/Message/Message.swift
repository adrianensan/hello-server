import Foundation

public class Message {
  var body: Data = Data()
  var bodyString: String {
    set { body = Data(newValue.utf8) }
    get { return String(data: body, encoding: .utf8) ?? "" }
  }
}
