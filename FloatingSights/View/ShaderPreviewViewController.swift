//
//  ShaderPreviewViewController.swift
//  FloatingSights
//
//  Created by takedatakashiki on 2026/04/11.
//

@preconcurrency import SceneKit
import UIKit

final class ShaderPreviewViewController: UIViewController {
    // MARK: - Data Model

    private struct ShaderItem {
        let emoji: String
        let sceneName: String
        let fragmentFunction: String
    }

    private let items: [ShaderItem] = [
        ShaderItem(emoji: "😱", sceneName: "art.scnassets/FloatingObject05.scn", fragmentFunction: "myFragment"),
        ShaderItem(emoji: "😄", sceneName: "art.scnassets/FloatingObject06.scn", fragmentFunction: "sixFragment"),
        ShaderItem(emoji: "✌️", sceneName: "art.scnassets/FloatingObject07.scn", fragmentFunction: "sevenFragment"),
        ShaderItem(emoji: "⚪️", sceneName: "art.scnassets/FloatingObject08.scn", fragmentFunction: "eightFragment"),
        ShaderItem(emoji: "😁", sceneName: "art.scnassets/FloatingObject09.scn", fragmentFunction: "nineFragment"),
    ]

    // MARK: - UI Properties

    private let scnView = SCNView(frame: .zero)
    private let selectorScrollView = UIScrollView()
    private var selectedIndex: Int = 0

    // MARK: - Scene Properties

    private var currentObjectNode: SCNNode?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "シェーダー"
        view.backgroundColor = .black

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance

        setUpSceneView()
        setUpScene()
        setUpSelector()
        loadItem(at: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scnView.isPlaying = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scnView.isPlaying = false
    }

    // MARK: - Setup

    private func setUpSceneView() {
        scnView.translatesAutoresizingMaskIntoConstraints = false
        scnView.backgroundColor = .black
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        view.addSubview(scnView)

        NSLayoutConstraint.activate([
            scnView.topAnchor.constraint(equalTo: view.topAnchor),
            scnView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scnView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scnView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setUpScene() {
        let scene = SCNScene()
        scnView.scene = scene

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.01
        cameraNode.camera?.zFar = 100
        cameraNode.position = SCNVector3(0, 0.1, 0.5)
        cameraNode.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(cameraNode)
        scnView.pointOfView = cameraNode

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.4, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)

        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = UIColor(white: 0.8, alpha: 1.0)
        directionalLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
        scene.rootNode.addChildNode(directionalLight)
    }

    private func setUpSelector() {
        let selectorBackground = UIView()
        selectorBackground.translatesAutoresizingMaskIntoConstraints = false
        selectorBackground.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.addSubview(selectorBackground)

        selectorScrollView.translatesAutoresizingMaskIntoConstraints = false
        selectorScrollView.showsHorizontalScrollIndicator = false
        selectorBackground.addSubview(selectorScrollView)

        let selectorHeight: CGFloat = 80

        NSLayoutConstraint.activate([
            selectorBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            selectorBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            selectorBackground.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            selectorBackground.heightAnchor.constraint(equalToConstant: selectorHeight),

            selectorScrollView.topAnchor.constraint(equalTo: selectorBackground.topAnchor),
            selectorScrollView.leadingAnchor.constraint(equalTo: selectorBackground.leadingAnchor),
            selectorScrollView.trailingAnchor.constraint(equalTo: selectorBackground.trailingAnchor),
            selectorScrollView.bottomAnchor.constraint(equalTo: selectorBackground.bottomAnchor),
        ])

        let itemWidth: CGFloat = 70
        let itemSpacing: CGFloat = 12
        let totalWidth = CGFloat(items.count) * itemWidth + CGFloat(items.count - 1) * itemSpacing
        selectorScrollView.contentSize = CGSize(width: totalWidth, height: selectorHeight)

        for (index, item) in items.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(item.emoji, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 40)
            button.frame = CGRect(
                x: CGFloat(index) * (itemWidth + itemSpacing),
                y: 0,
                width: itemWidth,
                height: selectorHeight
            )
            button.layer.cornerRadius = 10
            button.layer.borderColor = UIColor.white.cgColor
            button.layer.borderWidth = 0
            button.addTarget(self, action: #selector(selectorTapped(_:)), for: .touchUpInside)
            selectorScrollView.addSubview(button)
        }

        updateSelectorHighlight(selectedIndex: 0)
    }

    // MARK: - Actions

    @objc private func selectorTapped(_ sender: UIButton) {
        loadItem(at: sender.tag)
    }

    // MARK: - Object Loading

    private func loadItem(at index: Int) {
        currentObjectNode?.removeFromParentNode()

        let item = items[index]
        selectedIndex = index
        updateSelectorHighlight(selectedIndex: index)

        let node = Furniture.create(sceneName: item.sceneName, width: 0.15)

        let material = SCNMaterial()
        let image = UIImage(named: "art.scnassets/testes06.png")!
        let imageProperty = SCNMaterialProperty(contents: image)
        material.setValue(imageProperty, forKey: "diffuseTexture")

        let program = SCNProgram()
        program.vertexFunctionName = "myVertex"
        program.fragmentFunctionName = item.fragmentFunction
        program.isOpaque = false
        material.program = program

        node.name = "preview"
        node.geometry?.firstMaterial = material
        node.position = SCNVector3Zero

        let rotateAction = SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 10)
        )
        node.runAction(rotateAction, forKey: "autoRotate")

        scnView.scene?.rootNode.addChildNode(node)
        currentObjectNode = node
    }

    // MARK: - Helpers

    private func updateSelectorHighlight(selectedIndex: Int) {
        for case let button as UIButton in selectorScrollView.subviews {
            button.layer.borderWidth = (button.tag == selectedIndex) ? 3 : 0
            button.backgroundColor = (button.tag == selectedIndex)
                ? UIColor(white: 1, alpha: 0.15)
                : .clear
        }
    }
}
