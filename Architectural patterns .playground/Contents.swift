import UIKit
import XCTest

//// MVP
struct Person {
    let firstName: String
    let lastName: String
}

protocol GreetingView: AnyObject {
    func setGreeting(greeting: String)
    var presenter: GreetingViewPresenter! { get set }
}

protocol GreetingViewPresenter {
    init(view: GreetingView, person: Person)
    func showGreeting()
}

class GreetingPresenter: GreetingViewPresenter {
    
    unowned let view: GreetingView
    private let person: Person
    
    required init(view: GreetingView, person: Person) {
        self.view = view
        self.person = person
    }
    
    func showGreeting() {
        let greeting = "Hello" + " " + self.person.firstName + " " + self.person.lastName
        self.view.setGreeting(greeting: greeting)
    }
}

class GreetingViewController: UIViewController, GreetingView {

    var presenter: GreetingViewPresenter!
    let showGreetingButton = UIButton()
    let greetingLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showGreetingButton.addTarget(self, action: Selector(("didTapButton")), for: .touchUpInside)
    }
    
    func didTapButton(button: UIButton) {
        self.presenter.showGreeting()
    }
    
    func setGreeting(greeting: String) {
        self.greetingLabel.text = greeting
    }
}

// Tests

class GreetingViewTests: XCTestCase, GreetingView {
    var presenter: GreetingViewPresenter!
    let person = Person(firstName: "Test", lastName: "Test")
    
    func setup() {
        presenter = GreetingPresenter(view: self, person: person)
    }
    
    func testPresenterShowGreeting() {
        presenter.showGreeting()
    }
    
    func setGreeting(greeting: String) {
        let greetingExpected = person.firstName + " text expected " + person.lastName
        XCTAssertEqual(greeting, greetingExpected)
    }
}

// Assemblig of MVP
let person = Person(firstName: "David", lastName: "Blain")
let greetingView = GreetingViewController()
let greetingPresenter = GreetingPresenter(view: greetingView, person: person)
greetingView.presenter = greetingPresenter

///------------------------------------------------------------------------

////MVVM

struct Flower {
    let name: String
    let count: Int
}

protocol BouquetteViewModelProtocol: AnyObject {
    var bouquette: String? { get }
    var bouquetteConstructed: ((BouquetteViewModelProtocol) -> ())? { get set }
    init(flower: Flower)
    func constructBouquette()
}

class BouquetteViewModel: BouquetteViewModelProtocol {
    
    var bouquetteConstructed: ((any BouquetteViewModelProtocol) -> ())?
    
    private let flower: Flower
    
    required init(flower: Flower) {
        self.flower = flower
    }
    
    var bouquette: String? {
        didSet {
            self.bouquetteConstructed?(self)
        }
    }
    
    func constructBouquette() {
        self.bouquette = "Flower \(flower.name) " + String(flower.count) + "***"
    }
}

class BouquetteViewController: UIViewController {
    
    let bouqetteLabel = UILabel()
    
    var viewModel: BouquetteViewModelProtocol! {
        didSet {
            self.viewModel.bouquetteConstructed = { [unowned self] viewModel in
                self.bouqetteLabel.text = viewModel.bouquette
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.constructBouquette()
    }
}

// Assemblig of MVVM
let flower = Flower(name: "Rose", count: 3)
let viewModel = BouquetteViewModel(flower: flower)
let bouqetteView = BouquetteViewController()
bouqetteView.viewModel = viewModel

// Tests

class BouqetteViewTests: XCTestCase {
    
    func testBouqetteConstruction() {
        let sut = makeSUT()
        sut.constructBouquette()
        
        XCTAssertEqual(sut.bouquette, "What is expected")
    }
    
    func makeSUT() -> BouquetteViewModel {
        let sut = BouquetteViewModel(flower: Flower(name: "Archidea",
                                                    count: 2))
        return sut
    }
}

///------------------------------------------------------------------------

//// VIPER
struct Sweet { // Entity
    let name: String
    let size: String
}

struct SweetOrder { // TDS - Transport data structure
    let sweet: String
    let table: String
    let count: String
}

protocol SweetProvider {
    func provideSweetData()
    var output: SweetOrderOutput? { get set }
}

protocol SweetOrderOutput: AnyObject {
    func receivedSweetOrder(sweetOrder: SweetOrder)
}

class SweetInteractor: SweetProvider {
    
    weak var output: SweetOrderOutput?
    
    func provideSweetData() {
        let sweet = Sweet(name: "Red Velvet", size: "Medium")
        let sweetOrder = SweetOrderAdapter.constrcutSweetOrder(sweet: sweet)
        self.output?.receivedSweetOrder(sweetOrder: sweetOrder)
    }
}

class SweetOrderAdapter {
    class func constrcutSweetOrder(sweet: Sweet) -> SweetOrder {
        let sweetOrder = SweetOrder(sweet: sweet.name + sweet.size,
                                    table: String(8),
                                    count: String(2))
        return sweetOrder
    }
}

protocol SweetOrderEventHandler: AnyObject {
    func didTapShowOrderButton()
}

protocol SweetOrderView: AnyObject {
    func setOrderView(sweetOrder: String)
}

class SweetOrderPresenter: SweetOrderOutput, SweetOrderEventHandler {
    var view: SweetOrderView?
    var sweetProvider: SweetProvider
    
    init(sweetProvider: SweetProvider, view: SweetOrderView) {
        self.sweetProvider = sweetProvider
        self.view = view
    }
    
    func didTapShowOrderButton() {
        self.sweetProvider.provideSweetData()
    }
    
    func receivedSweetOrder(sweetOrder: SweetOrder) {
        let sweetViewData = sweetOrder.sweet + "table" + " " + sweetOrder.table + "count" + " " + sweetOrder.count
        self.view?.setOrderView(sweetOrder: sweetViewData)
    }
}

class SweetOrderViewController: UIViewController, SweetOrderView {
    weak var eventHandler: SweetOrderEventHandler?
    let showSweetOrderButton = UIButton()
    let sweetOrderLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showSweetOrderButton.addTarget(self, action: Selector(("didTapButton:")), for: .touchUpInside)
    }
    
    func didTapButton(button: UIButton) {
        self.eventHandler?.didTapShowOrderButton()
    }
    
    func setOrderView(sweetOrder: String) {
        self.sweetOrderLabel.text = sweetOrder
    }
}

// Assembling of VIPER module, without Router
let view = SweetOrderViewController()
let interactor = SweetInteractor()
let presenter = SweetOrderPresenter(sweetProvider: interactor, view: view)
view.eventHandler = presenter
interactor.output = presenter

// Tests
class SweetOrderPresenterTests: XCTestCase {
    
    var sweetOrderResults: ((Bool) -> ())? = nil
    
    func testDidTapShowButton() {
        let sut = makeSUT(sweet: Sweet(name: "Test", 
                                       size: "Test"))
        sut.didTapShowOrderButton()
        
        sweetOrderResults = { result in
            XCTAssertTrue(result)
        }
    }
    
    class SweetOrderViewTest: SweetOrderView {
        
        let presenter: SweetOrderPresenterTests
        
        init(presenter: SweetOrderPresenterTests) {
            self.presenter = presenter
        }
        // Expected result for didTapShowOrderButton action
        func setOrderView(sweetOrder: String) {
            self.presenter.sweetOrderResults?(sweetOrder == "Expected value")
        }
    }
    
    func makeSUT(sweet: Sweet) -> SweetOrderPresenter {
        let interactorMock = SweetInteractorMock(sweet: sweet)
        let sut = SweetOrderPresenter(sweetProvider: interactorMock, view: SweetOrderViewTest(presenter: self))
        return sut
    }
}

extension SweetOrderPresenterTests {
    class SweetInteractorMock: SweetProvider {
        var output: (any SweetOrderOutput)?
        
        let sweet: Sweet
        
        init(output: (any SweetOrderOutput)? = nil, sweet: Sweet) {
            self.output = output
            self.sweet = sweet
        }
        
        /// Mocking data here if needs to get data for any kind of stoage
        func provideSweetData() {
            let sweet = sweet
            let sweetOrder = SweetOrderAdapter.constrcutSweetOrder(sweet: sweet)
            self.output?.receivedSweetOrder(sweetOrder: sweetOrder)
        }
    }
}


