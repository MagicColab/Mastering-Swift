import SwiftUI
import UIKit

// ViewBulders examples - showing the convenience of usage

struct SalesFooterView: View {
    let isPro: Bool
    
    var body: some View {
       makeFooterView(isPro: isPro)
    }
    
    @ViewBuilder
    func makeFooterView(isPro: Bool) -> some View {
        if isPro {
            Text("Hello")
        } else {
            VStack {
                Text("Hi")
                Button("Become pro") {
                    ///
                }
            }
        }
    }
}

struct SalesFooterVBView {
    let isPro: Bool
    
    @ViewBuilder
    var body: some View {
        if isPro {
             Text("Hello")
        } else {
             Button("Hi") {
                startPurchase()
            }
        }
    }
    
    func startPurchase() {
        
    }
}

struct VHStack<Content: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @ViewBuilder var content: () -> Content
    
    
    var body: some View {
        if horizontalSizeClass == .compact {
            VStack(content: content)
        } else {
            HStack(content: content)
        }
    }
}

struct ContentView: View {
    var body: some View {
        VHStack { // ViewBulder in action
            Text("Hello World!")
            Text("Result Builders are great!")
        }
    }
}

extension Slider {
    @ViewBuilder
    func minimumTrackColor(_ color: Color) -> some View {
        if #available(OSX 11.0, *) {
            accentColor(color)
        } else {
            self
        }
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct ContainerView1: View {
    private var shouldApplyBackground: Bool {
        guard #available(iOS 14, *) else {
            return true
        }
        return false
    }
    
    var body: some View {
        Text("Hello, world!")
            .padding()
            .if(shouldApplyBackground) { view in
                view.background(Color.red)
            }
    }
}

/// or using autoclosure

struct ConteinerView2: View {
     var body: some View {
         Text("Hello, world!")
             .padding()
             .if({
                 if #available(iOS 14, *) {
                     return true
                 }
                 return false
             }()) { view in
                 view.background(Color.red)
             }
     }
 }

// Opaque types

public protocol ImageFetching<Image> {
    associatedtype Image
    func fetchImage() -> Image
}

public extension UIImageView {
    func configureImage(with imageFetcher: some ImageFetching<UIImage>) {
        // Cannot assign value of type '<anonymous>.Image' to type 'UIImage'
        image = imageFetcher.fetchImage()
    }
}

public extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: "group.com.myApp")!
}

struct Emanple {
    @AppStorage("isLogin", store: .appGroup) var isLogin: Bool = false
}

ContentView()
    .defaultAppStorage(.appGroup)
 
func appStorateUsage() {
    @AppStorage("isLogin") var isLogin: Bool = false // in ContentView, store in appGroup suit

    @AppStorage("count") var count = 100
    
    // in View
    print(count) // 100
    print(UserDefaults.standard.value(forKey: "count")) // nil
}




struct DefaultValue: View {
    @AppStorage("count") var count = 100
    
    var body: some View {
        Button("Count") {
            print(count)
        }
    }
}

DefaultValue()
    .onAppear {
        UserDefaults.standard.register(defaults: ["count": 50])
    }

/// Property wrappers
@propertyWrapper
struct InRange {
    private var mark: Int
    var wrappedValue: Int {
        set {
            mark = newValue
        }
        get {
            return max(0, min(mark, 100)) /// returns value between 0 and 100
        }
    }
    init(wrappedValue: Int) {
        mark = wrappedValue
    }
}

/// Usage
struct Student {
    @InRange var mark: Int
}

let student1 = Student(mark: 75)
print(student1.mark)

let student2 = Student(mark: 110)
print(student2.mark)

let student3 = Student(mark: -20)
print(student3.mark)







