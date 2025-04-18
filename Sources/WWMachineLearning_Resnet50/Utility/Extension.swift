//
//  Extension.swift
//  WWMachineLearning
//
//  Created by William.Weng on 2025/4/18.
//

import UIKit

// MARK: - CGImage (function)
public extension CGImage {
    
    /// [CGImage => CVPixelBuffer](https://juejin.cn/post/7064214474130980878)
    /// - Returns: [CVPixelBuffer?](https://blog.csdn.net/q345911572/article/details/117551676)
    func _pixelBuffer() -> CVPixelBuffer? {
        
        guard let buffer = CVPixelBuffer._create(cgImage: self) else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let size = CGSize(width: width, height: height)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        
        let info = CGImageAlphaInfo.noneSkipFirst.rawValue
        
        guard let context = CGContext._build(with: info, size: size, pixelData: pixelData, bitsPerComponent: 8, bytesPerRow: bytesPerRow, colorSpace: CGColorSpaceCreateDeviceRGB())
        else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }
        
        context.draw(self, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
}

// MARK: - CGContext (static function)
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

// MARK: - CVPixelBuffer (static function)
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

// MARK: - UIImage (function)
public extension UIImage {
    
    /// 產生CVPixelBuffer (影片傳輸用)
    /// - Returns: CVPixelBuffer?
    func _pixelBuffer() -> CVPixelBuffer? {
        
        autoreleasepool {
            return cgImage?._pixelBuffer()
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
}
