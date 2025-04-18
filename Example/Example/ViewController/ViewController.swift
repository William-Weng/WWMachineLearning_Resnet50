//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2025/4/18.
//

import UIKit
import WWMachineLearning_Resnet50

// MARK: - ViewController
final class ViewController: UIViewController {
    
    @IBAction func probabilityTest(_ sender: UIButton) {
        
        guard let info = WWMachineLearning.Resnet50.shard.probability(image: sender.backgroundImage(for: .normal)) else { return }
        
        sender.setTitle(info.label, for: .normal)
        title = "\(info.probability * 100.0) %"
    }
}
