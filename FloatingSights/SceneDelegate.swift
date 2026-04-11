//
//  SceneDelegate.swift
//  FloatingSights
//
//  Created by takedatakashiki on 2026/04/10.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: Properties

    var window: UIWindow?

    // MARK: Functions

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = ARSceneViewController()
        window.makeKeyAndVisible()
        self.window = window
    }
}
