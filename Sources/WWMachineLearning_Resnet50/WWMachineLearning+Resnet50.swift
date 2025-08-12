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
        
        public static let shard = Resnet50()
                
        private var type: ModelType = .int8lut
        private var model: MLModel?
        private var modelUrl: URL?

        private init() {}
    }
}

// MARK: - 公開函式
public extension WWMachineLearning.Resnet50 {
    
    /// 載入模型 (從快取 or 網路重新下載)
    /// - Parameters:
    ///   - type: 模型類型
    ///   - progress: 下載進度
    ///   - completion: Result<URL, Error>
    func loadModel(type: ModelType = .int8lut, progress: ((WWNetworking.DownloadProgressInformation) -> Void)? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        
        guard let modelUrl = URL(string: type.urlString()),
              let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else {
            return completion(.failure(WWMachineLearning.CustomError.notURL))
        }
        
        let compiledModelUrl = WWMachineLearning.shared.compiledModelUrl(modelUrl, for: folder)
        
        self.type = type
        self.modelUrl = modelUrl
        
        WWMachineLearning.shared.createFolder(folder)
        
        if FileManager.default._fileExists(with: compiledModelUrl).isExist {
            switch WWMachineLearning.shared.cacheModel(with: compiledModelUrl) {
            case .failure(let error): return completion(.failure(error))
            case .success(let model): self.model = model; return completion(.success(compiledModelUrl))
            }
        }
        
        WWMachineLearning.shared.downloadModel(modelUrl: modelUrl, folder: folder) { info in
            progress?(info)
        } completion: { downloadResult in
            switch downloadResult {
            case .failure(let error): completion(.failure(error))
            case .success(let model): self.model = model; completion(.success(compiledModelUrl))
            }
        }
    }
        
    /// [分析圖片是什麼物體](https://developer.apple.com/machine-learning/models/)
    /// - Parameters:
    ///   - image: UIImage?
    ///   - completion: (Result<ProbabilityInformation?, Error>) -> Void
    func probability(image: UIImage?, completion: @escaping (Result<ProbabilityInformation, Error>) -> Void) {
        
        prediction(with: image) { result in

            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let observations):
                
                guard let firstObservation = observations.first else { return completion(.failure(WWMachineLearning.CustomError.isEmpty)) }

                let info = ProbabilityInformation(label: firstObservation.identifier, probability: Double(firstObservation.confidence))
                completion(.success(info))
            }
        }
    }
        
    /// [分析圖片哪一些物體們的機率](https://medium.com/彼得潘的-swift-ios-app-開發教室/swiftui-使用-coreml-進行圖像辨識-ce02a92573f6)
    /// - Parameters:
    ///   - image: 圖片
    ///   - standardValue: 標準值
    ///   - completion: (Result<[ProbabilityInformation], Error>) -> Void
    func probabilities(image: UIImage?, standardValue: Double = 0.1, completion: @escaping (Result<[ProbabilityInformation], Error>) -> Void) {
        
        prediction(with: image) { result in

            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let observations):
                
                let infos = observations.compactMap { observation -> ProbabilityInformation? in
                    guard Double(observation.confidence) >= standardValue else { return nil }
                    return ProbabilityInformation(label: observation.identifier, probability: Double(observation.confidence))
                }
                
                completion(.success(infos))
            }
        }
    }
    
    /// 載入模型 (從快取 or 網路重新下載)
    /// - Parameters:
    ///   - type: 模型類型
    /// - Returns: Result<URL, Error>
    func loadModel(type: ModelType = .int8lut) async -> Result<URL, Error> {
        
        await withCheckedContinuation { continuation in
            loadModel(type: type) { continuation.resume(returning: $0) }
        }
    }
    
    /// 分析圖片是什麼物體
    /// - Parameters:
    ///   - image: UIImage?
    /// - Returns: Result<ProbabilityInformation, Error>
    func probability(image: UIImage?) async -> Result<ProbabilityInformation, Error> {
        
        await withCheckedContinuation { continuation in
            probability(image: image) { continuation.resume(returning: $0) }
        }
    }
    
    /// 分析圖片哪一些物體們的機率
    /// - Parameters:
    ///   - image: 圖片
    ///   - standardValue: 標準值
    /// - Returns: Result<[ProbabilityInformation], Error>
    func probabilities(image: UIImage?, standardValue: Double = 0.1) async -> Result<[ProbabilityInformation], Error> {
        
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
    ///   - completion: (Result<[VNClassificationObservation], Error>) -> Void
    func prediction(with image: UIImage?, result: @escaping (Result<[VNClassificationObservation], Error>) -> Void) {
        
        guard let model = self.model else { return result(.failure(WWMachineLearning.CustomError.notModelLoaded)) }
        
        guard let pixelBuffer = image?._resized(for: .init(width: 224, height: 224), scale: 1.0)._pixelBuffer() else { return result(.failure(WWMachineLearning.CustomError.notCreatePixelBuffer)) }
        
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
