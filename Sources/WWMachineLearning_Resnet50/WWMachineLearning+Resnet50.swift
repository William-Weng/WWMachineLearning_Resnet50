//
//  WWMachineLearning+Resnet50.swift
//  WWMachineLearning
//
//  Created by William.Weng on 2025/4/18.
//

import UIKit
import CoreML

// MARK: - WWMachineLearning.Resnet50
extension WWMachineLearning {
    
    public class Resnet50 {
        static public let shard = Resnet50()
    }
}

// MARK: - 公開函式
public extension WWMachineLearning.Resnet50 {
    
    /// [分析圖片是什麼物體](https://developer.apple.com/machine-learning/models/)
    /// - Parameter image: UIImage?
    /// - Returns: ProbabilityInformation?
    func probability(image: UIImage?) -> ProbabilityInformation? {
        
        guard let prediction = prediction(with: image) else { return nil }
        
        let label = prediction.classLabel
        let probability = prediction.classLabelProbs[label]
        
        return ProbabilityInformation(label: label, probability: probability ?? 0)
    }
    
    /// [分析圖片哪一些物體們的機率](https://medium.com/彼得潘的-swift-ios-app-開發教室/swiftui-使用-coreml-進行圖像辨識-ce02a92573f6)
    /// - Parameters:
    ///   - image: UIImage?
    ///   - standardValue: Double
    /// - Returns: [ProbabilityInformation]
    func probabilities(image: UIImage?, standardValue: Double = 0.1) -> [ProbabilityInformation] {
        
        guard let prediction = prediction(with: image) else { return [] }

        var probabilities: [ProbabilityInformation] = []
        
        for (label, probability) in prediction.classLabelProbs {
            if (probability < standardValue) { continue }
            probabilities.append(ProbabilityInformation(label: label, probability: probability))
        }
        
        return probabilities.sorted { $0.probability > $1.probability }
    }
}

// MARK: - 小工具
private extension WWMachineLearning.Resnet50 {
    
    /// [使用APPLE的Resnet50模型分析](https://developer.apple.com/machine-learning/)
    /// - Parameter image: UIImage?
    /// - Returns: Resnet50Int8LUTOutput?
    func prediction(with image: UIImage?) -> Resnet50Int8LUTOutput? {
        
        guard let model = try? Resnet50Int8LUT(configuration: MLModelConfiguration()),
              let pixelBuffer = image?._resized(for: .init(width: 224, height: 224), scale: 1.0)._pixelBuffer(),
              let prediction = try? model.prediction(image: pixelBuffer)
        else {
            return nil
        }
        
        return prediction
    }
}
