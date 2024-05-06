import Foundation

enum CacheEntry {
    case inProgress(Task<QuakeLocation, Error>)
    case ready(QuakeLocation)
}

final class CacheEntryObject {
    let entry: CacheEntry
    
    init(entry: CacheEntry) { self.entry = entry}
}

extension NSCache where KeyType == NSString, ObjectType == CacheEntryObject {
    subscript(url: URL) -> CacheEntry? {
        get {
            let key = url.absoluteString as NSString
            let value = object(forKey: key)
            return value?.entry
        }
        set {
            let key = url.absoluteString as NSString
            if let entry = newValue {
                let value = CacheEntryObject(entry: entry)
                setObject(value, forKey: key)
            }
        }
    }
    
}

class QuakeClient {
    private let quakeCache: NSCache<NSString, CacheEntryObject> = NSCache()
    
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }()
    
    private let feedURL = URL(string: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson")
    
    private let downloader: URLSession
    
    var quakes: [Quake] {
        get async throws {
            guard let url = feedURL else {
                throw QuakeError.missingURL
            }
            let data = try await downloader.data(from: url)
            let allQuakes = try decoder.decode(GeoJSON.self, from: data.0)
            var updatedQuakes = allQuakes.quakes
            if let olderThanOneHour = updatedQuakes.firstIndex(where: { $0.time.timeIntervalSinceNow > 3600 }) {
                let indexRange = updatedQuakes.startIndex..<olderThanOneHour
                try await withThrowingTaskGroup(of: (Int, QuakeLocation).self) { group in
                    for index in indexRange {
                        group.addTask {
                            let location = try await self.quakeLocation(from: allQuakes.quakes[index].detail)
                            return (index, location)
                        }
                    }
                    while let result = await group.nextResult() {
                        switch result {
                        case .failure(let error):
                            throw error
                        case .success(let (index, location)):
                            updatedQuakes[index].location = location
                        }
                    }
                }
               
            }
            return updatedQuakes
        }
    }
    
    init(downloader: URLSession) {
        self.downloader = downloader
    }
    
    func quakeLocation(from url: URL) async throws -> QuakeLocation {
        if let cached = quakeCache[url] {
            switch cached {
            case .ready(let location):
                return location
            case .inProgress(let task):
                return try await task.value
            }
        }
        
        let task = Task<QuakeLocation, Error> {
            let data = try await downloader.data(from: url)
            let location = try decoder.decode(QuakeLocation.self, from: data.0)
            return location
        }
        quakeCache[url] = .inProgress(task)
        do {
            let location = try await task.value
            quakeCache[url] = .ready(location)
            return location
        } catch {
            quakeCache[url] = nil
            throw error
        }
        
    }
}

struct Quake {
    let magnitude: Double
    let place: String
    let time: Date
    let code: String
    let detail: URL
    var location: QuakeLocation?
}

extension Quake: Identifiable {
    var id: String { code }
}

extension Quake: Decodable {
    private enum CodingKeys: String, CodingKey {
        case magnitude = "mag"
        case place
        case time
        case code
        case detail
    }


    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawMagnitude = try? values.decode(Double.self, forKey: .magnitude)
        let rawPlace = try? values.decode(String.self, forKey: .place)
        let rawTime = try? values.decode(Date.self, forKey: .time)
        let rawCode = try? values.decode(String.self, forKey: .code)
        let rawDetail = try? values.decode(URL.self, forKey: .detail)


        guard let magnitude = rawMagnitude,
              let place = rawPlace,
              let time = rawTime,
              let code = rawCode,
              let detail = rawDetail
        else {
            throw QuakeError.missingData
        }


        self.magnitude = magnitude
        self.place = place
        self.time = time
        self.code = code
        self.detail = detail
    }
}

enum QuakeError: Error {
    case missingData
    case missingURL
}

struct QuakeLocation {
    let coordinates: [CGFloat]
    
    var lat: CGFloat {
        guard coordinates.count > 0 else {
            return 0.0
        }
        return coordinates[0]
    }
    
    var long: CGFloat {
        guard coordinates.count > 1 else {
            return 0.0
        }
        return coordinates[1]
    }
}

extension QuakeLocation: Decodable {
    
}

struct GeoJSON {
    
}

extension GeoJSON: Decodable {}


