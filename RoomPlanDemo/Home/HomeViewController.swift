//
//  HomeViewController.swift
//  RoomPlanDemo
//
//  Created by Appscrip 3Embed on 06/02/25.
//

import UIKit
import SceneKit
import ModelIO

// MARK: - HomeViewController
class HomeViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(ModelListTableViewCell.self, forCellReuseIdentifier: "ModelListTableViewCell")
        return table
    }()
    
    var savedModels: [SavedModel] = []
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupTableView()
        loadSavedModels()
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 100 // Cell height + padding
    }
    
    // MARK: - Data Loading
    private func loadSavedModels() {
        loadingIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let models = [
                SavedModel(
                    name: "Main room",
                    size: "20' x 15'",
                    modelScene: self.loadUSDZScene(named: "model1.usdz"),
                    fileName: "model1.usdz"
                ),
                SavedModel(
                    name: "HR room", size: "15' x 12'",
                    modelScene: self.loadUSDZScene(named: "model2.usdz"),
                    fileName: "model2.usdz"
                ),
                SavedModel(
                    name: "Reception room",
                    size: "12' x 10'",
                    modelScene: self.loadUSDZScene(named: "model3.usdz"),
                    fileName: "model3.usdz"
                )
            ]
            
            DispatchQueue.main.async {
                self.savedModels = models
                self.tableView.reloadData()
                self.loadingIndicator.stopAnimating()
                self.loadingIndicator.removeFromSuperview()
            }
        }
    }
    
    private func loadUSDZScene(named filename: String) -> SCNScene? {
        guard let url = Bundle.main.url(forResource: filename.components(separatedBy: ".").first,
                                        withExtension: "usdz") else {
            print("Failed to find USDZ file: \(filename)")
            return nil
        }

        do {
            let scene = try SCNScene(url: url, options: nil)
            scene.background.contents = UIColor.white
            return scene
        } catch {
            print("Failed to load USDZ file: \(error.localizedDescription)")
            return nil
        }
    }

}

// MARK: - Model
struct SavedModel {
    let name: String
    let size: String
    let modelScene: SCNScene?
    let fileName: String?
}
