//
//  Furniture.swift
//  FloateingSights4var2
//
//  Created by takasiki on H30/07/24.
//  Copyright © 平成30年 takasiki. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class Furniture {
    
    static func create(sceneName: String, width: CGFloat) -> SCNNode {
        // シーンからノードを取り出す
        let scene = SCNScene(named: sceneName)!
        let node = scene.rootNode.childNode(withName: "default", recursively: true)

        // 縮尺を計算してスケールを調整する
        let (min, max) = (node?.boundingBox)!
        let w = CGFloat(max.x - min.x)
        let magnification = width / w
        node?.scale = SCNVector3(magnification, magnification, magnification)
        return node!
    }
}

