//
//  Extension.swift
//  WWMachineLearning
//
//  Created by William.Weng on 2025/8/12.
//

import UIKit
import CoreML

// MARK: - FileManager (public)
public extension FileManager {
    
    /// 移動檔案
    /// - Parameters:
    ///   - atURL: 從這裡移動 =>
    ///   - toURL: => 到這裡
    /// - Returns: Result<Bool, Error>
    func _moveFile(at atURL: URL, to toURL: URL) -> Result<Bool, Error> {
        
        do {
            try? removeItem(at: toURL)
            try moveItem(at: atURL, to: toURL)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    /// 移除檔案
    /// - Parameter atURL: URL
    /// - Returns: Result<Bool, Error>
    func _removeFile(at url: URL?) -> Result<Bool, Error> {
        
        guard let url = url,
              _fileExists(with: url).isExist
        else {
            return .failure(WWMachineLearning.CustomError.notExist)
        }

        do {
            try removeItem(at: url)
            return .success(true)
        } catch  {
            return .failure(error)
        }
    }
    
    /// 新增資料夾
    /// - Parameters:
    ///   - url: 基本資料夾位置
    ///   - path: 資料夾名稱
    /// - Returns: Result<Bool, Error>
    func _createDirectory(with url: URL?, path: String?) -> Result<Bool, Error> {
        
        guard var directoryURL = url else { return .success(false) }

        if let path { directoryURL = directoryURL.appendingPathComponent(path) }
        
        do {
            try createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    /// 測試該檔案是否存在 / 是否為資料夾
    /// - Parameter url: 檔案的URL路徑
    /// - Returns: Constant.FileInformation
    func _fileExists(with url: URL?) -> WWMachineLearning.FileInformation {

        guard let url = url else { return (false, false) }
        
        var isDirectory: ObjCBool = false
        let isExist = fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        return (isExist, isDirectory.boolValue)
    }
}

// MARK: - UIImage
public extension UIImage {
    
    /// 產生CVPixelBuffer (影片傳輸用)
    /// - Parameters:
    ///   - allocator: CFAllocator?
    ///   - formatType: OSType
    ///   - colorSpace: CGColorSpace
    ///   - imageInfo: UInt32
    /// - Returns: CVPixelBuffer?
    func _pixelBuffer(allocator: CFAllocator? = kCFAllocatorDefault, formatType: OSType = kCVPixelFormatType_32ARGB, colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB(), imageInfo: UInt32 = CGImageAlphaInfo.noneSkipFirst.rawValue) -> CVPixelBuffer? {
        
        autoreleasepool {
            return cgImage?._pixelBuffer(allocator: allocator, formatType: formatType, colorSpace: colorSpace, imageInfo: imageInfo)
        }
    }

    /// 改變圖片大小
    /// - Returns: UIImage
    /// - Parameters:
    ///   - size: 要改變的尺寸
    ///   - scale: 對應的畫面比例 (Retina圖像)
    func _resized(for size: CGSize, scale: CGFloat) -> UIImage {
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let resizeImage = renderer.image { (context) in draw(in: renderer.format.bounds) }
        
        return resizeImage
    }
    
    /// 改變圖片大小
    /// - Returns: UIImage
    /// - Parameters:
    ///   - size: 要改變的尺寸
    ///   - format: UIGraphicsImageRendererFormat
    func _resized(for size: CGSize, format: UIGraphicsImageRendererFormat) -> UIImage {
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let resizeImage = renderer.image { (context) in draw(in: renderer.format.bounds) }
        
        return resizeImage
    }
    
    /// 根據畫面比例重新調整圖片大小 => UIScreen.main.scale
    /// - Parameters:
    ///   - scale: CGFloat
    ///   - orientation: UIImage.Orientation
    /// - Returns: UIImage?
    func _rescaled(_ scale: CGFloat, orientation: UIImage.Orientation) -> UIImage? {
        
        guard let cgImage = self.cgImage else { return nil }
        
        let scaleImage = UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        return scaleImage
    }
    
    /// 圖片標準化 (比例 / 大小 / 色深) => 模型處理用
    /// - Parameters:
    ///   - size: 大小
    ///   - bitsPerComponent: 每一個顏色組件 =>（R, G, B, A）各用 8 位表示 (256色)
    ///   - bitsPerPixel: 顏色組成 =>R(8) + G(8) + B(8) + A(8) = 32
    func _normalize(with size: CGSize, bitsPerComponent: Int, bitsPerPixel: Int) -> UIImage? {
        
        let format = UIGraphicsImageRendererFormat.default()._scale(1.0)
        let resizedImage = self._resized(for: size, format: format)
        
        guard let cgimage = resizedImage.cgImage?._convertBitsPerComponent(bitsPerComponent, bitsPerPixel: bitsPerPixel) else { return nil }
        
        return UIImage(cgImage: cgimage)
    }
    
    /// 將灰階色域 (Mono) 圖片轉換為彩色色域 (RGBA) 圖片
    /// - Returns: UIImage?
    func _monochromeColorSpaceToSRGB() -> UIImage? {
        guard let cgImage = cgImage?._monochromeColorSpaceToSRGB() else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - CGImage
public extension CGImage {
    
    /// [CGImage => CVPixelBuffer](https://juejin.cn/post/7064214474130980878)
    /// - Parameters:
    ///   - allocator: CFAllocator?
    ///   - formatType: OSType
    ///   - colorSpace: CGColorSpace
    ///   - imageInfo: UInt32
    /// - Returns: [CVPixelBuffer?](https://blog.csdn.net/q345911572/article/details/117551676)
    func _pixelBuffer(allocator: CFAllocator? = kCFAllocatorDefault, formatType: OSType = kCVPixelFormatType_32ARGB, colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB(), imageInfo: UInt32) -> CVPixelBuffer? {
        
        guard let buffer = CVPixelBuffer._create(cgImage: self, allocator: allocator, formatType: formatType) else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        
        let size = CGSize(width: width, height: height)
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)

        guard let context = CGContext._build(with: imageInfo, size: size, pixelData: pixelData, bitsPerComponent: 8, bytesPerRow: bytesPerRow, colorSpace: colorSpace)
        else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }
        
        context.draw(self, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
    
    /// 轉換圖片顏色組成 (1024色 => 256色)
    /// - Parameters:
    ///   - bitsPerComponent: 每一個顏色組件 =>（R, G, B, A）各用 8-bits 表示 (256色)
    ///   - bitsPerPixel: 顏色組成 =>R(8) + G(8) + B(8) + A(8) = 32-bits
    func _convertBitsPerComponent(_ bitsPerComponent: Int, bitsPerPixel: Int) -> CGImage? {
        
        let bytesPerRow = width * bitsPerPixel / 8
        let colorSpace = colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let rect = CGRect(x: 0, y: 0, width: width, height: height)

        guard let context = CGContext._build(with: bitmapInfo.rawValue, size: rect.size, pixelData: nil, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, colorSpace: colorSpace) else { return nil }
        
        context.draw(self, in: rect)
        return context.makeImage()
    }
    
    /// 將灰階色域 (Mono) 圖片轉換為彩色色域 (RGBA) 圖片
    /// - Returns: CGImage?
    func _monochromeColorSpaceToSRGB() -> CGImage? {
        
        let size = CGSize(width: width, height: height)
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext._build(with: bitmapInfo, size: size, pixelData: nil, bitsPerComponent: 8, bytesPerRow: width * 4, colorSpace: CGColorSpaceCreateDeviceRGB()) else { return nil }
        
        context.draw(self, in: CGRect(origin: .zero, size: size))
        return context.makeImage()
    }
}

// MARK: - CGContext (static)
public extension CGContext {
    
    /// 建立CGContext
    /// - Parameters:
    ///   - info: UInt32
    ///   - size: CGSize
    ///   - pixelData: UnsafeMutableRawPointer?
    ///   - bitsPerComponent: Int
    ///   - bytesPerRow: Int
    ///   - colorSpace: CGColorSpace
    /// - Returns: CGContext?
    static func _build(with info: UInt32, size: CGSize, pixelData: UnsafeMutableRawPointer?, bitsPerComponent: Int, bytesPerRow: Int, colorSpace: CGColorSpace) -> CGContext? {
        let context = CGContext(data: pixelData, width: Int(size.width), height: Int(size.height), bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: info)
        return context
    }
}

// MARK: - CVPixelBuffer (static)
public extension CVPixelBuffer {
    
    /// [由CGImage，建立CVPixelBuffer](https://developer.apple.com/documentation/corevideo/cvpixelbuffercreate(_:_:_:_:_:_:))
    /// - Parameters:
    ///   - cgImage: CGImage?
    ///   - allocator: CFAllocator?
    ///   - formatType: OSType
    /// - Returns: CVPixelBuffer?
    static func _create(cgImage: CGImage?, allocator: CFAllocator? = kCFAllocatorDefault, formatType: OSType = kCVPixelFormatType_32ARGB) -> CVPixelBuffer? {
        
        guard let cgImage = cgImage else { return nil }
        
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        
        let status = CVPixelBufferCreate(allocator, cgImage.width, cgImage.height, formatType, attributes, &pixelBuffer)
        
        guard status == kCVReturnSuccess,
              let buffer = pixelBuffer
        else {
            return nil
        }
        
        return buffer
    }
}

// MARK: - UIGraphicsImageRendererFormat (function)
extension UIGraphicsImageRendererFormat {
    
    /// 設定比例
    /// - Parameter scale: 比例
    /// - Returns: Self
    func _scale(_ scale: CGFloat) -> Self {
        self.scale = scale
        return self
    }
    
    /// 透明度開關
    /// - Parameter opaque: Bool
    /// - Returns: Self
    func _opaque(_ opaque: Bool) -> Self {
        self.opaque = opaque
        return self
    }
}

// MARK: - MLModel (static)
extension MLModel {
    
    /// 生成MLModel
    /// - Returns: Result<MLModel, Error>
    /// - Parameters:
    ///   - url: ML模型路徑
    ///   - configuration: ML模型設定值
    static func _maker(contentsOf url: URL, configuration: MLModelConfiguration) -> Result<MLModel, Error> {
        
        do {
            let model = try MLModel(contentsOf: url, configuration: configuration)
            return .success(model)
        } catch {
            return .failure(error)
        }
    }
}
