import Foundation
import Combine

public func myLearningCode(of title: String, execute: () -> Void) {
    print("\n Example of: \(title) \n")
    execute()
}

myLearningCode(of: "filter operator") {
    let creditScorePublisher = [309, 484, 456,789, 234, 675, 555].publisher
    
    creditScorePublisher
        .filter { currentCreditScore in
        currentCreditScore > 400
    }.sink { receivedValue in
        print(receivedValue)
    }
}

myLearningCode(of: "removeDuplicates operator") {
    let receivedValues = ["apple", "juice", "chair", "book", "apple", "chair"].publisher
    
    receivedValues
        .removeDuplicates()
        .sink { receivedName in
            print(receivedName)
        }
}

myLearningCode(of: "ignoreOutput operator") {
    let receivedValues = ["Welcome screen 1", "Welcome screen 2"].publisher
    
    receivedValues
        .ignoreOutput()
        .sink { receivedValue in
        print(receivedValue)
    }
}

myLearningCode(of: "first(where:) operator") {
    let customCreditScorePublisher = [300, 650, 409, 290, 789, 347, 890].publisher
    
    customCreditScorePublisher.first { score in
        score > 706
    }.sink { value in
        print(value)
    }
}

myLearningCode(of: "last(where:) operator") {
    let customCreditScorePublisher = [490, 589, 200, 600, 543, 390].publisher
    
    customCreditScorePublisher.last { score in
        score > 400
    }.sink { value in
        print(value)
    }
}

myLearningCode(of: "dropFirls operator") {
    let score = (1...5).publisher
    
    score.dropFirst(3).sink { value in
        print(value)
    }
}

myLearningCode(of: "drop(while:) operator") {
    let scoreChangePublisher = [23, 45, 78, 12, 34, 56 , 34, 83].publisher
    
    scoreChangePublisher.drop { currentScopre in
        currentScopre < 40
    }.sink { value in
        print(value)
    }
}

var subscriptions = Set<AnyCancellable>()

myLearningCode(of: "drop(untilOutputFrom)") {
    let isReceiverReadyPublisher = PassthroughSubject<Void, Never>()
    let callingButtonTapsPublisher = PassthroughSubject<Int, Never>()
    
    callingButtonTapsPublisher.drop(untilOutputFrom: isReceiverReadyPublisher).sink { value in
        print(value)
    }.store(in: &subscriptions)
    
    (1...6).forEach { currentTap in
        callingButtonTapsPublisher.send(currentTap)
        
        if currentTap == 3 {
            isReceiverReadyPublisher.send()
        }
    }
    
    callingButtonTapsPublisher.send(completion: .finished)
}

myLearningCode(of: "prefix operator") {
    let score = (1...5).publisher
    
    score
        .prefix(3)
        .sink { value in
        print(value)
    }
}

myLearningCode(of: "prefix(while:) operator") {
    let scoreChangePublisher = [34, 56, 29, 40, 50, 20, 34, 33].publisher
    
    scoreChangePublisher
        .prefix { currentScore in
        currentScore < 40
    }
        .sink { value in
        print(value)
    }
}

var subscriptionsForPrefixs = Set<AnyCancellable>()

myLearningCode(of: "prefix(untilOutputFrom:) operator") {
    let isReceiverReadyPublisher = PassthroughSubject<Void, Never>()
    let callingButtonTapsPublisher = PassthroughSubject<Int, Never>()
    
    callingButtonTapsPublisher.prefix(untilOutputFrom: isReceiverReadyPublisher)
        .sink { value in
            print(value)
        }.store(in: &subscriptionsForPrefixs)
    
    (1...6).forEach { currentTap in
        callingButtonTapsPublisher.send(currentTap)
        
        if currentTap == 3 {
            isReceiverReadyPublisher.send()
        }
    }
    callingButtonTapsPublisher.send(completion: .finished)
}

myLearningCode(of: "CustorSubscriber") {
    
    class OrderNumberSubscriber: Subscriber {
        
        typealias Input = Int
        
        typealias Failure = Never
        
        func receive(subscription: any Subscription) {
            subscription.request(.max(5)) /// .unlimited
        }
        
        func receive(_ input: Int) -> Subscribers.Demand {
            /// do receiver job here
            print("received value \(input)")
            return .none
        }
        
        func receive(completion: Subscribers.Completion<Never>) {
            print(completion)
        }
    }
    
    let orderPublisher = (1...10).publisher
    
    let orderSubscriber = OrderNumberSubscriber()
    
    orderPublisher.subscribe(orderSubscriber)
}




