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
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let emptyStateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "cube.transparent")
        imageView.tintColor = .gray
        return imageView
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No rooms scanned yet\nTap + to scan a new room"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .gray
        return label
    }()
    
    var savedModels: [SavedModel] = []
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        setupTableView()
        loadSavedModels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload data when returning to this screen
        loadSavedModels()
    }
    
    // MARK: - Setup Methods
    private func setupNavigationBar() {
        title = "Saved Rooms"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped)
        )
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // Add views
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        view.addSubview(emptyStateView)
        
        // Add empty state subviews
        emptyStateView.addSubview(emptyStateImageView)
        emptyStateView.addSubview(emptyStateLabel)
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Empty state view constraints
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 20),
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 100 // Cell height + padding
    }
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        let scannerVC = RoomScannerViewController()
        navigationController?.pushViewController(scannerVC, animated: true)
    }
    
    // MARK: - Data Loading
    private func loadSavedModels() {
        loadingIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let models = try RoomModelManager.shared.loadSavedModels()
                
                DispatchQueue.main.async {
                    self?.savedModels = models
                    self?.tableView.reloadData()
                    self?.loadingIndicator.stopAnimating()
                    self?.loadingIndicator.removeFromSuperview()
                    
                    // Show/hide empty state
                    self?.emptyStateView.isHidden = !models.isEmpty
                    self?.tableView.isHidden = models.isEmpty
                }
            } catch {
                DispatchQueue.main.async {
                    self?.showAlert(message: "Failed to load saved models: \(error.localizedDescription)")
                    self?.loadingIndicator.stopAnimating()
                    self?.loadingIndicator.removeFromSuperview()
                }
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
