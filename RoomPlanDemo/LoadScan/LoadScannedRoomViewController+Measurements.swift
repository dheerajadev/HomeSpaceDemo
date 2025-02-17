//
//  LoadScannedRoomViewController+Measurements.swift
//  RoomPlanDemo
//
//  Created by Appscrip 3Embed on 17/02/25.
//

import UIKit
import SceneKit

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
    
    func findMeasurementGroup(containing node: SCNNode) -> Int? {
        return measurementGroups.firstIndex { group in
            group.contains { $0 == node || $0.childNodes.contains(node) }
        }
    }
    
    func removeMeasurementGroup(at index: Int) {
        let group = measurementGroups.remove(at: index)
        group.forEach { node in
            node.removeFromParentNode()
            if let index = measurementNodes.firstIndex(of: node) {
                measurementNodes.remove(at: index)
            }
        }
    }
    
    func clearLastMeasurement() {
        guard !measurementGroups.isEmpty else { return }
        removeMeasurementGroup(at: measurementGroups.count - 1)
    }
    
    func createPoint(at position: SCNVector3, color: UIColor) -> SCNNode {
        let sphere = SCNSphere(radius: 0.02)
        sphere.firstMaterial?.diffuse.contents = color
        
        let node = SCNNode(geometry: sphere)
        node.position = position
        return node
    }
    
    func calculateRealWorldDistance(from start: SCNVector3, to end: SCNVector3, scale: Float) -> Float {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dz = end.z - start.z
        
        // Calculate the actual distance in scene units
        let sceneDistance = sqrt(dx * dx + dy * dy + dz * dz)
        
        // Convert to real-world meters (accounting for model scale)
        return sceneDistance / scale
    }
    
    func formatDistance(_ distance: Float) -> String {
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
        }
    }
    
}

