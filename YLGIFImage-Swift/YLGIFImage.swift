//
//  YLGIFImage.swift
//  YLGIFImage
//
//  Created by Yong Li on 6/8/14.
//  Copyright (c) 2014 Yong Li. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices

public class YLGIFImage : UIImage {
    
    private class func isCGImageSourceContainAnimatedGIF(_ cgImageSource: CGImageSource) -> Bool {
        let isGIF = UTTypeConformsTo(CGImageSourceGetType(cgImageSource)!, kUTTypeGIF)
        let imgCount = CGImageSourceGetCount(cgImageSource)
        return isGIF && imgCount > 1
    }
    
    private class func getCGImageSourceGifFrameDelay(_ imageSource: CGImageSource, index: UInt) -> TimeInterval {
        var delay = 0.0
        let imgProperties:NSDictionary = CGImageSourceCopyPropertiesAtIndex(imageSource, Int(index), nil)!
        let gifProperties:NSDictionary? = imgProperties[kCGImagePropertyGIFDictionary as String] as? NSDictionary
        if let property = gifProperties {
            delay = property[kCGImagePropertyGIFUnclampedDelayTime as String] as! Double
            if delay <= 0 {
                delay = property[kCGImagePropertyGIFDelayTime as String] as! Double
            }
        }
        return delay
    }
    
    private func createSelf(_ cgImageSource: CGImageSource!, scale: CGFloat) -> Void {
        _cgImgSource = cgImageSource
        let imageProperties:NSDictionary = CGImageSourceCopyProperties(_cgImgSource!, nil)!
        let gifProperties: NSDictionary? = imageProperties[kCGImagePropertyGIFDictionary as String] as? NSDictionary
        if let property = gifProperties {
            self.loopCount = property[kCGImagePropertyGIFLoopCount as String] as! UInt
        }
        let numOfFrames = CGImageSourceGetCount(cgImageSource)
        for i in 0..<numOfFrames {
            // get frame duration
            let frameDuration = YLGIFImage.getCGImageSourceGifFrameDelay(cgImageSource, index: UInt(i))
            self.frameDurations.append(NSNumber(value: frameDuration))
            self.totalDuration += frameDuration
            
            //Log("dura = \(frameDuration)")
            
            if i < Int(YLGIFImage.prefetchNum) {
                // get frame
                let cgimage = CGImageSourceCreateImageAtIndex(cgImageSource, i, nil)
                let image: UIImage = UIImage(cgImage: cgimage!)
                self.frameImages.append(image)
                //Log("\(i): frame = \(image)")
            } else {
                self.frameImages.append(NSNull())
            }
        }
        //Log("\(self.frameImages.count)")
    }

    private lazy var readFrameQueue:DispatchQueue = DispatchQueue(label: "com.ronnie.gifreadframe")

    private var _scale:CGFloat = 1.0
    private var _cgImgSource:CGImageSource? = nil
    var totalDuration: TimeInterval = 0.0
    var frameDurations = [AnyObject]()
    var loopCount: UInt = 1
    var frameImages:[AnyObject] = [AnyObject]()

    struct YLGIFGlobalSetting {
        static var prefetchNumber:UInt = 10
    }

    class var prefetchNum: UInt {
        return YLGIFGlobalSetting.prefetchNumber
    }

    class func setPrefetchNum(_ number:UInt) {
        YLGIFGlobalSetting.prefetchNumber = number
    }

    public convenience init?(named name: String!) {
        guard let path = Bundle.main.path(forResource: name, ofType: nil)
            else { return nil }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path))
            else { return nil }
        self.init(data: data)
    }

    public convenience override init?(contentsOfFile path: String) {
        let data = try? Data(contentsOf: URL(string: path)!)
        self.init(data: data!)
    }

    public override init?(data: Data)  {
        if let cgImgSource = CGImageSourceCreateWithData(data as CFData, nil), YLGIFImage.isCGImageSourceContainAnimatedGIF(cgImgSource) {
            super.init()
            createSelf(cgImgSource, scale: 1.0)
        } else {
            super.init(data: data)
        }
    }

    public override init?(data: Data, scale: CGFloat) {
        if let cgImgSource = CGImageSourceCreateWithData(data as CFData, nil), YLGIFImage.isCGImageSourceContainAnimatedGIF(cgImgSource) {
            super.init()
            createSelf(cgImgSource, scale: scale)
        } else {
            super.init(data: data, scale: scale)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required public init(imageLiteralResourceName name: String) {
        fatalError("init(imageLiteral name:) has not been implemented")
    }

    func getFrame(_ index: UInt) -> UIImage? {
        if Int(index) >= self.frameImages.count {
            return nil
        }
        let image:UIImage? = self.frameImages[Int(index)] as? UIImage
        if self.frameImages.count > Int(YLGIFImage.prefetchNum) {
            if index != 0 {
                self.frameImages[Int(index)] = NSNull()
            }

            for i in index+1...index+YLGIFImage.prefetchNum {
                let idx = Int(i)%self.frameImages.count
                if self.frameImages[idx] is NSNull {
                    self.readFrameQueue.async{
                        let cgImg = CGImageSourceCreateImageAtIndex(self._cgImgSource!, idx, nil)
                        self.frameImages[idx] = UIImage(cgImage: cgImg!)
                    }
                }
            }
        }

        return image
    }
}
