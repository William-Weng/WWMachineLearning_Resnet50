//
//  WWMachineLearning.swift
//  WWMachineLearning
//
//  Created by William.Weng on 2025/8/12.
//

import CoreML
import WWNetworking

// MARK: - WWMachineLearning
open class WWMachineLearning {
    
    public static let shared = WWMachineLearning()
    
    private init() {}
}

// MARK: - 小工具
public extension WWMachineLearning {
    
    /// 建立儲存Model的資料夾
    /// - Returns: Result<Bool, Error>
    func createFolder(_ folder: URL) -> Result<URL, Error> {
                
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            return .success(folder)
        } catch {
            return .failure(error)
        }
    }
    
    /// 載入已編譯的Model
    /// - Parameter compiledModelUrl: URL
    /// - Returns: Result<MLModel, Error>
    func cacheModel(with compiledModelUrl: URL) -> Result<MLModel, Error> {
        do {
            return try .success(MLModel(contentsOf: compiledModelUrl))
        } catch {
            return .failure(error)
        }
    }

    /// 下載模型 + 完成後編譯
    /// - Parameters:
    ///   - modelUrl: 模型所在的URL
    ///   - folder: 模型完成後所在的資料夾
    ///   - progress: 下載模型進度
    ///   - completion: 完成結果
    func downloadModel(modelUrl: URL, folder: URL, progress: @escaping ((WWNetworking.DownloadProgressInformation) -> Void), completion: @escaping (Result<MLModel, Error>) -> Void) {
        
        let uncompiledModelUrl = uncompiledModelUrl(modelUrl, for: folder)
        let compiledModelUrl = compiledModelUrl(modelUrl, for: folder)
        
        _ = WWNetworking.shared.download(urlString: modelUrl.absoluteString, progress: { info in
            progress(info)
            
        }, completion: { [weak self] downloadResult in
            
            guard let this = self else { return }
            
            switch downloadResult {
            case .failure(let error): print(error)
            case .success(let info):
                
                switch FileManager.default._moveFile(at: info.location, to: uncompiledModelUrl) {
                case .failure(let error): return completion(.failure(error))
                case .success(let isSuccess): if (!isSuccess) { return completion(.failure(CustomError.notMoveFile)) }
                }
                
                this.compileModel(at: uncompiledModelUrl, to: compiledModelUrl) { compileResult in
                    switch compileResult {
                    case .failure(let error): return completion(.failure(error))
                    case .success(let model): return completion(.success(model))
                    }
                }
            }
        })
    }
    
    /// 編譯模型
    /// - Parameters:
    ///   - uncompiledModelUrl: 未壓縮的模型路徑
    ///   - compiledModelUrl: 壓縮完成後的模型路徑
    ///   - result: Result<MLModel, Error>
    func compileModel(at uncompiledModelUrl: URL, to compiledModelUrl: URL, result: @escaping (Result<MLModel, Error>) -> Void)  {
        
        MLModel.compileModel(at: uncompiledModelUrl) { compileResult in
            
            _ = FileManager.default._removeFile(at: uncompiledModelUrl)
            
            switch compileResult {
            case .failure(let error): return result(.failure(error))
            case .success(let compiledUrl):
                
                switch FileManager.default._moveFile(at: compiledUrl, to: compiledModelUrl) {
                case .failure(let error): return result(.failure(error))
                case .success(let isSuccess): if (!isSuccess) { return result(.failure(CustomError.notMoveFile)) }
                }

                switch MLModel._maker(contentsOf: compiledModelUrl) {
                case .failure(let error): return result(.failure(error))
                case .success(let model): return result(.success(model))
                }
            }
        }
    }
    
    /// 取得未編譯模型的本地URL => ooxx.mlmodel
    /// - Parameters:
    ///   - modelUrl: URL
    ///   - folder: URL
    /// - Returns: Result<URL, Error>
    func uncompiledModelUrl(_ modelUrl: URL, for folder: URL) -> URL {
                
        let name = modelUrl.lastPathComponent
        let url = folder.appendingPathComponent(name)
        
        return url
    }
    
    /// 取得編譯後模型的本地URL => ooxx.mlmodelc
    /// - Parameters:
    ///   - modelUrl: URL
    ///   - folder: URL
    /// - Returns: URL
    func compiledModelUrl(_ modelUrl: URL, for folder: URL) -> URL {
        
        let name = modelUrl.deletingPathExtension().lastPathComponent + ".mlmodelc"
        let url = folder.appendingPathComponent(name)
        
        return url
    }
}
