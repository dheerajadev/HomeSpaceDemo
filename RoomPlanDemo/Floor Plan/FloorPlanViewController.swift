//
//  FloorPlanViewController.swift
//  RoomPlanDemo
//
//  Created by Appscrip 3Embed on 06/02/25.
//

import UIKit
import SpriteKit
import RoomPlan

class FloorPlanViewController: UIViewController {
    
    // MARK: - PROPERTIES
    
    var capturedRoom: CapturedRoom
    private var skView: SKView!
    
    let legendView: FloorPlanLegend = {
        let view = FloorPlanLegend()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - MAIN

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
        setupLegend()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        skView.frame = view.bounds
    }

    // MARK: - FUNCTIONS
    
    private func setupScene() {
        skView = SKView(frame: view.bounds)
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)

        let scene = FloorPlanScene(capturedRoom: capturedRoom)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
    }
    
    private func setupLegend() {
        view.addSubview(legendView)
        NSLayoutConstraint.activate([
            legendView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            legendView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }
    
}
