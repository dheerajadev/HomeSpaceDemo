import Foundation

extension FileManager {
    var documentDirectory: URL {
        try! self.url(for: .documentDirectory, 
                     in: .userDomainMask, 
                     appropriateFor: nil, 
                     create: true)
    }
} 