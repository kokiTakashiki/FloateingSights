//
//  ViewController.swift
//  FloateingSights4var2
//
//  Created by takasiki on H30/07/24.
//  Copyright © 平成30年 takasiki. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ScrollViewDelegate, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var controlView: UIView!
    
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var menuView: UIView!
    var isMenuOpen = true
    @IBOutlet weak var scrollView: TouchScrollView!
    @IBOutlet weak var uiSwitch: UISwitch!
    @IBOutlet weak var resetbutton: UIButton!
    @IBOutlet weak var letsFloat: UIButton!
    
    var planeNodes:[PlaneNode] = []
    
    var sofaNode: SCNNode?
    
    private lazy var startTime = Date()
    fileprivate var _display_link:CADisplayLink!    // ループ処理用ディスプレイリンク

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.Delegate = self
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        //time はめたるから呼ぶにはscn_frameを使うがそのためにはタイム計算をして、その結果データをmaterialにセットすると良い
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true, block: { (timer) in
            self.updateTime()
        })

        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        
        
        menuView.translatesAutoresizingMaskIntoConstraints = true
        toggleMenu()
        initializeMenu()
        
        controlView.backgroundColor = UIColor(white: 0, alpha: 0)
        resetbutton.addTarget(self, action: #selector(ViewController.onClickMyButton(sender:)), for: .touchDown)
        letsFloat.addTarget(self, action: #selector(ViewController.onClickFloat(sender:)), for: .touchDown)
        letsFloat.addTarget(self, action: #selector(ViewController.outClickFloat(sender:)), for: .touchUpInside)
    }
    
    private func updateTime() {
        var time = Float(Date().timeIntervalSince(startTime))
        let timeData = Data(bytes: &time, count: MemoryLayout<Float>.size)
        sofaNode?.geometry?.firstMaterial?.setValue(timeData, forKey: "time")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal // 平面の検出を有効化する
        sceneView.session.run(configuration)
        
        // updateのループ処理を開始
        _display_link = CADisplayLink(target: self, selector: #selector(ViewController.polling(_:)))
        _display_link.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
        
        // updateのループ処理を終了
        _display_link.remove(from: RunLoop.current, forMode: RunLoopMode.commonModes)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // CADisplayLinkで60fpsで呼ばれる関数
    @objc func polling(_ display_link :CADisplayLink) {
        if sofaNode != nil{
            if isFloat == true{
                //print(sofaNode?.position.y)
                if (sofaNode?.position.y)! < Float(0.3) {
                    sofaNode?.physicsBody?.isAffectedByGravity = false
                    sofaNode?.runAction(SCNAction.move(to: SCNVector3((sofaNode?.position.x)!,0.5,(sofaNode?.position.z)!), duration: 5))
                }
                switch (sofaNode?.position.y)! {
                case 0.5:
                    sofaNode?.runAction(SCNAction.move(to: SCNVector3((sofaNode?.position.x)!,0.3,(sofaNode?.position.z)!), duration: 3.5))
                case 0.3:
                    sofaNode?.runAction(SCNAction.move(to: SCNVector3((sofaNode?.position.x)!,0.5,(sofaNode?.position.z)!), duration: 4))
                default:
                    break
                }
            }
        }
    }
    
    // MARK; - Control
    @IBAction func rotation(_ sender: Any) {
        sofaNode?.physicsBody?.applyTorque(SCNVector4(0, 10, 0, -1.0), asImpulse:false)
    }
    
    // タッチなぞり関数
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with:event)    // 親のメソッドをコール(必須)
        // タッチイベントを取得
        let touchEvent = touches.first!
        let touchLocation = touchEvent.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        if !hitTestResult.isEmpty {
            if let hitResult = hitTestResult.first {
                let HitlocalCoordinates = SCNVector3(hitResult.worldTransform.columns.3.x,
                                                     hitResult.worldTransform.columns.3.y,
                                                     hitResult.worldTransform.columns.3.z)
                //print(HitlocalCoordinates)
                sofaNode?.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y + Float(0.05), hitResult.worldTransform.columns.3.z)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                // 平面を表現するノードを追加する
                let panelNode = PlaneNode(anchor: planeAnchor)
                panelNode.isDisplay = true
                
                node.addChildNode(panelNode)
                self.planeNodes.append(panelNode)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node.childNodes[0] as? PlaneNode {
                if self.uiSwitch.isOn{
                    // Switchがonの時の処理
                    planeNode.isHidden = false
                }else{
                    // Switchがoffの時の処理
                    planeNode.isHidden = true
                }
                // ノードの位置及び形状を修正する
                planeNode.update(anchor: planeAnchor)
            }
        }
    }
    
    // MAEK: - Menu View
    @IBAction func menuButtonTapperd(_ sender: UIButton) {
        toggleMenu()
    }
    
    /*
     ボタンイベント
     */
    @objc internal func onClickMyButton(sender: UIButton) {
        if let rC:SCNNode = sceneView.scene.rootNode.childNode(withName: "tgt", recursively: true){
            rC.removeFromParentNode()
        }
        //sofaNode?.removeFromParentNode()
    }
    var isFloat:Bool = false
    @objc internal func onClickFloat(sender: UIButton) {
        isFloat = true
        print(isFloat)
    }
    @objc internal func outClickFloat(sender: UIButton) {
        isFloat = false
        print(isFloat)
    }
    
    func toggleMenu() {
        if isMenuOpen {
            controlView.isHidden = false
            isMenuOpen = false
            menuButton.setImage(UIImage(named:"open"), for: .normal)
            UIView.animate(withDuration: 0.5, animations: {
                self.menuView.frame.origin.y = UIScreen.main.bounds.height - 50
            })
        } else {
            controlView.isHidden = true
            for imageView in scrollView.subviews {
                imageView.layer.borderWidth = 0
            }
            isMenuOpen = true
            menuButton.setImage(UIImage(named:"close"), for: .normal)
            UIView.animate(withDuration: 0.5, animations: {
                self.menuView.frame.origin.y = UIScreen.main.bounds.height - 300
            })
        }
    }
    
    func initializeMenu() {
        let imageWidth = 250
        let imageHeight = 200
        let margin = 20
        let imageNames = ["😱","😄","✌️","⚪️","😁"]
        
        scrollView.contentSize = CGSize(width: (imageWidth + margin) * imageNames.count , height: imageHeight)
        scrollView.isUserInteractionEnabled = true

        for i:Int in 0 ..< imageNames.count {
            let titelLabel: UILabel = UILabel(frame: CGRect(x:0,y:0,width:200,height:50))
            titelLabel.text = imageNames[i]
            titelLabel.font = UIFont.systemFont(ofSize: 120)
            titelLabel.textAlignment = .center
            titelLabel.tag = i + 1
            titelLabel.isUserInteractionEnabled = true
            titelLabel.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.0)
            titelLabel.layer.borderColor = UIColor.white.cgColor
            titelLabel.layer.borderWidth = 0
            titelLabel.layer.masksToBounds = true
            titelLabel.layer.cornerRadius = 10
 
            let offSet = i * (imageWidth + margin)
            titelLabel.frame = CGRect(x: offSet, y: 0, width: imageWidth, height: imageHeight)
            scrollView.addSubview(titelLabel)
        }
        
        menuView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    }
    
    // MAEK: - append Sofa Node
    func scrollViewTapped(tag: Int) {
        let imageView = scrollView.subviews[tag-1]
        imageView.layer.borderWidth = 10
        
        self.toggleMenu()
        
//        if sofaNode != nil {
//            sofaNode?.removeFromParentNode()
//        }
        
        let hitTestResult = sceneView.hitTest(sceneView.center, types: .existingPlaneUsingExtent)
        if !hitTestResult.isEmpty {
            if let hitResult = hitTestResult.first {
                
                let sceneName = ["KokeDama05","KokeDama06","KokeDama07","KokeDama08","KokeDama09"]
                let assetsName = "art.scnassets"
                let sofaWidth:[CGFloat] = [0.15, 0.15, 0.15, 0.15,0.15]
                sofaNode = Furniture.create(sceneName: "\(assetsName)/\(sceneName[tag-1]).scn", width: sofaWidth[tag-1])
                
                let material = SCNMaterial()
                switch sceneName[tag-1]{
                case "KokeDama05":
                    let image = UIImage(named: "art.scnassets/testes06.png")!
                    let imageProperty = SCNMaterialProperty(contents: image)
                    material.setValue(imageProperty, forKey: "diffuseTexture")
                    
                    //        let image2 = UIImage(named: "art.scnassets/photos_2017_11_3_fst_moss-textureDispSq.png")!
                    //        let image2Property = SCNMaterialProperty(contents: image2)
                    //        material.setValue(image2Property, forKey: "noiseTexture")
                    let program = SCNProgram()
                    program.fragmentFunctionName = "myFragment"
                    program.vertexFunctionName = "myVertex"
                    material.program = program
                    //透過処理
                    program.isOpaque = false
                case "KokeDama06":
                    let image = UIImage(named: "art.scnassets/testes06.png")!
                    let imageProperty = SCNMaterialProperty(contents: image)
                    material.setValue(imageProperty, forKey: "diffuseTexture")
                    
                    //        let image2 = UIImage(named: "art.scnassets/photos_2017_11_3_fst_moss-textureDispSq.png")!
                    //        let image2Property = SCNMaterialProperty(contents: image2)
                    //        material.setValue(image2Property, forKey: "noiseTexture")
                    let program = SCNProgram()
                    program.fragmentFunctionName = "sixFragment"
                    program.vertexFunctionName = "myVertex"
                    material.program = program
                    //透過処理
                    program.isOpaque = false
                case "KokeDama07":
                    let image = UIImage(named: "art.scnassets/testes06.png")!
                    let imageProperty = SCNMaterialProperty(contents: image)
                    material.setValue(imageProperty, forKey: "diffuseTexture")
                    
                    //        let image2 = UIImage(named: "art.scnassets/photos_2017_11_3_fst_moss-textureDispSq.png")!
                    //        let image2Property = SCNMaterialProperty(contents: image2)
                    //        material.setValue(image2Property, forKey: "noiseTexture")
                    let program = SCNProgram()
                    program.fragmentFunctionName = "sevenFragment"
                    program.vertexFunctionName = "myVertex"
                    material.program = program
                    //透過処理
                    program.isOpaque = false
                case "KokeDama08":
                    let image = UIImage(named: "art.scnassets/testes06.png")!
                    let imageProperty = SCNMaterialProperty(contents: image)
                    material.setValue(imageProperty, forKey: "diffuseTexture")
                    
                    //        let image2 = UIImage(named: "art.scnassets/photos_2017_11_3_fst_moss-textureDispSq.png")!
                    //        let image2Property = SCNMaterialProperty(contents: image2)
                    //        material.setValue(image2Property, forKey: "noiseTexture")
                    let program = SCNProgram()
                    program.fragmentFunctionName = "eightFragment"
                    program.vertexFunctionName = "myVertex"
                    material.program = program
                    //透過処理
                    program.isOpaque = false
                case "KokeDama09":
                    let image = UIImage(named: "art.scnassets/testes06.png")!
                    let imageProperty = SCNMaterialProperty(contents: image)
                    material.setValue(imageProperty, forKey: "diffuseTexture")
                    
                    //        let image2 = UIImage(named: "art.scnassets/photos_2017_11_3_fst_moss-textureDispSq.png")!
                    //        let image2Property = SCNMaterialProperty(contents: image2)
                    //        material.setValue(image2Property, forKey: "noiseTexture")
                    let program = SCNProgram()
                    program.fragmentFunctionName = "nineFragment"
                    program.vertexFunctionName = "myVertex"
                    material.program = program
                    //透過処理
                    program.isOpaque = false
                default:
                    break
                }
                
                sofaNode?.name = "tgt"
                sofaNode?.geometry?.firstMaterial = material
                sofaNode?.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
                sofaNode?.physicsBody?.categoryBitMask = 1
                sofaNode?.physicsBody?.restitution = 0// 弾み具合　0:弾まない 3:弾みすぎ
                sofaNode?.physicsBody?.damping = 1  // 空気の摩擦抵抗 1でゆっくり落ちる
                sofaNode?.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y + Float(0.5), hitResult.worldTransform.columns.3.z)
                sceneView.scene.rootNode.addChildNode(sofaNode!)
            }
        }
    }
    
    /*
     乱数を生成するメソッド.
     */
    func getRandomNumber(Min _Min : Float, Max _Max : Float)->Float {
        return ( Float(arc4random_uniform(UINT32_MAX)) / Float(UINT32_MAX) ) * (_Max - _Min) + _Min
    }
}

