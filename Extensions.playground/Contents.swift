import UIKit

extension Encodable where Self: Identifiable {
    
    func cacheOnDisk(using encoder: JSONEncoder = .init()) throws {
        let folderURLs = FileManager.default.urls(for: .cachesDirectory,
                                                  in: .userDomainMask)
        
        /// Rather than hardcoding a specific type's name here, we instead dynamically resolve a
        /// description of the type that our method is currently being called on:
        let typeName = String(describing: Self.self)
        let fileName = "\(typeName)-\(id).cache"
        let fileURL = folderURLs[0].appending(component: fileName)
        let data = try encoder.encode(self)
        try data.write(to: fileURL)
    }
}

extension Result where Success: RangeReplaceableCollection {
    func combine(with other: Self) throws -> Self {
        try .success(get() + other.get())
    }
}

public protocol DataConvertable {
    var data: Data { get }
}

extension Data: DataConvertable {
    public var data: Data { self }
}

extension String: DataConvertable {
    public var data: Data { Data(utf8) }
}

extension UIImage: DataConvertable {
    public var data: Data { pngData()! }
}

public struct Container {
    public func write<T: DataConvertable>(_ value: T) throws {
        let data = value.data
    }
}
