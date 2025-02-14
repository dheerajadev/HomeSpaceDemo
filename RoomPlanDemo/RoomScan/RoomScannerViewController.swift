//
//  RoomScannerViewController.swift
//  RoomPlanDemo
//
//  Created by Appscrip 3Embed on 31/01/25.
//

import UIKit
import RoomPlan
import ARKit
import RealityKit

class RoomScannerViewController: UIViewController {
    
    // MARK: - PROPERTIES
    
    var roomCaptureView: RoomCaptureView!
    var isScanning = false
    
    // Replace scannedRooms array with single property
    private var lastScannedRoom: (model: CapturedRoom, url: URL)?
    
    lazy var placeholderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    lazy var placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "camera.viewfinder")
        imageView.tintColor = .white
        return imageView
    }()
    
    lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tap 'Start Scan' to begin room scanning"
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    lazy var startScanButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .green
        button.addTarget(self, action: #selector(toggleScanning), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        button.setTitle("Start Scan", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 25
        return button
    }()
    
    // Add debug label to show loading status
    private lazy var debugLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.textAlignment = .center
        label.backgroundColor = .white.withAlphaComponent(0.7)
        label.isHidden = true
        return label
    }()
    
    // Add to class properties
    private let documentPicker: UIDocumentPickerViewController = {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.usdz])
        picker.allowsMultipleSelection = false
        return picker
    }()
    
    // MARK: MAIN -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        checkDeviceCompatibility()
        documentPicker.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isScanning {
            roomCaptureView.captureSession.stop()
            isScanning = false
        }
    }
    
    // MARK: FUNCTIONS -
    
    func updateUIState(isPlaceholderVisible: Bool, isScanningEnabled: Bool, isCurrentlyScanning: Bool? = nil) {
        
        if let roomCaptureView {
            self.roomCaptureView.isHidden = isPlaceholderVisible
        }
        placeholderView.isHidden = !isPlaceholderVisible
        startScanButton.isEnabled = isScanningEnabled
        
        let scanning = isCurrentlyScanning ?? isScanning
        
        if scanning {
            startScanButton.setTitle("Stop Scan", for: .normal)
            startScanButton.backgroundColor = .red
        } else {
            startScanButton.setTitle("Start Scan", for: .normal)
            startScanButton.backgroundColor = .green
        }
    }
    
    func checkDeviceCompatibility() {
        // Check RoomPlan support
        guard RoomCaptureSession.isSupported else {
            showAlert(message: "This device doesn't support RoomPlan")
            updateUIState(isPlaceholderVisible: false, isScanningEnabled: false)
            return
        }
        
        setupViews()
        setupConstraints()
        
        // Check camera authorization status
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            updateUIState(isPlaceholderVisible: true, isScanningEnabled: true)
        case .notDetermined:
            updateUIState(isPlaceholderVisible: true, isScanningEnabled: false)
            requestCameraPermission()
        case .denied, .restricted:
            updateUIState(isPlaceholderVisible: false, isScanningEnabled: false)
            showAlert(message: "Camera access is required for room scanning. Please enable it in Settings.")
        @unknown default:
            break
        }
        
    }
    
    func setupViews() {
        view.backgroundColor = .black
        
        // Initialize RoomCaptureView
        roomCaptureView = RoomCaptureView(frame: .zero)
        roomCaptureView.translatesAutoresizingMaskIntoConstraints = false
        roomCaptureView.captureSession.delegate = self
        roomCaptureView.isHidden = true
        view.addSubview(roomCaptureView)
        
        view.addSubview(placeholderView)
        placeholderView.addSubview(placeholderImageView)
        placeholderView.addSubview(placeholderLabel)
        
        view.addSubview(startScanButton)
        view.addSubview(debugLabel)
        
        NSLayoutConstraint.activate([
            // RoomCaptureView constraints
            roomCaptureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            roomCaptureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            roomCaptureView.topAnchor.constraint(equalTo: view.topAnchor),
            roomCaptureView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Placeholder view constraints
            placeholderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            placeholderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            placeholderView.topAnchor.constraint(equalTo: view.topAnchor),
            placeholderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Placeholder image constraints
            placeholderImageView.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor),
            placeholderImageView.centerYAnchor.constraint(equalTo: placeholderView.centerYAnchor, constant: -50),
            placeholderImageView.widthAnchor.constraint(equalToConstant: 100),
            placeholderImageView.heightAnchor.constraint(equalToConstant: 100),
            
            // Placeholder label constraints
            placeholderLabel.topAnchor.constraint(equalTo: placeholderImageView.bottomAnchor, constant: 20),
            placeholderLabel.leadingAnchor.constraint(equalTo: placeholderView.leadingAnchor, constant: 20),
            placeholderLabel.trailingAnchor.constraint(equalTo: placeholderView.trailingAnchor, constant: -20),
            
            // Button constraints
            startScanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startScanButton.heightAnchor.constraint(equalToConstant: 50),
            startScanButton.widthAnchor.constraint(equalToConstant: 150),
            startScanButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            debugLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            debugLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            debugLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            // RoomCaptureView constraints
            roomCaptureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            roomCaptureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            roomCaptureView.topAnchor.constraint(equalTo: view.topAnchor),
            roomCaptureView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Placeholder view constraints
            placeholderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            placeholderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            placeholderView.topAnchor.constraint(equalTo: view.topAnchor),
            placeholderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Placeholder image constraints
            placeholderImageView.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor),
            placeholderImageView.centerYAnchor.constraint(equalTo: placeholderView.centerYAnchor, constant: -50),
            placeholderImageView.widthAnchor.constraint(equalToConstant: 100),
            placeholderImageView.heightAnchor.constraint(equalToConstant: 100),
            
            // Placeholder label constraints
            placeholderLabel.topAnchor.constraint(equalTo: placeholderImageView.bottomAnchor, constant: 20),
            placeholderLabel.leadingAnchor.constraint(equalTo: placeholderView.leadingAnchor, constant: 20),
            placeholderLabel.trailingAnchor.constraint(equalTo: placeholderView.trailingAnchor, constant: -20),
            
            // Button constraints
            startScanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startScanButton.heightAnchor.constraint(equalToConstant: 50),
            startScanButton.widthAnchor.constraint(equalToConstant: 150),
            startScanButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    @objc func toggleScanning() {
        isScanning.toggle()
        
        if isScanning {
            var configuration = RoomCaptureSession.Configuration()
            configuration.isCoachingEnabled = true
            roomCaptureView.captureSession.run(configuration: configuration)
            updateUIState(isPlaceholderVisible: false, isScanningEnabled: true, isCurrentlyScanning: true)
        } else {
            roomCaptureView.captureSession.stop()
            // Don't transition to AR view anymore
            updateUIState(isPlaceholderVisible: true, isScanningEnabled: true, isCurrentlyScanning: false)
        }
    }
    
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.updateUIState(isPlaceholderVisible: true, isScanningEnabled: true)
                } else {
                    self?.updateUIState(isPlaceholderVisible: false, isScanningEnabled: false)
                    self?.showAlert(message: "Camera access is required for room scanning. Please enable it in Settings.")
                }
            }
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Alert",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupNavigationBar() {
        // Set title
        title = "Room Scanner"
        
        // Configure back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        // Move import button to right side
        let importButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(importButtonTapped)
        )
        importButton.tintColor = .white
        navigationItem.rightBarButtonItem = importButton
    }
    
    @objc private func backButtonTapped() {
        // If scanning is in progress, show confirmation alert
        if isScanning {
            let alert = UIAlertController(
                title: "Stop Scanning?",
                message: "Going back will stop the current scan. Are you sure?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Stop & Go Back", style: .destructive) { [weak self] _ in
                self?.roomCaptureView.captureSession.stop()
                self?.navigationController?.popViewController(animated: true)
            })
            
            present(alert, animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    // Add import button action
    @objc private func importButtonTapped() {
        present(documentPicker, animated: true)
    }
}

// Add RoomCaptureSession Delegate
extension RoomScannerViewController: RoomCaptureSessionDelegate {
    
    func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        // This gets called with live updates during scanning
        print("\n--- Room Update ---")
        print("Walls: \(room.walls.count)")
        print("Doors: \(room.doors.count)")
        print("Windows: \(room.windows.count)")
        print("Openings: \(room.openings.count)")
        
        // Print furniture
        let furniture = room.objects.reduce(into: [:]) { counts, object in
            counts[object.category, default: 0] += 1
        }
        print("\nDetected Furniture:")
        furniture.forEach { category, count in
            print("\(category): \(count)")
        }
    }
    
    func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {
        print("\nRoom added to session")
    }
    
    func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
        print("Instructions: \(instruction)")
    }
    
    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
        guard error == nil else {
            print("Error during scanning: \(error!.localizedDescription)")
            return
        }
        
        Task {
            do {
                let finalRoom = try await RoomBuilder(options: [.beautifyObjects])
                    .capturedRoom(from: data)
                
                // Save the captured room
                try RoomModelManager.shared.saveRoom(
                    finalRoom,
                    data,
                    name: "Room \(Date().formatted(date: .abbreviated, time: .shortened))"
                )
                
                
                DispatchQueue.main.async { [weak self] in
                    self?.debugLabel.isHidden = false
                    self?.debugLabel.text = "Room scan completed and saved"
                    
                    // Navigate to home screen to see saved models
                    self?.navigationController?.popToRootViewController(animated: true)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.debugLabel.isHidden = true
                    }
                }
                
            } catch {
                print("Processing error: \(error.localizedDescription)")
                DispatchQueue.main.async { [weak self] in
                    self?.showAlert(message: "Failed to process final room: \(error.localizedDescription)")
                }
            }
        }
    }
}

// Add document picker delegate extension
extension RoomScannerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        
        // Create security-scoped resource access
        let shouldStopAccessing = selectedURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                selectedURL.stopAccessingSecurityScopedResource()
            }
        }
        
        // Create and present LoadScannedRoomViewController
        let viewController = LoadScannedRoomViewController(model: nil, url: selectedURL)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
