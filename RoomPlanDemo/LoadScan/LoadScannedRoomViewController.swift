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
}

private enum MeasurementUnit: String, CaseIterable {
    case meters = "Meters"
    case feet = "Feet"
    case inches = "Inches"
}

class LoadScannedRoomViewController: UIViewController {

    // MARK: - PROPERTIES
    
    private var model: CapturedRoom?
    private var modelFileUrl: URL
    private var modelNode: SCNNode?
    private var dimensionNodes: [SCNNode] = []
    private var isMeasurementsVisible = false
    private var measurementMode = false
    private var firstPoint: SCNVector3?
    private var temporaryNodes: [SCNNode] = []
    private var measurementNodes: [SCNNode] = []
    private var measurementGroups: [[SCNNode]] = []
    private var tapGesture: UITapGestureRecognizer?
    private var longPressGesture: UILongPressGestureRecognizer?
    private var currentUnit: MeasurementUnit = .meters
    
    let sceneView: SCNView = {
        let view = SCNView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.autoenablesDefaultLighting = true
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
    
    private let unitControl: UISegmentedControl = {
        let control = UISegmentedControl(items: MeasurementUnit.allCases.map { $0.rawValue })
        control.selectedSegmentIndex = 0
        control.backgroundColor = .white
        control.selectedSegmentTintColor = .systemBlue
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
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
        setupNavigationBar()
        loadScannedRoom()
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews() {
        view.backgroundColor = .black
        view.addSubview(sceneView)
        view.addSubview(debugLabel)
        view.addSubview(unitControl)
        
        unitControl.addTarget(self, action: #selector(unitChanged(_:)), for: .valueChanged)
        unitControl.isHidden = true  // Initially hide the unit control
    }
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            
            debugLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            debugLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            debugLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            
            unitControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            unitControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            unitControl.widthAnchor.constraint(equalToConstant: 250)
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
        
        // Add basic ambient light just to make model visible
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500  // High intensity for full visibility
        ambientLight.light?.temperature = 4000  // Neutral white light
        scene.rootNode.addChildNode(ambientLight)
        
        // Add subtle omnidirectional light to prevent completely flat appearance
        let omniLight = SCNNode()
        omniLight.light = SCNLight()
        omniLight.light?.type = .omni
        omniLight.light?.intensity = 200
        omniLight.position = SCNVector3(0, 0, 10)
        omniLight.light?.castsShadow = false
        scene.rootNode.addChildNode(omniLight)
        
        // Configure SceneView
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.defaultCameraController.interactionMode = .orbitTurntable
        sceneView.defaultCameraController.minimumVerticalAngle = -60
        sceneView.defaultCameraController.maximumVerticalAngle = 60
        sceneView.defaultCameraController.inertiaEnabled = true
        
        // Set scene options
        let backgroundColor = UIColor(hex: "#EFF6EE")
        sceneView.backgroundColor = backgroundColor
        scene.background.contents = backgroundColor
        
        // Enable basic environment lighting
        scene.lightingEnvironment.intensity = 1.0
        scene.lightingEnvironment.contents = backgroundColor
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
    
    private func featureSelected(_ option: FeatureOptions) {
        
        switch option {
        case .floorPlan:
            guard let model else { return }
            
            let controller = FloorPlanViewController(capturedRoom: model)
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func loadScannedRoom() {
        let fileUrl = modelFileUrl
        debugLabel.text = "Loading model from: \(fileUrl.lastPathComponent)"
        
        do {
            // Try loading the .usdz model
            let scene = try SCNScene(url: fileUrl, options: [.checkConsistency: true])
            
            // Set up scene background and lighting
            let dimWhiteColor = UIColor(hex: "#EFF6EE")
            scene.background.contents = dimWhiteColor
            sceneView.backgroundColor = dimWhiteColor
            setupScene()
            
            // Process and color the nodes
            scene.rootNode.enumerateChildNodes { (node, _) in
                // Color based on node name or geometry
                if node.name?.lowercased().contains("floor") == true {
                    node.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
                } else if node.name?.lowercased().contains("wall") == true {
                    node.geometry?.firstMaterial?.diffuse.contents = UIColor(hex: "#B0C4DE", alpha: 0.6)
                } else if node.geometry != nil {
                    node.geometry?.firstMaterial?.diffuse.contents = UIColor(hex: "#B5A999")
                }
            }
            
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
    
    @objc private func showViewModeOptions() {
        let alert = UIAlertController(title: "Features", message: "Select option", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Floor Plan", style: .default) { [weak self] _ in
            self?.featureSelected(FeatureOptions.floorPlan)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        present(alert, animated: true)
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
    
    @objc private func toggleMeasurements() {
        measurementMode.toggle()
        
        if measurementMode {
            debugLabel.text = "Tap to select first point"
            
            // Create and add tap gesture
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tapGesture?.delegate = self
            sceneView.addGestureRecognizer(tapGesture!)
            
            // Create and add long press gesture
            longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            longPressGesture?.minimumPressDuration = 0.5
            longPressGesture?.delegate = self
            sceneView.addGestureRecognizer(longPressGesture!)
            
            // Add clear measurements button with red color
            let clearButton = UIBarButtonItem(
                image: UIImage(systemName: "trash"),
                style: .plain,
                target: self,
                action: #selector(showClearOptions)
            )
            clearButton.tintColor = .systemRed
            navigationItem.rightBarButtonItems?.insert(clearButton, at: 1)
            
            // Change ruler button color to indicate active state
            if let measureButton = navigationItem.rightBarButtonItems?[2] {
                measureButton.tintColor = .systemGreen
            }
            
            // Show unit control
            unitControl.isHidden = false
            
        } else {
            debugLabel.text = "Use pinch to zoom, pan to rotate, and two fingers to move"
            
            // Clear all measurements first
            clearMeasurements()
            
            // Remove gestures
            if let tapGesture = tapGesture {
                sceneView.removeGestureRecognizer(tapGesture)
            }
            if let longPressGesture = longPressGesture {
                sceneView.removeGestureRecognizer(longPressGesture)
            }
            tapGesture = nil
            longPressGesture = nil
            
            // Remove clear button
            if navigationItem.rightBarButtonItems?.count == 4 {
                navigationItem.rightBarButtonItems?.remove(at: 1)
            }
            
            // Reset ruler button color
            if let measureButton = navigationItem.rightBarButtonItems?[1] {
                measureButton.tintColor = .black
            }
            
            // Hide unit control
            unitControl.isHidden = true
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        
        // Perform hit test with existing geometry
        let hitResults = sceneView.hitTest(location, options: [
            .searchMode: SCNHitTestSearchMode.closest.rawValue,
            .boundingBoxOnly: true
        ])
        
        guard let result = hitResults.first else { return }
        
        if firstPoint == nil {
            // First point selected
            firstPoint = result.worldCoordinates
            addPoint(at: result.worldCoordinates, color: UIColor.black)
            debugLabel.text = "Tap to select second point"
        } else {
            // Second point selected
            let secondPoint = result.worldCoordinates
            addMeasurementLine(from: firstPoint!, to: secondPoint)
            firstPoint = nil
            debugLabel.text = "Tap to select first point"
        }
    }
    
    @objc private func showClearOptions() {
        let alert = UIAlertController(title: "Clear Measurements", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
            self?.clearMeasurements()
        })
        
        alert.addAction(UIAlertAction(title: "Clear Last", style: .default) { [weak self] _ in
            self?.clearLastMeasurement()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?[1]
        }
        
        present(alert, animated: true)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let location = gesture.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        
        for result in hitResults {
            if let measurementIndex = findMeasurementGroup(containing: result.node) {
                removeMeasurementGroup(at: measurementIndex)
                break
            }
        }
    }
    
    @objc private func unitChanged(_ sender: UISegmentedControl) {
        currentUnit = MeasurementUnit.allCases[sender.selectedSegmentIndex]
        
        // Update all existing measurements
        measurementGroups.forEach { group in
            if let dimensionNode = group.last { // Last node is dimension label
                let startPoint = group[1].position
                let endPoint = group[2].position
                let modelScale = modelNode?.parent?.scale.x ?? 1.0
                let distance = calculateRealWorldDistance(from: startPoint, to: endPoint, scale: modelScale)
                
                // Get the exact position in parent's coordinate space
                let parentNode = dimensionNode.parent
                let worldPosition = dimensionNode.worldPosition
                
                // Create new dimension label
                let newDimensionNode = createDimensionLabel(
                    at: worldPosition,
                    text: formatDistance(distance)
                )
                
                // Maintain exact position and orientation
                if let parent = parentNode {
                    parent.addChildNode(newDimensionNode)
                    newDimensionNode.transform = dimensionNode.transform
                } else {
                    sceneView.scene?.rootNode.addChildNode(newDimensionNode)
                }
                
                dimensionNode.removeFromParentNode()
                
                // Update the reference in measurementGroups
                if let groupIndex = measurementGroups.firstIndex(where: { $0.contains(dimensionNode) }),
                   let nodeIndex = measurementGroups[groupIndex].firstIndex(of: dimensionNode) {
                    measurementGroups[groupIndex][nodeIndex] = newDimensionNode
                }
            }
        }
    }
    
}

extension LoadScannedRoomViewController {
    
    func createDimensionLabel(at position: SCNVector3, text: String) -> SCNNode {
        let containerNode = SCNNode()
        containerNode.position = position
        
        // Create UILabel with explicit frame
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        label.text = text
        label.font = .systemFont(ofSize: 30, weight: .semibold) // Increased font size
        label.textColor = .white
        label.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.9)
        label.textAlignment = .center
        
        // Add padding and styling
        label.layer.masksToBounds = true
        label.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        
        // Size the label to fit content
        label.sizeToFit()
        // Add padding to frame
        label.frame = label.frame.insetBy(dx: -12, dy: -8)
        
        // Convert UILabel to image
        UIGraphicsBeginImageContextWithOptions(label.frame.size, false, UIScreen.main.scale)
        if let context = UIGraphicsGetCurrentContext() {
            label.layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let image = image {
                // Create plane geometry with label image as texture
                let plane = SCNPlane(width: CGFloat(label.frame.width) * 0.001,
                                   height: CGFloat(label.frame.height) * 0.001)
                let material = SCNMaterial()
                material.diffuse.contents = image
                material.isDoubleSided = true
                material.emission.contents = image // Make it glow slightly
                plane.materials = [material]
                
                let planeNode = SCNNode(geometry: plane)
                containerNode.addChildNode(planeNode)
            }
        }
        
        // Make label always face camera
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = [.X, .Y, .Z]
        containerNode.constraints = [billboardConstraint]
        
        // Offset slightly towards camera to prevent z-fighting
        containerNode.position = SCNVector3(
            position.x,
            position.y,
            position.z + 0.01
        )
        
        return containerNode
    }
    
    func addPoint(at position: SCNVector3, color: UIColor) {
        // Create a small sphere to mark the point
        let sphere = SCNSphere(radius: 0.02)
        sphere.firstMaterial?.diffuse.contents = color
        
        let node = SCNNode(geometry: sphere)
        node.position = position
        
        sceneView.scene?.rootNode.addChildNode(node)
        temporaryNodes.append(node)
    }
    
    func addMeasurementLine(from start: SCNVector3, to end: SCNVector3) {
        // Clear temporary points
        temporaryNodes.forEach { $0.removeFromParentNode() }
        temporaryNodes.removeAll()
        
        // Get the model's scale to adjust measurements
        let modelScale = modelNode?.parent?.scale.x ?? 1.0
        
        // Calculate real-world distance (accounting for model scale)
        let distance = calculateRealWorldDistance(from: start, to: end, scale: modelScale)
        
        // Create measurement nodes
        let line = createLine(from: start, to: end)
        let startPoint = createPoint(at: start, color: UIColor.white)
        let endPoint = createPoint(at: end, color: UIColor.white)
        
        // Position label at midpoint, slightly offset
        let midPoint = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )
        
        // Create dimension label with real-world distance
        let dimensionNode = createDimensionLabel(
            at: midPoint,
            text: formatDistance(distance)
        )
        
        // Add nodes to scene
        let nodes = [line, startPoint, endPoint, dimensionNode]
        nodes.forEach { sceneView.scene?.rootNode.addChildNode($0) }
        
        // Store measurement group
        measurementGroups.append(nodes)
        measurementNodes.append(contentsOf: nodes)
    }
    
    func createLine(from start: SCNVector3, to end: SCNVector3) -> SCNNode {
        let lineGeometry = SCNCylinder(
            radius: 0.002,
            height: CGFloat(distance(from: start, to: end))
        )
        lineGeometry.firstMaterial?.diffuse.contents = UIColor.black
        
        let node = SCNNode(geometry: lineGeometry)
        
        // Position at midpoint
        let position = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )
        node.position = position
        
        // Calculate the direction vector
        let direction = SCNVector3(
            end.x - start.x,
            end.y - start.y,
            end.z - start.z
        )
        
        // Orient the cylinder
        let height = sqrt(
            direction.x * direction.x +
            direction.y * direction.y +
            direction.z * direction.z
        )
        
        if height > 0 {
            let pitch = acos(direction.y / height)
            let yaw = atan2(direction.x, direction.z)
            
            node.eulerAngles = SCNVector3(pitch, yaw, 0)
        }
        
        return node
    }
    
    func distance(from start: SCNVector3, to end: SCNVector3) -> Float {
        return sqrt(
            pow(end.x - start.x, 2) +
            pow(end.y - start.y, 2) +
            pow(end.z - start.z, 2)
        )
    }
    
    func clearMeasurements() {
        // Remove all temporary nodes
        temporaryNodes.forEach { node in
            node.removeFromParentNode()
        }
        temporaryNodes.removeAll()
        
        // Remove all measurement nodes
        measurementNodes.forEach { node in
            node.removeFromParentNode()
        }
        measurementNodes.removeAll()
        
        // Remove all measurement groups
        measurementGroups.forEach { group in
            group.forEach { node in
                node.removeFromParentNode()
            }
        }
        measurementGroups.removeAll()
        
        // Reset first point
        firstPoint = nil
    }
    
    private func findMeasurementGroup(containing node: SCNNode) -> Int? {
        return measurementGroups.firstIndex { group in
            group.contains { $0 == node || $0.childNodes.contains(node) }
        }
    }
    
    private func removeMeasurementGroup(at index: Int) {
        let group = measurementGroups.remove(at: index)
        group.forEach { node in
            node.removeFromParentNode()
            if let index = measurementNodes.firstIndex(of: node) {
                measurementNodes.remove(at: index)
            }
        }
    }
    
    private func clearLastMeasurement() {
        guard !measurementGroups.isEmpty else { return }
        removeMeasurementGroup(at: measurementGroups.count - 1)
    }
    
    private func createPoint(at position: SCNVector3, color: UIColor) -> SCNNode {
        let sphere = SCNSphere(radius: 0.02)
        sphere.firstMaterial?.diffuse.contents = color
        
        let node = SCNNode(geometry: sphere)
        node.position = position
        return node
    }
    
    private func calculateRealWorldDistance(from start: SCNVector3, to end: SCNVector3, scale: Float) -> Float {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dz = end.z - start.z
        
        // Calculate the actual distance in scene units
        let sceneDistance = sqrt(dx * dx + dy * dy + dz * dz)
        
        // Convert to real-world meters (accounting for model scale)
        return sceneDistance / scale
    }
    
    private func formatDistance(_ distance: Float) -> String {
        switch currentUnit {
        case .meters:
            if distance < 1.0 {
                return String(format: "%.0f cm", distance * 100)
            } else {
                return String(format: "%.2f m", distance)
            }
            
        case .feet:
            let feet = distance * 3.28084
            if feet < 1.0 {
                return String(format: "%.1f in", feet * 12)
            } else {
                let wholeFeet = Int(feet)
                let inches = (feet - Float(wholeFeet)) * 12
                if inches > 0 {
                    return String(format: "%d' %.1f\"", wholeFeet, inches)
                } else {
                    return String(format: "%d'", wholeFeet)
                }
            }
            
        case .inches:
            let inches = distance * 39.3701
            return String(format: "%.1f\"", inches)
        }
    }
    
}

extension LoadScannedRoomViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow measurement gestures to work alongside SceneKit's built-in gestures
        if gestureRecognizer == tapGesture || gestureRecognizer == longPressGesture {
            return true
        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Make sure tap gesture doesn't interfere with double-tap zoom
        if gestureRecognizer == tapGesture && otherGestureRecognizer is UITapGestureRecognizer {
            return otherGestureRecognizer.numberOfTouches > 1
        }
        return false
    }
}

// Add this extension to help with padding
extension UIEdgeInsets {
    func inverted() -> UIEdgeInsets {
        return UIEdgeInsets(top: -top,
                           left: -left,
                           bottom: -bottom,
                           right: -right)
    }
}
