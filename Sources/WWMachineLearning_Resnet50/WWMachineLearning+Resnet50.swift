//
//  WWMachineLearning+Resnet50.swift
//  WWMachineLearning
//
//  Created by William.Weng on 2025/8/12.
//

import UIKit
import CoreML
import Vision
import WWNetworking

// MARK: - WWMachineLearning.Resnet50
extension WWMachineLearning {
    
    public class Resnet50 {
        
        public static let shared = Resnet50()
                
        public private(set) var model: MLModel?

        private init() {}
    }
}

// MARK: - 公開函式
public extension WWMachineLearning.Resnet50 {
    
    /// 載入模型 (從快取 or 網路重新下載)
    /// - Parameters:
    ///   - type: 模型類型
    ///   - folder: 儲存資料夾
    ///   - configuration: ML模型設定值
    ///   - progress: 下載進度
    ///   - completion: Result<URL, Error>
    func loadModel(type: ModelType = .int8lut, folder: URL? = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first, configuration: MLModelConfiguration = .init(), progress: ((WWNetworking.DownloadProgressInformation) -> Void)? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        
        let urlString = type.urlString()
        
        WWMachineLearning.shared.loadModel(urlString: urlString, folder: folder, configuration: configuration) { downloadProgress in
            progress?(downloadProgress)
        } completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let model, let url): self.model = model; completion(.success(url))
            }
        }
    }
    
    /// [分析圖片是什麼物體](https://developer.apple.com/machine-learning/models/)
    /// - Parameters:
    ///   - image: UIImage?
    ///   - result: (Result<ProbabilityInformation?, Error>) -> Void
    func probability(image: UIImage?, result: @escaping (Result<WWMachineLearning.ProbabilityInformation, Error>) -> Void) {
        
        prediction(with: image) { predictionResult in

            switch predictionResult {
            case .failure(let error): result(.failure(error))
            case .success(let observations):
                
                guard let firstObservation = observations.first else { return result(.failure(WWMachineLearning.CustomError.isEmpty)) }

                let info = WWMachineLearning.ProbabilityInformation(label: firstObservation.identifier, probability: Double(firstObservation.confidence))
                result(.success(info))
            }
        }
    }
        
    /// [分析圖片哪一些物體們的機率](https://medium.com/彼得潘的-swift-ios-app-開發教室/swiftui-使用-coreml-進行圖像辨識-ce02a92573f6)
    /// - Parameters:
    ///   - image: 圖片
    ///   - standardValue: 標準值
    ///   - result: (Result<[ProbabilityInformation], Error>) -> Void
    func probabilities(image: UIImage?, standardValue: Double = 0.1, result: @escaping (Result<[WWMachineLearning.ProbabilityInformation], Error>) -> Void) {
        
        prediction(with: image) { predictionResult in

            switch predictionResult {
            case .failure(let error): result(.failure(error))
            case .success(let observations):
                
                let infos = observations.compactMap { observation -> WWMachineLearning.ProbabilityInformation? in
                    guard Double(observation.confidence) >= standardValue else { return nil }
                    return WWMachineLearning.ProbabilityInformation(label: observation.identifier, probability: Double(observation.confidence))
                }
                
                result(.success(infos))
            }
        }
    }
    
    /// 載入模型 (從快取 or 網路重新下載)
    /// - Parameters:
    ///   - type: 模型類型
    ///   - folder: 儲存資料夾
    ///   - configuration: ML模型設定值
    /// - Returns: Result<URL, Error>
    func loadModel(type: ModelType = .int8lut, folder: URL? = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first, configuration: MLModelConfiguration = .init()) async -> Result<URL, Error> {
        
        await withCheckedContinuation { continuation in
            loadModel(type: type, folder: folder, configuration: configuration) { continuation.resume(returning: $0) }
        }
    }
    
    /// 分析圖片是什麼物體
    /// - Parameters:
    ///   - image: UIImage?
    /// - Returns: Result<ProbabilityInformation, Error>
    func probability(image: UIImage?) async -> Result<WWMachineLearning.ProbabilityInformation, Error> {
        
        await withCheckedContinuation { continuation in
            probability(image: image) { continuation.resume(returning: $0) }
        }
    }
    
    /// 分析圖片哪一些物體們的機率
    /// - Parameters:
    ///   - image: 圖片
    ///   - standardValue: 標準值
    /// - Returns: Result<[ProbabilityInformation], Error>
    func probabilities(image: UIImage?, standardValue: Double = 0.1) async -> Result<[WWMachineLearning.ProbabilityInformation], Error> {
        
        await withCheckedContinuation { continuation in
            probabilities(image: image, standardValue: standardValue) { continuation.resume(returning: $0) }
        }
    }
}

// MARK: - 小工具
private extension WWMachineLearning.Resnet50 {
        
    /// 執行預測
    /// - Parameters:
    ///   - image: UIImage?
    ///   - result: (Result<[VNClassificationObservation], Error>) -> Void
    func prediction(with image: UIImage?, result: @escaping (Result<[VNClassificationObservation], Error>) -> Void) {
        
        guard let image else { return result(.failure(WWMachineLearning.CustomError.isImageEmpty)) }
        guard let model = self.model else { return result(.failure(WWMachineLearning.CustomError.notModelLoaded)) }
        guard let pixelBuffer = image._resized(for: .init(width: 224, height: 224), scale: 1.0)._pixelBuffer() else { return result(.failure(WWMachineLearning.CustomError.notCreatePixelBuffer)) }
        
        do {
            let coreMLModel = try VNCoreMLModel(for: model)
                        
            let request = VNCoreMLRequest(model: coreMLModel) { (request, error) in
                
                if let error = error { return result(.failure(error)) }
                
                guard let results = request.results as? [VNClassificationObservation] else { return result(.failure(WWMachineLearning.CustomError.isEmpty)) }
                result(.success(results))
            }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try handler.perform([request])
            
        } catch {
            result(.failure(error))
        }
    }
}
