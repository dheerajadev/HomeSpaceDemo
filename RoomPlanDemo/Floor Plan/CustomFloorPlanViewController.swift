//
//  CustomFloorPlanViewController.swift
//  RoomPlanDemo
//
//  Created by Appscrip 3Embed on 06/02/25.
//

import UIKit
import SpriteKit
import RoomPlan

class CustomFloorPlanViewController: UIViewController {
    var capturedRoom: CapturedRoom

    init(capturedRoom: CapturedRoom) {
        self.capturedRoom = capturedRoom
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
    }

    private func setupScene() {
        let skView = SKView(frame: view.bounds)
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)

        let scene = FloorPlanScene(capturedRoom: capturedRoom)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }
}
