//
//  ARSceneViewController.swift
//  FloateingSights
//
//  Created by takedatakashiki on 2026/04/10.
//

@preconcurrency import ARKit
@preconcurrency import SceneKit
import UIKit

final class ARSceneViewController: UIViewController, ScrollViewDelegate, ARSCNViewDelegate {
    // MARK: - UI Properties

    private let sceneView = ARSCNView(frame: .zero)
    private let controlView = UIView()
    private let uiSwitch = UISwitch()
    private let resetButton = UIButton(type: .system)
    private let letsFloatButton = UIButton(type: .system)
    private let rotateButton = UIButton(type: .system)
    private let menuView = UIView()
    private let menuButton = UIButton(type: .system)
    private let scrollView = TouchScrollView()

    // MARK: - State

    var isMenuOpen = true
    var planeNodes: [PlaneNode] = []
    var sofaNode: SCNNode?
    private lazy var startTime = Date()
    fileprivate var _display_link: CADisplayLink!
    var isFloat: Bool = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpARSceneView()
        setUpMenuView()
        setUpControlView()

        scrollView.Delegate = self
        sceneView.delegate = self
        sceneView.showsStatistics = true

        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateTime()
        }

        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true

        toggleMenu()
        initializeMenu()

        resetButton.addTarget(self, action: #selector(onClickMyButton(sender:)), for: .touchDown)
        letsFloatButton.addTarget(self, action: #selector(onClickFloat(sender:)), for: .touchDown)
        letsFloatButton.addTarget(self, action: #selector(outClickFloat(sender:)), for: .touchUpInside)
        rotateButton.addTarget(self, action: #selector(onClickRotate), for: .touchDown)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)

        _display_link = CADisplayLink(target: self, selector: #selector(polling(_:)))
        _display_link.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sceneView.session.pause()
        _display_link.remove(from: RunLoop.current, forMode: RunLoop.Mode.common)
    }

    // MARK: - Setup

    private func setUpARSceneView() {
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setUpControlView() {
        let screen = UIScreen.main.bounds
        let buttonW: CGFloat = 64
        let buttonH: CGFloat = 36
        let spacing: CGFloat = 8
        let switchW: CGFloat = 51
        let totalW = switchW + spacing + buttonW + spacing + buttonW + spacing + buttonW

        controlView.backgroundColor = UIColor(white: 0, alpha: 0)
        controlView.frame = CGRect(x: screen.width - totalW - 16, y: 48, width: totalW, height: buttonH)
        view.addSubview(controlView)

        uiSwitch.frame = CGRect(x: 0, y: (buttonH - 31) / 2, width: switchW, height: 31)
        controlView.addSubview(uiSwitch)

        var xOffset = switchW + spacing
        for (button, title) in [(resetButton, "Reset"), (letsFloatButton, "Float"), (rotateButton, "Rotate")] {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            button.backgroundColor = UIColor(white: 0.15, alpha: 0.7)
            button.layer.cornerRadius = 8
            button.frame = CGRect(x: xOffset, y: 0, width: buttonW, height: buttonH)
            controlView.addSubview(button)
            xOffset += buttonW + spacing
        }
    }

    private func setUpMenuView() {
        let screen = UIScreen.main.bounds

        menuView.frame = CGRect(x: 0, y: screen.height - 50, width: screen.width, height: 300)
        menuView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        view.addSubview(menuView)

        menuButton.frame = CGRect(x: screen.width / 2 - 30, y: 0, width: 60, height: 50)
        menuButton.setImage(UIImage(named: "open"), for: .normal)
        menuButton.addTarget(self, action: #selector(menuButtonTapped(_:)), for: .touchUpInside)
        menuView.addSubview(menuButton)

        scrollView.frame = CGRect(x: 0, y: 50, width: screen.width, height: 200)
        scrollView.showsHorizontalScrollIndicator = false
        menuView.addSubview(scrollView)
    }

    // MARK: - Time Update

    private func updateTime() {
        var time = Float(Date().timeIntervalSince(startTime))
        let timeData = withUnsafeBytes(of: &time) { Data($0) }
        sofaNode?.geometry?.firstMaterial?.setValue(timeData, forKey: "time")
    }

    // MARK: - CADisplayLink

    @objc func polling(_: CADisplayLink) {
        if sofaNode != nil {
            if isFloat == true {
                if (sofaNode?.position.y)! < Float(0.3) {
                    sofaNode?.physicsBody?.isAffectedByGravity = false
                    sofaNode?.runAction(SCNAction.move(to: SCNVector3((sofaNode?.position.x)!, 0.5, (sofaNode?.position.z)!), duration: 5))
                }
                switch (sofaNode?.position.y)! {
                case 0.5:
                    sofaNode?.runAction(SCNAction.move(to: SCNVector3((sofaNode?.position.x)!, 0.3, (sofaNode?.position.z)!), duration: 3.5))
                case 0.3:
                    sofaNode?.runAction(SCNAction.move(to: SCNVector3((sofaNode?.position.x)!, 0.5, (sofaNode?.position.z)!), duration: 4))
                default:
                    break
                }
            }
        }
    }

    // MARK: - Touch

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let touchEvent = touches.first!
        let touchLocation = touchEvent.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        if !hitTestResult.isEmpty, let hitResult = hitTestResult.first {
            sofaNode?.position = SCNVector3(
                hitResult.worldTransform.columns.3.x,
                hitResult.worldTransform.columns.3.y + Float(0.05),
                hitResult.worldTransform.columns.3.z
            )
        }
    }

    // MARK: - ARSCNViewDelegate

    nonisolated func renderer(_: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        Task { @MainActor in
            if let planeAnchor = anchor as? ARPlaneAnchor {
                let panelNode = PlaneNode(anchor: planeAnchor)
                panelNode.isDisplay = true
                node.addChildNode(panelNode)
                self.planeNodes.append(panelNode)
            }
        }
    }

    nonisolated func renderer(_: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        Task { @MainActor in
            if let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node.childNodes[0] as? PlaneNode {
                planeNode.isHidden = !self.uiSwitch.isOn
                planeNode.update(anchor: planeAnchor)
            }
        }
    }

    // MARK: - Menu

    @objc private func menuButtonTapped(_: UIButton) {
        toggleMenu()
    }

    func toggleMenu() {
        if isMenuOpen {
            controlView.isHidden = false
            isMenuOpen = false
            menuButton.setImage(UIImage(named: "open"), for: .normal)
            UIView.animate(withDuration: 0.5) {
                self.menuView.frame.origin.y = UIScreen.main.bounds.height - 50
            }
        } else {
            controlView.isHidden = true
            for imageView in scrollView.subviews {
                imageView.layer.borderWidth = 0
            }
            isMenuOpen = true
            menuButton.setImage(UIImage(named: "close"), for: .normal)
            UIView.animate(withDuration: 0.5) {
                self.menuView.frame.origin.y = UIScreen.main.bounds.height - 300
            }
        }
    }

    func initializeMenu() {
        let imageWidth = 250
        let imageHeight = 200
        let margin = 20
        let imageNames = ["😱", "😄", "✌️", "⚪️", "😁"]

        scrollView.contentSize = CGSize(width: (imageWidth + margin) * imageNames.count, height: imageHeight)
        scrollView.isUserInteractionEnabled = true

        for i in 0 ..< imageNames.count {
            let label = UILabel()
            label.text = imageNames[i]
            label.font = UIFont.systemFont(ofSize: 120)
            label.textAlignment = .center
            label.tag = i + 1
            label.isUserInteractionEnabled = true
            label.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.0)
            label.layer.borderColor = UIColor.white.cgColor
            label.layer.borderWidth = 0
            label.layer.masksToBounds = true
            label.layer.cornerRadius = 10
            label.frame = CGRect(x: i * (imageWidth + margin), y: 0, width: imageWidth, height: imageHeight)
            scrollView.addSubview(label)
        }
    }

    // MARK: - Button Actions

    @objc private func onClickMyButton(sender _: UIButton) {
        sceneView.scene.rootNode.childNode(withName: "tgt", recursively: true)?.removeFromParentNode()
    }

    @objc private func onClickFloat(sender _: UIButton) {
        isFloat = true
    }

    @objc private func outClickFloat(sender _: UIButton) {
        isFloat = false
    }

    @objc private func onClickRotate() {
        sofaNode?.physicsBody?.applyTorque(SCNVector4(0, 10, 0, -1.0), asImpulse: false)
    }

    // MARK: - ScrollViewDelegate

    func scrollViewTapped(tag: Int) {
        let imageView = scrollView.subviews[tag - 1]
        imageView.layer.borderWidth = 10

        toggleMenu()

        let hitTestResult = sceneView.hitTest(sceneView.center, types: .existingPlaneUsingExtent)
        guard !hitTestResult.isEmpty, let hitResult = hitTestResult.first else { return }

        let sceneNames = ["KokeDama05", "KokeDama06", "KokeDama07", "KokeDama08", "KokeDama09"]
        let fragmentFunctions = ["myFragment", "sixFragment", "sevenFragment", "eightFragment", "nineFragment"]
        let assetsName = "art.scnassets"

        sofaNode = Furniture.create(sceneName: "\(assetsName)/\(sceneNames[tag - 1]).scn", width: 0.15)

        let material = SCNMaterial()
        let image = UIImage(named: "art.scnassets/testes06.png")!
        let imageProperty = SCNMaterialProperty(contents: image)
        material.setValue(imageProperty, forKey: "diffuseTexture")

        let program = SCNProgram()
        program.fragmentFunctionName = fragmentFunctions[tag - 1]
        program.vertexFunctionName = "myVertex"
        program.isOpaque = false
        material.program = program

        sofaNode?.name = "tgt"
        sofaNode?.geometry?.firstMaterial = material
        sofaNode?.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        sofaNode?.physicsBody?.categoryBitMask = 1
        sofaNode?.physicsBody?.restitution = 0
        sofaNode?.physicsBody?.damping = 1
        sofaNode?.position = SCNVector3(
            hitResult.worldTransform.columns.3.x,
            hitResult.worldTransform.columns.3.y + Float(0.5),
            hitResult.worldTransform.columns.3.z
        )
        sceneView.scene.rootNode.addChildNode(sofaNode!)
    }
}
