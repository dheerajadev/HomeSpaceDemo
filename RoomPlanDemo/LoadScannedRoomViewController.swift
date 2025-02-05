//
//  LoadScannedRoomViewController.swift
//  RoomPlanDemo
//
//  Created by Appscrip 3Embed on 03/02/25.
//

import UIKit
import RealityKit
import SceneKit
import Combine
import RoomPlan

private enum FeatureOptions {
    case floorPlan
    case blueprint
}

class LoadScannedRoomViewController: UIViewController {

    // MARK: - PROPERTIES
    
    private var model: CapturedRoom?
    private var modelFileUrl: URL
    private var modelNode: SCNNode?
    
    let sceneView: SCNView = {
        let view = SCNView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.allowsCameraControl = true // Enables default rotation/pan/zoom
        return view
    }()
    
    let debugLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.backgroundColor = .black.withAlphaComponent(0.7)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    // MARK: MAIN -
    
    init(model: CapturedRoom?, url: URL) {
        self.model = model
        self.modelFileUrl = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpConstraints()
        setupScene()
        setupNavigationBar()
        loadScannedRoom()
        
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews() {
        view.backgroundColor = .black
        view.addSubview(sceneView)
        view.addSubview(debugLabel)
    }
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            
            debugLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            debugLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            debugLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }
    
    private func setupScene() {
        let scene = SCNScene()
        
        // Setup camera
        let camera = SCNCamera()
        camera.automaticallyAdjustsZRange = true
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)
        
        // Main directional light (simulates sun)
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 600
        directionalLight.light?.temperature = 6500
        directionalLight.light?.castsShadow = true
        directionalLight.position = SCNVector3(5, 5, 5)
        directionalLight.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/4, 0)
        scene.rootNode.addChildNode(directionalLight)
        
        // Fill light (softer light from opposite direction)
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.intensity = 300
        fillLight.light?.temperature = 4000
        fillLight.position = SCNVector3(-3, 0, -3)
        scene.rootNode.addChildNode(fillLight)
        
        // Ambient light (general soft illumination)
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 150
        ambientLight.light?.temperature = 5500
        scene.rootNode.addChildNode(ambientLight)
        
        // Configure SceneView
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.defaultCameraController.interactionMode = .orbitTurntable
        sceneView.defaultCameraController.minimumVerticalAngle = -60
        sceneView.defaultCameraController.maximumVerticalAngle = 60
        sceneView.defaultCameraController.inertiaEnabled = true
        
        // Set scene options
        sceneView.backgroundColor = .white
        scene.background.contents = UIColor.white
        
        // Set environment lighting
        scene.lightingEnvironment.intensity = 1.0
        scene.lightingEnvironment.contents = UIColor.darkGray.cgColor
    }
    
    private func setupNavigationBar() {
        let exportButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(exportButtonTapped)
        )
        
        let measureButton = UIBarButtonItem(
            image: UIImage(systemName: "ruler"),
            style: .plain,
            target: self,
            action: #selector(toggleMeasurements)
        )
        
        let modeButton = UIBarButtonItem(
            image: UIImage(systemName: "square.3.stack.3d.top.filled"),
            style: .plain,
            target: self,
            action: #selector(showViewModeOptions)
        )
        
        exportButton.tintColor = .black
        measureButton.tintColor = .black
        modeButton.tintColor = .black
        
        navigationItem.rightBarButtonItems = [exportButton, measureButton, modeButton]
    }
    
    @objc private func exportButtonTapped() {
        
        let fileURL = modelFileUrl
        
        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        
        present(activityVC, animated: true)
    }
    
    @objc private func showViewModeOptions() {
        let alert = UIAlertController(title: "Features", message: "Select option", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Floor Plan", style: .default) { [weak self] _ in
            self?.featureSelected(FeatureOptions.floorPlan)
        })
        
        alert.addAction(UIAlertAction(title: "Blueprint", style: .default) { [weak self] _ in
            self?.featureSelected(FeatureOptions.blueprint)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        present(alert, animated: true)
    }
    
    private func featureSelected(_ option: FeatureOptions) {
        
        switch option {
        case .floorPlan:
            guard let model else { return }
            let controller = FloorPlanViewController(capturedRoom: model)
            navigationController?.pushViewController(controller, animated: true)
            
        case .blueprint:
            break
        }
    }
    
    func loadScannedRoom() {
        
        let fileUrl = modelFileUrl
        debugLabel.text = "Loading model from: \(fileUrl.lastPathComponent)"
        
        do {
            
            // Try loading the .usdz model
            let scene = try SCNScene(url: fileUrl, options: [.checkConsistency: true])
            
            // Print the number of child nodes to help with debugging
            print("Root node has \(scene.rootNode.childNodes.count) child nodes.")
            
            // Get the root node of the loaded model
            modelNode = scene.rootNode.childNodes.first
            
            if let modelNode {
                // Create a container node for centering
                let containerNode = SCNNode()
                sceneView.scene?.rootNode.addChildNode(containerNode)
                containerNode.addChildNode(modelNode)
                
                // Calculate the bounding box of the model
                let boundingBox = modelNode.boundingBox
                let boundingBoxMin = boundingBox.min
                let boundingBoxMax = boundingBox.max
                
                // Calculate center offset
                let centerX = (boundingBoxMin.x + boundingBoxMax.x) / 2
                let centerY = (boundingBoxMin.y + boundingBoxMax.y) / 2
                let centerZ = (boundingBoxMin.z + boundingBoxMax.z) / 2
                
                // Move model to center
                modelNode.position = SCNVector3(-centerX, -centerY, -centerZ)
                
                // Calculate model size
                let modelSize = SCNVector3(
                    boundingBoxMax.x - boundingBoxMin.x,
                    boundingBoxMax.y - boundingBoxMin.y,
                    boundingBoxMax.z - boundingBoxMin.z
                )
                
                // Calculate scale to fit view
                let maxDimension = max(modelSize.x, max(modelSize.y, modelSize.z))
                let scale = 2.0 / maxDimension // Scale to fit in a 2x2x2 cube
                containerNode.scale = SCNVector3(scale, scale, scale)
                
                debugLabel.text = "Use pinch to zoom, pan to rotate, and two fingers to move"
                
                // Ensure model is visible
                sceneView.pointOfView = sceneView.scene?.rootNode.childNode(withName: "camera", recursively: true)
            } else {
                self.debugLabel.text = "Model not found!"
            }
            
        } catch {
            debugLabel.text = "Error: \(error.localizedDescription)"
            print("Failed to load model: \(error.localizedDescription)")
            
            let errorAlert = UIAlertController(
                title: "Error",
                message: "Failed to load room model: \(error.localizedDescription)",
                preferredStyle: .alert
            )
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
            present(errorAlert, animated: true)
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Alert",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - ACTIONS
    
    @objc private func toggleMeasurements() {
        
    }
     
}
