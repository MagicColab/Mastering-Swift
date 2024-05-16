//
//  CompositionalArchitecuteExample.swift
//  
//
//  Created by Zaruhi Davtyan on 16.05.24.
//

import UIKit

public protocol YourFeatureRouting {
    func showAnotherFeature()
}

final class YourFeatureViewController: UIViewController {
    private let featureRouter: YourFeatureRouting
    
    init(featureRouter: YourFeatureRouting) {
        self.featureRouter = featureRouter
    }
    
    private func showAnotherFeature() {
        featureRouter.showAnotherFeature()
    }
}

public struct YourFeatureFactory {
    static func make(featureRouter: YourFeatureRouting) -> UIViewController {
        YourFeatureViewController(featureRouter: featureRouter)
    }
}

struct YourFeatureRouter: YourFeatureRouting {
    var source: UIViewController?
    
    func showAnotherFeature() {
        let vc = AnotherFeatureViewController()
        source?.present(vc, animated: true)
    }
}

struct YourFeatureCompositionFactory {
    static func make() -> UIViewController {
        let featureRouter = YourFeatureRouter()
        let featureService = YourServiceFactory.make()
        let vc = YourFeatureFactory.make(featureRouter: featureRouter,
                                         featureService: featureService)
        featureRouter.source = vc
        
        return vc 
    }
}
