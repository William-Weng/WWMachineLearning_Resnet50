//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2025/8/12.
//

import UIKit
import WWMachineLearning_Resnet50

// MARK: - ViewController
final class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            _ = await WWMachineLearning.Resnet50.shard.loadModel()
        }
    }
    
    @IBAction func probabilityTest(_ sender: UIButton) {
        
        let image = sender.backgroundImage(for: .normal)
        
        Task {
            switch await WWMachineLearning.Resnet50.shard.probability(image: image) {
            case .failure(let error): sender.setTitle(error.localizedDescription, for: .normal)
            case .success(let info):
                sender.setTitle(info.label, for: .normal)
                title = "\(info.probability * 100.0) %"
            }
        }
    }
}
