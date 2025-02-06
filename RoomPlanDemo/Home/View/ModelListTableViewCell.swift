//
//  ModelListTableViewCell.swift
//  RoomPlanDemo
//
//  Created by Appscrip 3Embed on 06/02/25.
//

import UIKit
import SceneKit

class ModelListTableViewCell: UITableViewCell {

    // MARK: - UI Elements
    private let modelView: SCNView = {
        let view = SCNView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = true
        return view
    }()
    
    private let modelNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let modelSizeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        contentView.addSubview(modelView)
        contentView.addSubview(modelNameLabel)
        contentView.addSubview(modelSizeLabel)
        
        NSLayoutConstraint.activate([
            modelView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            modelView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            modelView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            modelView.widthAnchor.constraint(equalTo: modelView.heightAnchor),
            modelView.heightAnchor.constraint(equalToConstant: 80),
            
            modelNameLabel.leadingAnchor.constraint(equalTo: modelView.trailingAnchor, constant: 16),
            modelNameLabel.topAnchor.constraint(equalTo: modelView.topAnchor),
            modelNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            modelSizeLabel.leadingAnchor.constraint(equalTo: modelNameLabel.leadingAnchor),
            modelSizeLabel.topAnchor.constraint(equalTo: modelNameLabel.bottomAnchor, constant: 8),
            modelSizeLabel.trailingAnchor.constraint(equalTo: modelNameLabel.trailingAnchor)
        ])
        
        // Configure SCNView default settings
        modelView.backgroundColor = .systemGray6
        modelView.autoenablesDefaultLighting = true
        modelView.allowsCameraControl = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Stop any running actions before clearing the scene
        modelView.scene = nil
    }
    
    // MARK: - Configuration
    func configure(with model: SavedModel) {
        modelNameLabel.text = model.name
        modelSizeLabel.text = model.size
        modelView.scene = model.modelScene
    }

}
