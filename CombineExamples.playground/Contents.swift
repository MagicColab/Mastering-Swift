import SwiftUI
import Combine

struct TaskGroupsLoader {
    var urlSession = URLSession.shared
    private let decoder = JSONDecoder()
    
    let url = URL(string: "https://example.com")!
    
    func loadGroupList() -> AnyPublisher<[EntryGroup], Error> {
        urlSession
            .dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: NetworkResponse<[Entry]>.self,
                    decoder: decoder)
            .map(\.result)
            .flatMap(loadGroups)
            .eraseToAnyPublisher()
    }
}

private extension TaskGroupsLoader {
    func loadGroups(for entries: [Entry]) -> AnyPublisher<[EntryGroup], Error> {
        entries.publisher
            .flatMap(loadGroup)
            .collect()
            .sort { $0.id > $1.id }
            .eraseToAnyPublisher()
    }
}

private extension TaskGroupsLoader {
    func loadGroup(for entry: Entry) -> AnyPublisher<EntryGroup, Error> {
        let url = URL.metadataForEntryGroup(withId: entry.id)
        
        return urlSession.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: NetworkResponse<EntryGroup>.self,
                    decoder: decoder)
            .map(\.result)
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output: Sequence {
    typealias Sorter = (Output.Element, Output.Element) -> Bool
    
    func sort(by sorter: @escaping Sorter) -> Publishers.Map<Self, [Output.Element]> {
        map { sequence in
            sequence.sorted(by: sorter)
        }
    }
}

protocol SearchResultsLoader {
    func loadResults(forQuery query: String,
                     filter: SearchFilter?) -> AnyPublisher<[SearchResult], Error>
}

struct RemoteSearchResultsLoader: SearchResultsLoader {
    var urlSession = URLSession.shared
    private let decoder = JSONDecoder()
    
    func loadResults(forQuery query: String,
                     filter: SearchFilter? = nil) -> AnyPublisher<[SearchResult], Error> {
        guard query.count > 2 else {
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        let url = URL.search(for: query, filter: filter)
        
        return urlSession.dataTaskPublisher(for: url)
            .retry(2)
            .map(\.data)
            .decode(type: NetworkResponse<[SearchResult]>.self,
                    decoder: decoder)
            .map(\.result)
            .eraseToAnyPublisher()
    }
}

class SearchViewModel: ObservableObject {
    typealias Output = Result<[SearchResult], Error>
    
    @Published private(set) var output = Output.success([])
    @Input var query = ""
    @Input var filter: SearchFilter?
    
    private let loader: SearchResultsLoader
    
    init(loader: RemoteSearchResultsLoader = .init()) {
        self.loader = loader
        configureDataPipeline()
    }
}

private extension SearchViewModel {
    func loadResults() {
        loader.loadResults(forQuery: query, filter: filter)
            .asResult()
            .receive(on: DispatchQueue.main)
            .assign(to: &$output)
    }
}

@propertyWrapper
struct Input<Value> {
    var wrappedValue: Value {
        get { subject.value }
        set { subject.send(newValue) }
    }
    
    var projectedValue: AnyPublisher<Value, Never> {
        subject.eraseToAnyPublisher()
    }
    
    private let subject: CurrentValueSubject<Value, Never>
    
    init(wrappedValue: Value) {
        subject = CurrentValueSubject(wrappedValue)
    }
}

private extension SearchViewModel {
    func configureDataPipeline() {
        $query
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .combineLatest($filter)
            .map { [loader] query, filter in
                loader.loadResults(forQuery: query,
                                   filter: filter)
                .asResult()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$output)
    }
}

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        VStack {
            TextField("Search", text: $viewModel.query)
            
            switch viewModel.output {
            case .success(let results):
                List(results) { result in
                    SearchResultView(result: result)
                }
            case .failure(let error):
                ErrorView(error: error)
            }
            
        }
    }
}

extension Publisher {
    func asResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        self.map(Result.success)
            .catch { error in
                Just(.failure(error))
            }
            .eraseToAnyPublisher()
    }
}

//// Example building blocks

struct SearchResultView: View {
    
    let result: SearchResult
    
    init(result: SearchResult) {
        self.result = result
    }
    
    var body: some View {
        Text(String(result.id))
    }
}

struct ErrorView: View {
    let error: Error
    
    init(error: Error) {
        self.error = error
    }
    
    var body: some View {
        Text("error")
    }
}

struct NetworkResponse<T: Decodable>: Decodable {
    var result: T
}

struct SearchResult: Decodable, Identifiable {
    var id: Int
    
    
}

extension URL {
    static func search(for query: String, filter: SearchFilter? = nil) -> Self { URL(string: "http://example.com")! }
    
    static func metadataForEntryGroup(withId id: Int) -> Self { URL(string: "http://example.com")! }
}

struct SearchFilter {
    
}

struct Entry: Decodable {
    let id: Int
}

struct EntryGroup: Decodable {
    let id: Int
}

enum MyError: Error {
    
    static func error(description: String, code: Int) -> NSError {
        NSError(domain: "", code: code, userInfo: ["description" : description])
    }
    
    static func error(for error: URLError) -> NSError? {
        switch error.code {
        case .cannotLoadFromNetwork:
            return Self.error(description: "bla bla", code: error.code.rawValue)
        default:
            return Self.error(description: "bla bla", code: -1)
            
        }
    }
}
    
