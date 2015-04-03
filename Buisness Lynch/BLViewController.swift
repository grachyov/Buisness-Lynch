//
//  BLViewController.swift
//  Buisness Lynch
//
//  Created by Ivan Grachev on 25/03/15.
//  Copyright (c) 2015 Ivan Grachev. All rights reserved.
//

import UIKit

class BLViewController: UIViewController {

    var srcImageStringURL: String?
    var srcView: UIView?
    var srcImage: UIImage?
    var overlayImage: UIImage?
    var xOffset: CGFloat?
    var yOffset: CGFloat?
    let pageURL = NSURL(string: "http://www.artlebedev.ru/kovodstvo/business-lynch/2015/03/30/")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showImage()
        findImageOffset()
        mergeImagesAndComments()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func showImage() {
        loadSrcImage()
        loadOverlayImage()
//        srcView = UIImageView(image: loadSrcImage())
//        view.addSubview(srcView!)
//        view.addSubview(UIImageView(image: loadOverlayImage()))
//        addTestLabels()
    }
    
    func loadSrcImage() -> UIImage {
        let pageHTMLData = NSData(contentsOfURL: pageURL)
        let lynchParser = TFHpple(HTMLData: pageHTMLData)
        let srcImageXpath = "//link[@rel='image_src']/@href"
        srcImageStringURL = lynchParser.peekAtSearchWithXPathQuery(srcImageXpath).content
        let srcImageURL = NSURL(string: "http:" + srcImageStringURL!)!
        srcImage = UIImage(data: NSData(contentsOfURL: srcImageURL)!)!
        return srcImage!
    }
    
    func loadOverlayImage() -> UIImage {
        var overlayImageStringURL = srcImageStringURL!
        overlayImageStringURL = "http:/" + overlayImageStringURL.stringByDeletingPathExtension + ".png"
        var pngImageName = overlayImageStringURL.lastPathComponent
        overlayImageStringURL = overlayImageStringURL.stringByDeletingLastPathComponent
        overlayImageStringURL = overlayImageStringURL + "/lynch-" + pngImageName
        let overlayImageURL = NSURL(string: overlayImageStringURL)!
        overlayImage = UIImage(data: NSData(contentsOfURL: overlayImageURL)!)!
        return overlayImage!
    }
    
    func findImageOffset() {
        let pageHTMLData = NSData(contentsOfURL: pageURL)
        let lynchParser = TFHpple(HTMLData: pageHTMLData)
        let offsetXpath = "//div[@id='Lynch']/img/@style"
        let offsetString = lynchParser.peekAtSearchWithXPathQuery(offsetXpath).content
        let firstJunkRange = offsetString.rangeOfString("left: ")
        let secondJunkRange = offsetString.rangeOfString("px; top: ")
        let xOffsetString = offsetString.substringWithRange(firstJunkRange!.endIndex ..< secondJunkRange!.startIndex)
        var yOffsetString = offsetString.substringWithRange(secondJunkRange!.endIndex ..< offsetString.endIndex)
        yOffsetString.removeRange(yOffsetString.rangeOfString("px;")!)
        
        xOffset = CGFloat(xOffsetString.toInt()!)
//        let newX = CGFloat(srcView!.center.x) + xFloat
//        srcView!.center.x = newX
        
        yOffset = CGFloat(yOffsetString.toInt()!)
//        let newY = CGFloat(srcView!.center.y) + yFloat
//        srcView!.center.y = newY
    }

    func addTestLabels() {
        let pageHTMLData = NSData(contentsOfURL: pageURL)
        let lynchParser = TFHpple(HTMLData: pageHTMLData)
        let lynchCommentXpath = "//div[@id='Lynch']//div[@class='LynchComment']"
        let lynchCommentsArray = lynchParser.searchWithXPathQuery(lynchCommentXpath) as [TFHppleElement]
        for lynchCommentElement in lynchCommentsArray {
            let coordinatesString = lynchCommentElement.attributes["style"]! as String
            var lynchCommentRaw = lynchCommentElement.raw
            
            let leftJunkRange = coordinatesString.rangeOfString("left: ")
            let topJunkRange = coordinatesString.rangeOfString("px; top: ")
            let widthJunkRange = coordinatesString.rangeOfString("px; width: ")
            let heightJunkRange = coordinatesString.rangeOfString("px; height: ")
            let colorJunkRange = coordinatesString.rangeOfString("px; color:")
            
            let textX = CGFloat(coordinatesString.substringWithRange(leftJunkRange!.endIndex ..< topJunkRange!.startIndex).toInt()!)
            let textY = CGFloat(coordinatesString.substringWithRange(topJunkRange!.endIndex ..< widthJunkRange!.startIndex).toInt()!)
            let textWidth = CGFloat(coordinatesString.substringWithRange(widthJunkRange!.endIndex ..< heightJunkRange!.startIndex).toInt()!)
            let textHeight = CGFloat(coordinatesString.substringWithRange(heightJunkRange!.endIndex ..< colorJunkRange!.startIndex).toInt()!)
            
            let beginningJunkRange = lynchCommentRaw.rangeOfString("><div>")
            let endingJunkRange = lynchCommentRaw.rangeOfString("</div></div>")
            var commentText = lynchCommentRaw.substringWithRange(beginningJunkRange!.endIndex.successor() ..< endingJunkRange!.startIndex.predecessor())
            commentText = commentText.stringByReplacingOccurrencesOfString("<br/>", withString: "\n")
            while let beforeURLJunkRange = commentText.rangeOfString("<a href=\"http://") {
                let afterURLJunkRange = commentText.rangeOfString("\" class=")
                let afterURLJunkEndRange = commentText.rangeOfString("</a>")
                let linkString = commentText.substringWithRange(beforeURLJunkRange.endIndex ..< afterURLJunkRange!.startIndex)
                commentText.replaceRange(beforeURLJunkRange.startIndex ..< afterURLJunkEndRange!.endIndex, with: linkString)
            }
            
            let label = UILabel(frame: CGRect(x: textX + 8, y: textY, width: textWidth - 8 - 4, height: textHeight))
            label.font = UIFont(name: "Arial", size: 13)
            label.numberOfLines = 0
            label.text = commentText
            view.addSubview(label)
        }
    }
    
    func mergeImagesAndComments() {
        var mergedWidth = calculateMergedSideSize(srcImage!.size.width, overlaySide: overlayImage!.size.width, offset: xOffset!)
        var mergedHeight = calculateMergedSideSize(srcImage!.size.height, overlaySide: overlayImage!.size.height, offset: yOffset!)
        let mergedSize = CGSize(width: mergedWidth, height: mergedHeight)
        let overlayOrigin = CGPoint(x: ((xOffset! > 0) ? 0 : -xOffset!), y: ((yOffset! > 0) ? 0 : -yOffset!))
        
        UIGraphicsBeginImageContextWithOptions(mergedSize, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        let translation = CGAffineTransformMakeTranslation(overlayOrigin.x, overlayOrigin.y)
        srcImage!.drawInRect(CGRect(x: xOffset!, y: yOffset!, width: srcImage!.size.width, height: srcImage!.size.height))
        overlayImage!.drawInRect(CGRect(x: 0, y: 0, width: overlayImage!.size.width, height: overlayImage!.size.height))
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let mergedImageView = UIImageView(frame: view.frame)
        mergedImageView.contentMode = UIViewContentMode.ScaleAspectFit
        mergedImageView.image = resultImage
        view.addSubview(mergedImageView)
    }
    
    func calculateMergedSideSize(srcSide: CGFloat, overlaySide: CGFloat, offset: CGFloat) -> CGFloat {
        if offset < 0 {
            return offset + max(overlaySide, srcSide - offset)
        }
        else {
            return max(overlaySide, offset + srcSide)
        }
    }
}