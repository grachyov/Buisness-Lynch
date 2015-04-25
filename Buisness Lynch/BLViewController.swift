//
//  BLViewController.swift
//  Buisness Lynch
//
//  Created by Ivan Grachev on 25/03/15.
//  Copyright (c) 2015 Ivan Grachev. All rights reserved.
//

import UIKit

class BLViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var imageScrollView: UIScrollView!
    @IBOutlet weak var descriptionView: UIView!
    
    var mergedImageView: UIImageView?
    
    var srcImageStringURL: String?
    var srcView: UIView?
    var srcImage: UIImage?
    var mergedImage: UIImage?
    var overlayImage: UIImage?
    var xOffset: CGFloat?
    var yOffset: CGFloat?
    var lynchComments: [(text: String, frame: CGRect)] = []
    let pageURL = NSURL(string: "http://www.artlebedev.ru/kovodstvo/business-lynch/today/")!
    var didSetup = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        if !didSetup {
            didSetup = true
            showImage()
            findImageOffset()
            mergeImagesAndComments()
            addDescriptionViewSeparator()
            addDoubleTapGestureRecognizer()
        }
    }

    func addDoubleTapGestureRecognizer() {
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: Selector("handleDoubleTap:"))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        imageScrollView.addGestureRecognizer(doubleTapRecognizer)
    }
    
    func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        if imageScrollView.zoomScale > imageScrollView.minimumZoomScale {
            imageScrollView.setZoomScale(imageScrollView.minimumZoomScale, animated: true)
        }
        else {
            imageScrollView.setZoomScale(imageScrollView.maximumZoomScale, animated: true)
        }
    }
    
    func addDescriptionViewSeparator() {
        let separatorView = UIView(frame: CGRect(x: 0, y: 0, width: descriptionView.frame.width, height: 0.5))
        separatorView.backgroundColor = UIColor.lightGrayColor()
        descriptionView.addSubview(separatorView)
    }
    
    func showImage() {
        loadSrcImage()
        loadOverlayImage()
//        srcView = UIImageView(image: loadSrcImage())
//        view.addSubview(srcView!)
//        view.addSubview(UIImageView(image: loadOverlayImage()))
        addTestLabels()
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
        let lynchCommentsArray = lynchParser.searchWithXPathQuery(lynchCommentXpath) as! [TFHppleElement]
        for lynchCommentElement in lynchCommentsArray {
            let coordinatesString = lynchCommentElement.attributes["style"]! as! String
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
            if (endingJunkRange != nil) {
                var commentText = lynchCommentRaw.substringWithRange(beginningJunkRange!.endIndex.successor() ..< endingJunkRange!.startIndex.predecessor())
                commentText = commentText.stringByReplacingOccurrencesOfString("<br/>", withString: "\n")
                while let beforeURLJunkRange = commentText.rangeOfString("<a href=\"http://") {
                    let afterURLJunkRange = commentText.rangeOfString("\" class=")
                    let afterURLJunkEndRange = commentText.rangeOfString("</a>")
                    let linkString = commentText.substringWithRange(beforeURLJunkRange.endIndex ..< afterURLJunkRange!.startIndex)
                    commentText.replaceRange(beforeURLJunkRange.startIndex ..< afterURLJunkEndRange!.endIndex, with: linkString)
                }
                
                lynchComments += [(text: commentText, frame: CGRect(x: textX + 8, y: textY, width: textWidth - 8 - 4, height: textHeight))]
            }
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
        CGContextConcatCTM(context, translation)
        srcImage!.drawInRect(CGRect(x: xOffset!, y: yOffset!, width: srcImage!.size.width, height: srcImage!.size.height))
        overlayImage!.drawInRect(CGRect(x: 0, y: 0, width: overlayImage!.size.width, height: overlayImage!.size.height))
        for (text: String, frame: CGRect) in lynchComments {
            let attributedString = NSAttributedString(string:text, attributes:[NSFontAttributeName:UIFont(name:"Arial", size:13)!])
            attributedString.drawInRect(frame)
        }
        CGContextConcatCTM(context, CGAffineTransformInvert(translation))
        mergedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        mergedImageView = UIImageView(image: mergedImage)
        imageScrollView.maximumZoomScale = 1
        imageScrollView.minimumZoomScale = 0.4
        imageScrollView.contentSize = mergedImage!.size
        imageScrollView.delegate = self
        imageScrollView.zoomScale = 0.4
        imageScrollView.addSubview(mergedImageView!)
    }
    
    @IBAction func switchBetweenCommentedAndOriginal(sender: UIButton) {
        if sender.titleLabel?.text! == "Оригинал" {
            sender.setTitle("С рецензией", forState: UIControlState.allZeros)
            mergedImageView?.image = srcImage
        }
        else {
            sender.setTitle("Оригинал", forState: UIControlState.allZeros)
            mergedImageView?.image = mergedImage
        }
    }
    func calculateMergedSideSize(srcSide: CGFloat, overlaySide: CGFloat, offset: CGFloat) -> CGFloat {
        if offset < 0 {
            return offset + max(overlaySide, srcSide - offset)
        }
        else {
            return max(overlaySide, offset + srcSide)
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return mergedImageView
    }
}