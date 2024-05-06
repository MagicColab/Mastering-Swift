import Foundation
//// Futures implementation
///

class Future<Value> {
    typealias Result = Swift.Result<Value, Error>
    typealias Callback = (Result) -> Void
    
    fileprivate var result: Result? {
        /// Observe whenever a reslut is assigned, and report it:
        didSet { result.map(report) }
    }
    
    private var callbacks = [Callback]()
    
    func observe(using callback: @escaping Callback) {
        /// if a resukt has already beed set, call the callback directly
        if let result = result {
            callback(result)
            return
        }
        
        callbacks.append(callback)
    }
    
    private func report(result: Result) {
        callbacks.forEach { $0(result) }
        callbacks = []
    }
}

class Promise<Value>: Future<Value> {
    init(value: Value? = nil) {
        super.init()
        
        /// If the value was already known at the time the promise
        /// was contructed, we can report it directly:
        result = value.map(Result.success)
    }
    
    func resolve(with value: Value) {
        result = .success(value)
    }
    
    func reject(with error: Error) {
        result = .failure(error)
    }
}

extension URLSession {
    func request(url: URL) async -> Future<Data> {
        /// We'll start by constructing a Promise, that will later be
        /// returned as a Future:
        
        let promise = Promise<Data>()
        
        ///Perform a data task, just like we mormally would:
        do {
            let response = try await data(from: url)
            promise.resolve(with: response.0)
        } catch {
            promise.reject(with: error)
        }
        
        return promise
    }
}

let url = URL(string: "https://example.com")!
URLSession.shared.request(url: url).observe { result in
        /// handle the result
}


/// Chaining
extension Future {
    func chained<T>(using closure: @escaping (Value) throws -> Future<T>) -> Future<T> {
        /// We'll start by constructing a "wrapper" promise that will be returned from this method:
        let promise = Promise<T>()
        
        /// Observe the current future:
        observe { result in
            switch result {
            case .success(let value):
                do {
                    /// Attempt to construct a new future using the value returned from the first one:
                    let future = try closure(value)
                    
                    /// Observe the "nested" future, and once it completes, resolve/reject the "wrapper" future:
                    future.observe { result in
                        switch result {
                        case .success(let value):
                            promise.resolve(with: value)
                        case .failure(let error):
                            promise.reject(with: error)
                        }
                    }
                } catch {
                    promise.reject(with: error)
                }
            case .failure(let error):
                promise.reject(with: error)
            }
        }
        
        return promise
    }
}

extension Future where Value: Saveable {
    func saved(in database: Database) -> Future<Value> {
        chained { value in
            let promise = Promise<Value>()
            
            database.save(value) {
                promise.resolve(with: value)
            }
        }
    }
}

extension Future {
    func transformed<T>(with closure: @escaping (Value) throws -> T) -> Future<T> {
        chained { value in
            try Promise(value: closure(value))
        }
    }
}

extension Future where Value == Data {
    func decoded<T: Decodable>(as type: T.Type = T.self,
                               using decoder: JSONDecoder = .init()) -> Future<T> {
        transformed { data in
            try decoder.decode(T.self, from: data)
        }
        
    }
}

class UserLoader {
    
    func loadUser(withID id: User.ID) -> Future<User> {
        let url = urlForLOadingUser(withID: id)
        
        /// Request the URL, returning data:
        let requestFuture = urlSession.request(url: url)
        
        /// Transform the loaded data into a User model:
        let decodedFuture = requestFuture.decoded(as: User.self)
        
        ///Save the user in our database:
        let savedFuture = decodedFuture.saved(in: database)
        
        /// Return the last future, as it marks the end of our chain:
        return savedFuture
    }
    
    /// Alternatinve
    func loadUserAlt(withID id: User.ID) -> Future<User> {
        urlSession
            .request(url: urlForLoadingUser(withID: id))
            .decoded()
            .saved(in: database)
    }
    
}
