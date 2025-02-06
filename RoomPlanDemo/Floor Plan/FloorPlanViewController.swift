//
//  FloorPlanViewController.swift
//  RoomPlanDemo
//
//  Created by Appscrip 3Embed on 05/02/25.
//

import UIKit
import RoomPlan
import simd

class FloorPlanViewController: UIViewController {
    
    var capturedRoom: CapturedRoom
    private var floorPlanView: FloorPlanView!
    
    init(capturedRoom: CapturedRoom) {
        self.capturedRoom = capturedRoom
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupFloorPlanView()
    }
    
    private func setupFloorPlanView() {
        floorPlanView = FloorPlanView(capturedRoom: capturedRoom)
        floorPlanView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(floorPlanView)
        
        NSLayoutConstraint.activate([
            floorPlanView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            floorPlanView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            floorPlanView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            floorPlanView.heightAnchor.constraint(equalTo: floorPlanView.widthAnchor) // Make it square
        ])
    }
}

class FloorPlanView: UIView {
    private let capturedRoom: CapturedRoom
    private var shapeLayer: CAShapeLayer?
    
    init(capturedRoom: CapturedRoom) {
        self.capturedRoom = capturedRoom
        super.init(frame: .zero)
        backgroundColor = .white
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawFloorPlan()
    }
    
    private func drawFloorPlan() {
        // Remove existing shape layer and labels
        shapeLayer?.removeFromSuperlayer()
        subviews.forEach { $0.removeFromSuperview() }
        
        guard let floorSurface = capturedRoom.floors.first(where: { $0.category == .floor }) else {
            print("No floor surface found")
            return
        }
        
        // Create new shape layer
        let shapeLayer = CAShapeLayer()
        self.shapeLayer = shapeLayer
        
        let path = UIBezierPath()
        
        // Get floor dimensions and transform
        let dimensions = floorSurface.dimensions
        let transform = floorSurface.transform
        
        // Calculate corners of the floor rectangle
        let width = dimensions.x
        let length = dimensions.z
        let corners = [
            SIMD3<Float>(-width/2, 0, -length/2),  // Bottom left
            SIMD3<Float>(width/2, 0, -length/2),   // Bottom right
            SIMD3<Float>(width/2, 0, length/2),    // Top right
            SIMD3<Float>(-width/2, 0, length/2)    // Top left
        ]
        
        // Transform corners to world space and convert to 2D points
        let points = corners.map { corner -> CGPoint in
            let cornerPoint = SIMD4<Float>(corner.x, corner.y, corner.z, 1)
            let worldPoint = transform.columns.0 * cornerPoint[0] +
                            transform.columns.1 * cornerPoint[1] +
                            transform.columns.2 * cornerPoint[2] +
                            transform.columns.3 * cornerPoint[3]
            return CGPoint(x: CGFloat(worldPoint.x), y: CGFloat(worldPoint.z))
        }
        
        // Calculate bounds for scaling
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 0
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 0
        
        // Calculate scale to fit view
        let margin: CGFloat = 40
        let scale = min(
            (bounds.width - margin * 2) / CGFloat(maxX - minX),
            (bounds.height - margin * 2) / CGFloat(maxY - minY)
        )
        
        // Draw floor outline
        for (index, point) in points.enumerated() {
            let scaledPoint = CGPoint(
                x: (point.x - minX) * scale + margin,
                y: (point.y - minY) * scale + margin
            )
            
            if index == 0 {
                path.move(to: scaledPoint)
            } else {
                path.addLine(to: scaledPoint)
            }
        }
        
        path.close()
        
        // Configure shape layer
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.fillColor = UIColor.clear.cgColor
        
        // Add measurements
        addMeasurements(width: width, length: length, scale: scale, margin: margin)
        
        // Add walls
        addWalls(scale: scale, margin: margin, minX: minX, minY: minY)
        
        layer.addSublayer(shapeLayer)
    }
    
    private func addWalls(scale: CGFloat, margin: CGFloat, minX: CGFloat, minY: CGFloat) {
        let wallLayer = CAShapeLayer()
        let wallPath = UIBezierPath()
        
        for wall in capturedRoom.walls {
            let transform = wall.transform
            let width = wall.dimensions.x
            
            // Calculate wall endpoints using matrix multiplication
            let startPoint4 = transform.columns.0 * (-width/2) +
                             transform.columns.1 * 0 +
                             transform.columns.2 * 0 +
                             transform.columns.3
            
            let endPoint4 = transform.columns.0 * (width/2) +
                           transform.columns.1 * 0 +
                           transform.columns.2 * 0 +
                           transform.columns.3
            
            // Convert to screen space
            let startPoint = CGPoint(
                x: (CGFloat(startPoint4.x) - minX) * scale + margin,
                y: (CGFloat(startPoint4.z) - minY) * scale + margin
            )
            let endPoint = CGPoint(
                x: (CGFloat(endPoint4.x) - minX) * scale + margin,
                y: (CGFloat(endPoint4.z) - minY) * scale + margin
            )
            
            // Draw wall with thickness
            let wallThickness: CGFloat = 8
            let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
            let perpendicular = angle + .pi/2
            
            let offset = CGPoint(
                x: wallThickness/2 * cos(perpendicular),
                y: wallThickness/2 * sin(perpendicular)
            )
            
            wallPath.move(to: CGPoint(x: startPoint.x + offset.x, y: startPoint.y + offset.y))
            wallPath.addLine(to: CGPoint(x: endPoint.x + offset.x, y: endPoint.y + offset.y))
            wallPath.addLine(to: CGPoint(x: endPoint.x - offset.x, y: endPoint.y - offset.y))
            wallPath.addLine(to: CGPoint(x: startPoint.x - offset.x, y: startPoint.y - offset.y))
            wallPath.close()
        }
        
        wallLayer.path = wallPath.cgPath
        wallLayer.fillColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        wallLayer.strokeColor = UIColor.black.cgColor
        layer.addSublayer(wallLayer)
    }
    
    private func addMeasurements(width: Float, length: Float, scale: CGFloat, margin: CGFloat) {
        // Add width measurement
        let widthLabel = createLabel(text: String(format: "%.2fm", width))
        widthLabel.frame = CGRect(
            x: margin,
            y: bounds.height - margin - 20,
            width: CGFloat(width) * scale,
            height: 20
        )
        addSubview(widthLabel)
        
        // Add length measurement
        let lengthLabel = createLabel(text: String(format: "%.2fm", length))
        lengthLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        lengthLabel.frame = CGRect(
            x: bounds.width - margin - 20,
            y: margin,
            width: CGFloat(length) * scale,
            height: 20
        )
        addSubview(lengthLabel)
        
        // Add area
        let area = width * length
        let areaLabel = createLabel(text: String(format: "Area: %.2f m²", area))
        areaLabel.frame = CGRect(
            x: margin,
            y: margin,
            width: 200,
            height: 20
        )
        addSubview(areaLabel)
    }
    
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12)
        return label
    }
}

