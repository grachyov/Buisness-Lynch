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
    let pageURL = NSURL(string: "http://www.artlebedev.ru/kovodstvo/business-lynch/2015/03/11/")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showImage()
        findOffset()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showImage() {
        srcView = UIImageView(image: loadSrcImage())
        view.addSubview(srcView!)
        view.addSubview(UIImageView(image: loadOverlayImage()))
        view.addSubview(createTestLabel())
    }
    
    func loadSrcImage() -> UIImage {
        let pageHTMLData = NSData(contentsOfURL: pageURL)
        let lynchParser = TFHpple(HTMLData: pageHTMLData)
        let srcImageXpath = "//link[@rel='image_src']/@href"
        srcImageStringURL = lynchParser.peekAtSearchWithXPathQuery(srcImageXpath).content
        let srcImageURL = NSURL(string: "http:" + srcImageStringURL!)!
        let srcImage = UIImage(data: NSData(contentsOfURL: srcImageURL)!)!
        return srcImage
    }
    
    func loadOverlayImage() -> UIImage {
        var overlayImageStringURL = srcImageStringURL!
        overlayImageStringURL.removeRange(overlayImageStringURL.rangeOfString("jpg")!)
        overlayImageStringURL.removeRange(overlayImageStringURL.rangeOfString("//")!)
        overlayImageStringURL = "http://" + overlayImageStringURL + "png"
        var pngImageName = overlayImageStringURL.lastPathComponent
        overlayImageStringURL = overlayImageStringURL.stringByDeletingLastPathComponent
        overlayImageStringURL = overlayImageStringURL + "/lynch-" + pngImageName
        let overlayImageURL = NSURL(string: overlayImageStringURL)!
        let overlayImage = UIImage(data: NSData(contentsOfURL: overlayImageURL)!)!
        return overlayImage
    }
    
    func findOffset() {
        let pageHTMLData = NSData(contentsOfURL: pageURL)
        let lynchParser = TFHpple(HTMLData: pageHTMLData)
        let offsetXpath = "//div[@id='Lynch']/img/@style"
        let offsetString = lynchParser.peekAtSearchWithXPathQuery(offsetXpath).content
        let firstJunkRange = offsetString.rangeOfString("left: ")
        let secondJunkRange = offsetString.rangeOfString("px; top: ")
        let xOffsetString = offsetString.substringWithRange(firstJunkRange!.endIndex ..< secondJunkRange!.startIndex)
        var yOffsetString = offsetString.substringWithRange(secondJunkRange!.endIndex ..< offsetString.endIndex)
        yOffsetString.removeRange(yOffsetString.rangeOfString("px;")!)
        
        let xFloat = CGFloat(xOffsetString.toInt()!)
        let newX = CGFloat(srcView!.center.x) + xFloat
        srcView!.center.x = newX
        
        let yFloat = CGFloat(yOffsetString.toInt()!)
        let newY = CGFloat(srcView!.center.y) + yFloat
        srcView!.center.y = newY
    }

    func createTestLabel() -> UILabel {
        let pageHTMLData = NSData(contentsOfURL: pageURL)
        let lynchParser = TFHpple(HTMLData: pageHTMLData)
        let coordinatesXpath = "//div[@id='Lynch']//div[@class='LynchComment']/@style"
        let coordinatesString = lynchParser.peekAtSearchWithXPathQuery(coordinatesXpath).content
        
        let leftJunkRange = coordinatesString.rangeOfString("left: ")
        let topJunkRange = coordinatesString.rangeOfString("px; top: ")
        let widthJunkRange = coordinatesString.rangeOfString("px; width: ")
        let heightJunkRange = coordinatesString.rangeOfString("px; height: ")
        let colorJunkRange = coordinatesString.rangeOfString("px; color:")
        
        let textX = CGFloat(coordinatesString.substringWithRange(leftJunkRange!.endIndex ..< topJunkRange!.startIndex).toInt()!)
        let textY = CGFloat(coordinatesString.substringWithRange(topJunkRange!.endIndex ..< widthJunkRange!.startIndex).toInt()!)
        let textWidth = CGFloat(coordinatesString.substringWithRange(widthJunkRange!.endIndex ..< heightJunkRange!.startIndex).toInt()!)
        let textHeight = CGFloat(coordinatesString.substringWithRange(heightJunkRange!.endIndex ..< colorJunkRange!.startIndex).toInt()!)
        
        let commentTextXpath = "//div[@id='Lynch']//div[@class='LynchComment']"
        var lynchCommentRaw = lynchParser.peekAtSearchWithXPathQuery(commentTextXpath).raw
        let beginningJunkRange = lynchCommentRaw.rangeOfString("><div>")
        let endingJunkRange = lynchCommentRaw.rangeOfString("</div></div>")
        var commentText = lynchCommentRaw.substringWithRange(beginningJunkRange!.endIndex.successor() ..< endingJunkRange!.startIndex.predecessor())
        commentText = commentText.stringByReplacingOccurrencesOfString("<br/>", withString: "\n")

        let label = UILabel(frame: CGRect(x: textX + 8, y: textY, width: textWidth - 8 - 4, height: textHeight))
        label.font = UIFont(name: "Arial", size: 13)
        label.numberOfLines = 0
        label.text = commentText
        return label
    }
    
}