import Foundation

extension String {
    var data: Data {
        return self.data(using: .utf8) ?? Data()
    }
}
