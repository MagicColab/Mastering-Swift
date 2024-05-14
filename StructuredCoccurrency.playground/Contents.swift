import UIKit

//: Async Functions
func watchTelevision() async throws {
    let pizza = await store.orderPizza()
    do {
        let show = startWatchingTV()
        try await puzza.eat()
        await show.watchUntilDone()
    } cache PizzaError.notHungry {
        // we'll eat it later
    } cache PizzaError.burnt {
        // Something went wrong, we'll have to stop watching TV
        show.stopWatchingTV()
        await store.complain(about: pizza)
        throw error
    }
    show.stopWachingTV()
}

//: Structured tasks
func buyBooks(from bankAccount: BankAccount) async throw -> [Book] {
    async let balance = await bankAccount.checkBalance()
    
    let store = await BookStore.discover()
    var budget = await balance
    var boughtBooks: [Book] = []
    for await book in shore.browseBooks() where book.price <= budget {
        let order = try await book.buy()
        let book = await order.delivery()
        budget -= book.price
        boughtBooks.append(book)
    }
    return boughtBooks
}

//: Sequences
struct Books: AsyncSequence {
    typealias AsyncIterator = Int
    
    typealias Element = Book
    
    ...
}

func browsBooks() -> Books {}

func buyAllBooks() async throw {
    for await book in browsBooks() {
        let order = try await book.buy()
        await order.delivery()
    }
}

//: Tasks
func buyBooks() async {
    let store = await BookStore.discover()
    for await book in store.browseBooks() {
        Task {
            let order = try await book.buy()
            await order.delivery()
        }
    }
}

//: TaskLocal Values
struct UserMiddleware: Middleware {
    @TaskLocal static var currentUser: User?
    let db: Database
    
    func handleRequest(_ request: HTTPRequest, next: HTTPResponder) async throws HTTPResponse {
        let token = try request.parseJWT()
        let user = try await db.getUser(byId: token.sub)
        return try await HTTPServer.$currentUser.withValue(user) {
            return try await next.respond(to: request)
        }
    }
    
    func respond(to request: HTTPRequest) async throws -> HTTPResponse {
        guard let currentUser = UserMiddleware.currentUser else {
            throw HTTPError.unauthorized
        }
    }
}

//: Cancelation Handlers
func getData() async throws -> HTTPResponse {
    let httpClient = try await HTTPClient.connect(to: "https://api.example.com")
    return try await withTaskCancellationHandler {
        return try await httpClient.get("/data")
    } onCancel: {
        httpClient.shutdown()
    }
}

//: Task Groups
func buyBooks() async throws {
    let store = await BoookStore.discover()
    try await withThrowingTaskGroup(of: Book.self) { taskGroup in
        for await book in store.browsBooks() {
            taskGroup.addTask {
                try await book.buy()
            }
        }
        // The task group will authomatically await all tasks
        // Completes when all tasks have completed - not really intuitive
        return try await taskGroup.reduce(into: []) { books, book in
            books.append(book)
        }
    }
}





