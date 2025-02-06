//
//  HomeViewController+Delegate.swift
//  RoomPlanDemo
//
//  Created by Appscrip 3Embed on 06/02/25.
//

import UIKit

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
        
        guard let fileName = savedModels[indexPath.row].fileName else { return }
        guard let url = Bundle.main.url(forResource: fileName.components(separatedBy: ".").first,
                                        withExtension: "usdz") else {
            print("Failed to find USDZ file: \(fileName)")
            return
        }
        
        let viewController = LoadScannedRoomViewController(model: nil, url: url)
        self.navigationController?.pushViewController(viewController, animated: true)
        
    }
    
}
