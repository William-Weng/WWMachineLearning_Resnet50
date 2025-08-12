//
//  Constant.swift
//  WWMachineLearning
//
//  Created by William.Weng on 2025/8/12.
//

import Foundation

// MARK: - typealias
public extension WWMachineLearning {
    
    typealias ProbabilityInformation = (label: String, probability: Double)     // (標籤名稱, 可能性)
    typealias FileInformation = (isExist: Bool, isDirectory: Bool)              // 檔案相關資訊 (是否存在 / 是否為資料夾)
}

// MARK: - enum
public extension WWMachineLearning {
    
    /// 自定義錯誤
    enum CustomError: Error {
        case isEmpty
        case isImageEmpty
        case notURL
        case notExist
        case notMoveFile
        case notModelLoaded
        case notCreatePixelBuffer
    }
}

// MARK: - enum
public extension WWMachineLearning.Resnet50 {
    
    /// 模型類型
    enum ModelType {

        case `default`
        case headless
        case fp16
        case int8lut
        
        /// [模型下載路徑](https://developer.apple.com/machine-learning/models/)
        /// - Returns: String
        func urlString() -> String {
            
            let baseURL = "https://ml-assets.apple.com/coreml/models/Image/ImageClassification/Resnet50"
            
            switch self {
            case .default: return "\(baseURL)/Resnet50.mlmodel"
            case .headless: return "\(baseURL)/Resnet50Headless.mlmodel"
            case .fp16: return "\(baseURL)/Resnet50FP16.mlmodel"
            case .int8lut: return "\(baseURL)/Resnet50Int8LUT.mlmodel"
            }
        }
    }
}
