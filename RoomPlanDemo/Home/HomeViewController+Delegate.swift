//
//  HomeViewController+Delegate.swift
//  RoomPlanDemo
//
//  Created by Appscrip 3Embed on 06/02/25.
//

import UIKit
import RoomPlan

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ModelListTableViewCell", for: indexPath) as? ModelListTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: savedModels[indexPath.row])
        cell.selectionStyle = .none
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let model = savedModels[indexPath.row]
        
        let fileURL = RoomModelManager.shared.modelsDirectory.appendingPathComponent(model.fileName)
                print("USDZ file URL: \(fileURL)")
        
        print("Captured Structure --> \(model.roomData)")
        let capturedStructure = model.roomData
        let capturedRoom = capturedStructure.rooms.first
                
        Task {
            do {
                DispatchQueue.main.async { [weak self] in
                    let viewController = LoadScannedRoomViewController(model: capturedRoom, url: fileURL)
                    self?.navigationController?.pushViewController(viewController, animated: true)
                }
            } catch {
                print("Processing error: \(error.localizedDescription)")
                DispatchQueue.main.async { [weak self] in
                    self?.showAlert(message: "Failed to reconstructed room: \(error.localizedDescription)")
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
    
}
