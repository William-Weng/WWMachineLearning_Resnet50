# WWMachineLearning_Resnet50
[![Swift-5.7](https://img.shields.io/badge/Swift-5.7-orange.svg?style=flat)](https://developer.apple.com/swift/) [![iOS-15.0](https://img.shields.io/badge/iOS-15.0-pink.svg?style=flat)](https://developer.apple.com/swift/) ![TAG](https://img.shields.io/github/v/tag/William-Weng/WWMachineLearning_Resnet50) [![Swift Package Manager-SUCCESS](https://img.shields.io/badge/Swift_Package_Manager-SUCCESS-blue.svg?style=flat)](https://developer.apple.com/swift/) [![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

### [Introduction - 簡介](https://swiftpackageindex.com/William-Weng)
- [Use Apple's ResNet (Residual Neural Network) model to determine the probability of what the object in the picture is.](https://developer.apple.com/machine-learning/models/)
- [利用APPLE的ResNet (Residual Neural Network) 模型來分辨圖片上物體是什麼的機率。](https://medium.com/彼得潘的-swift-ios-app-開發教室/swiftui-使用-coreml-進行圖像辨識-ce02a92573f6)

![](./Example.webp)

### [Installation with Swift Package Manager](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/使用-spm-安裝第三方套件-xcode-11-新功能-2c4ffcf85b4b)

```bash
dependencies: [
    .package(url: "https://github.com/William-Weng/WWMachineLearning_Resnet50.git", .upToNextMajor(from: "1.0.0"))
]
```

### Function - 可用函式
|函式|功能|
|-|-|
|probability(image:)|分析圖片是什麼物體|
|probabilities(image:standardValue:)|分析圖片哪一些物體們的機率|

### Example
```swift
import UIKit
import WWMachineLearning_Resnet50

final class ViewController: UIViewController {
    
    @IBAction func probabilityTest(_ sender: UIButton) {
        
        guard let info = WWMachineLearning.Resnet50.shard.probability(image: sender.backgroundImage(for: .normal)) else { return }
        
        sender.setTitle(info.label, for: .normal)
        title = "\(info.probability * 100.0) %"
    }
}
```
