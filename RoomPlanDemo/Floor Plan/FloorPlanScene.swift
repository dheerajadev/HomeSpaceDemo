//
//  FloorPlanScene.swift
//  RoomPlanDemo
//
//  Created by Appscrip 3Embed on 06/02/25.
//

import RoomPlan
import SpriteKit

class FloorPlanScene: SKScene {
    
    // MARK: - Properties
    
    // Surfaces and objects from our scan result
    private let surfaces: [CapturedRoom.Surface]
    private let objects: [CapturedRoom.Object]
    
    // Variables that store camera scale and position at the start of a gesture
    private var previousCameraScale = CGFloat()
    private var previousCameraPosition = CGPoint()
    
    // MARK: - MAIN
    
    init(capturedRoom: CapturedRoom) {
        self.surfaces = capturedRoom.doors + capturedRoom.openings + capturedRoom.walls + capturedRoom.windows
        self.objects = capturedRoom.objects
        
        super.init(size: CGSize(width: 500, height: 500))
        
        self.scaleMode = .aspectFit
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.backgroundColor = floorPlanBackgroundColor
        
        addCamera()
        
        drawSurfaces()
        drawObjects()
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.addTarget(self, action: #selector(panGestureAction(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer()
        pinchGestureRecognizer.addTarget(self, action: #selector(pinchGestureAction(_:)))
        view.addGestureRecognizer(pinchGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - FUNCTIONS
    
    private func drawSurfaces() {
        for surface in surfaces {
            let surfaceNode = FloorPlanSurface(capturedSurface: surface)
            addChild(surfaceNode)
        }
    }
    
    private func drawObjects() {
        for object in objects {
            let objectNode = FloorPlanObject(capturedObject: object)
            addChild(objectNode)
        }
    }
    
    private func addCamera() {
        let cameraNode = SKCameraNode()
        addChild(cameraNode)
        self.camera = cameraNode
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
    }
    
    // MARK: - ACTIONS
    
    // Pan gestures only handle camera movement in this scene
    @objc private func panGestureAction(_ sender: UIPanGestureRecognizer) {
        guard let camera = self.camera else { return }
        
        if sender.state == .began {
            previousCameraPosition = camera.position
        }
        
        let translationScale = camera.xScale
        let panTranslation = sender.translation(in: self.view)
        let newCameraPosition = CGPoint(
            x: previousCameraPosition.x + panTranslation.x * -translationScale,
            y: previousCameraPosition.y + panTranslation.y * translationScale
        )
        
        camera.position = newCameraPosition
    }
    
    // Pinch gestures only handle camera movement in this scene
    @objc private func pinchGestureAction(_ sender: UIPinchGestureRecognizer) {
        guard let camera = self.camera else { return }
        
        if sender.state == .began {
            previousCameraScale = camera.xScale
        }
        
        camera.setScale(previousCameraScale * 1 / sender.scale)
    }
    
}
