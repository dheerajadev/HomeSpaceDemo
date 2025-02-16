//
//  FloorPlanSurface.swift
//  RoomPlan 2D
//
//  Created by Dennis van Oosten on 12/03/2023.
//

import SpriteKit
import RoomPlan

class FloorPlanSurface: SKNode {
    
    private let capturedSurface: CapturedRoom.Surface
    
    // MARK: - Computed properties
    
    private var halfLength: CGFloat {
        return CGFloat(capturedSurface.dimensions.x) * scalingFactor / 2
    }
    
    private var pointA: CGPoint {
        return CGPoint(x: -halfLength, y: 0)
    }
    
    private var pointB: CGPoint {
        return CGPoint(x: halfLength, y: 0)
    }
    
    private var pointC: CGPoint {
        return pointB.rotateAround(point: pointA, by: 0.25 * .pi)
    }
    
    // MARK: - Init
    
    init(capturedSurface: CapturedRoom.Surface) {
        self.capturedSurface = capturedSurface
        
        super.init()
        
        // Set the surface's position using the transform matrix
        let surfacePositionX = -CGFloat(capturedSurface.transform.position.x) * scalingFactor
        let surfacePositionY = CGFloat(capturedSurface.transform.position.z) * scalingFactor
        self.position = CGPoint(x: surfacePositionX, y: surfacePositionY)
        
        // Set the surface's zRotation using the transform matrix
        self.zRotation = -CGFloat(capturedSurface.transform.eulerAngles.z - capturedSurface.transform.eulerAngles.y)
        
        // Draw the right surface
        switch capturedSurface.category {
        case .door:
            drawDoor()
        case .opening:
            drawOpening()
        case .wall:
            drawWall()
        case .window:
            drawWindow()
        @unknown default:
            drawWall()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Draw

    private func drawDoor() {
        let hideWallPath = createPath(from: pointA, to: pointB)
        let doorPath = createPath(from: pointA, to: pointC)

        // Hide the wall underneath the door
        let hideWallShape = createShapeNode(from: hideWallPath)
        hideWallShape.strokeColor = floorPlanBackgroundColor
        hideWallShape.lineWidth = hideSurfaceWith
        hideWallShape.zPosition = hideSurfaceZPosition
        
        // The door itself
        let doorShape = createShapeNode(from: doorPath)
        doorShape.strokeColor = doorColor
        doorShape.lineCap = .round
        doorShape.zPosition = doorZPosition
        
        // The door's arc
        let doorArcPath = CGMutablePath()
        doorArcPath.addArc(
            center: pointA,
            radius: halfLength * 2,
            startAngle: 0.25 * .pi,
            endAngle: 0,
            clockwise: true
        )
        
        let dashPattern: [CGFloat] = [24.0, 8.0]
        let dashedArcPath = doorArcPath.copy(dashingWithPhase: 1, lengths: dashPattern)

        let doorArcShape = createShapeNode(from: dashedArcPath)
        doorArcShape.strokeColor = doorColor
        doorArcShape.lineWidth = doorArcWidth
        doorArcShape.zPosition = doorArcZPosition
        
        addChild(hideWallShape)
        addChild(doorShape)
        addChild(doorArcShape)
        
        // Add dimension
        let offset: CGFloat = 20
        let dimensionStartPoint = CGPoint(x: pointA.x, y: pointA.y - offset)
        let dimensionEndPoint = CGPoint(x: pointB.x, y: pointB.y - offset)
        drawDimension(from: dimensionStartPoint, to: dimensionEndPoint)
    }
    
    private func drawOpening() {
        let openingPath = createPath(from: pointA, to: pointB)
        
        // Hide the wall underneath the opening
        let hideWallShape = createShapeNode(from: openingPath)
        hideWallShape.strokeColor = floorPlanBackgroundColor
        hideWallShape.lineWidth = hideSurfaceWith
        hideWallShape.zPosition = hideSurfaceZPosition
        
        // Add visible opening line
        let openingShape = createShapeNode(from: openingPath)
        openingShape.strokeColor = openingColor
        openingShape.lineWidth = surfaceWith
        openingShape.zPosition = windowZPosition
        
        addChild(hideWallShape)
        addChild(openingShape)
    }
    
    private func drawWall() {
        let wallPath = createPath(from: pointA, to: pointB)
        let wallShape = createShapeNode(from: wallPath)
        wallShape.lineCap = .round

        addChild(wallShape)
        
        // Add dimension
        let offset: CGFloat = 20
        let dimensionStartPoint = CGPoint(x: pointA.x, y: pointA.y - offset)
        let dimensionEndPoint = CGPoint(x: pointB.x, y: pointB.y - offset)
        drawDimension(from: dimensionStartPoint, to: dimensionEndPoint)
    }
    
    private func drawWindow() {
        let windowPath = createPath(from: pointA, to: pointB)
        
        // Hide the wall underneath the window
        let hideWallShape = createShapeNode(from: windowPath)
        hideWallShape.strokeColor = floorPlanBackgroundColor
        hideWallShape.lineWidth = hideSurfaceWith
        hideWallShape.zPosition = hideSurfaceZPosition
        
        // The window itself
        let windowShape = createShapeNode(from: windowPath)
        windowShape.strokeColor = windowColor
        windowShape.lineWidth = windowWidth
        windowShape.zPosition = windowZPosition
        
        addChild(hideWallShape)
        addChild(windowShape)
        
        // Add dimension
        let offset: CGFloat = 20
        let dimensionStartPoint = CGPoint(x: pointA.x, y: pointA.y - offset)
        let dimensionEndPoint = CGPoint(x: pointB.x, y: pointB.y - offset)
        drawDimension(from: dimensionStartPoint, to: dimensionEndPoint)
    }
    
    // MARK: - Helper functions
    
    private func createPath(from pointA: CGPoint, to pointB: CGPoint) -> CGMutablePath {
        let path = CGMutablePath()
        path.move(to: pointA)
        path.addLine(to: pointB)
        
        return path
    }
    
    private func createShapeNode(from path: CGPath) -> SKShapeNode {
        let shapeNode = SKShapeNode(path: path)
        shapeNode.strokeColor = floorPlanSurfaceColor
        shapeNode.lineWidth = surfaceWith
        
        return shapeNode
    }
    
    private func addDimensionLabel(at point: CGPoint, text: String, rotation: CGFloat = 0) {
        let label = SKLabelNode(text: text)
        label.fontSize = dimensionFontSize
        label.fontColor = dimensionTextColor
        label.fontName = "Helvetica-Bold"
        
        // Keep text horizontal (aligned to user's view)
        label.zRotation = 0
        
        // Determine if the line is more vertical or horizontal
        let isMoreVertical = abs(sin(rotation)) > abs(cos(rotation))
        
        // Position the label based on line orientation
        if isMoreVertical {
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(
                x: point.x + dimensionOffset/2,
                y: point.y
            )
        } else {
            label.verticalAlignmentMode = .bottom
            label.position = CGPoint(
                x: point.x,
                y: point.y - dimensionOffset/2
            )
        }
        
        // Make background slightly larger
        let padding = CGSize(width: 16, height: 8)
        let background = SKShapeNode(rectOf: CGSize(
            width: label.frame.width + padding.width,
            height: label.frame.height + padding.height
        ))
        background.fillColor = floorPlanBackgroundColor
        background.strokeColor = .clear
        background.position = label.position
        background.zPosition = dimensionZPosition
        
        label.zPosition = dimensionZPosition + 1
        
        addChild(background)
        addChild(label)
    }
    
    private func drawDimension(from startPoint: CGPoint, to endPoint: CGPoint) {
        // Calculate length
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let lengthInMeters = sqrt(dx * dx + dy * dy) / scalingFactor
        
        // Format dimension text in meters
        let dimensionText: String
        if lengthInMeters >= 1 {
            dimensionText = String(format: "%.2fm", lengthInMeters)
        } else {
            let lengthInCm = lengthInMeters * 100
            dimensionText = String(format: "%.0fcm", lengthInCm)
        }
        
        let angle = atan2(dy, dx)
        let isMoreVertical = abs(sin(angle)) > abs(cos(angle))
        
        // Adjust dimension line position based on orientation
        let adjustedStartPoint: CGPoint
        let adjustedEndPoint: CGPoint
        
        if isMoreVertical {
            // For vertical lines, offset to the right
            adjustedStartPoint = CGPoint(
                x: startPoint.x + dimensionOffset,
                y: startPoint.y
            )
            adjustedEndPoint = CGPoint(
                x: endPoint.x + dimensionOffset,
                y: endPoint.y
            )
        } else {
            // For horizontal lines, offset downward
            adjustedStartPoint = CGPoint(
                x: startPoint.x,
                y: startPoint.y - dimensionOffset
            )
            adjustedEndPoint = CGPoint(
                x: endPoint.x,
                y: endPoint.y - dimensionOffset
            )
        }
        
        // Draw dimension line
        let dimensionPath = CGMutablePath()
        dimensionPath.move(to: adjustedStartPoint)
        dimensionPath.addLine(to: adjustedEndPoint)
        
        let dimensionLine = SKShapeNode(path: dimensionPath)
        dimensionLine.strokeColor = dimensionTextColor
        dimensionLine.lineWidth = dimensionLineWidth
        dimensionLine.zPosition = dimensionZPosition
        addChild(dimensionLine)
        
        // Add perpendicular end caps
        let perpLength = dimensionCapLength
        let capAngle = isMoreVertical ? 0 : CGFloat.pi/2
        
        // Start cap
        let startCapPath = CGMutablePath()
        startCapPath.move(to: CGPoint(
            x: adjustedStartPoint.x + perpLength * cos(capAngle + CGFloat.pi/2),
            y: adjustedStartPoint.y + perpLength * sin(capAngle + CGFloat.pi/2)
        ))
        startCapPath.addLine(to: CGPoint(
            x: adjustedStartPoint.x + perpLength * cos(capAngle - CGFloat.pi/2),
            y: adjustedStartPoint.y + perpLength * sin(capAngle - CGFloat.pi/2)
        ))
        
        // End cap
        let endCapPath = CGMutablePath()
        endCapPath.move(to: CGPoint(
            x: adjustedEndPoint.x + perpLength * cos(capAngle + CGFloat.pi/2),
            y: adjustedEndPoint.y + perpLength * sin(capAngle + CGFloat.pi/2)
        ))
        endCapPath.addLine(to: CGPoint(
            x: adjustedEndPoint.x + perpLength * cos(capAngle - CGFloat.pi/2),
            y: adjustedEndPoint.y + perpLength * sin(capAngle - CGFloat.pi/2)
        ))
        
        let startCap = SKShapeNode(path: startCapPath)
        let endCap = SKShapeNode(path: endCapPath)
        startCap.strokeColor = dimensionTextColor
        endCap.strokeColor = dimensionTextColor
        startCap.lineWidth = dimensionLineWidth
        endCap.lineWidth = dimensionLineWidth
        startCap.zPosition = dimensionZPosition
        endCap.zPosition = dimensionZPosition
        
        addChild(startCap)
        addChild(endCap)
        
        // Calculate midpoint for label
        let midPoint = CGPoint(
            x: (adjustedStartPoint.x + adjustedEndPoint.x) / 2,
            y: (adjustedStartPoint.y + adjustedEndPoint.y) / 2
        )
        
        // Add dimension label
        addDimensionLabel(at: midPoint, text: dimensionText, rotation: angle)
    }
    
}
