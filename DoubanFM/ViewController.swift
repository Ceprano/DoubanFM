//
//  ViewController.swift
//  DoubanFM
//
//  Created by jzhone on 14-8-8.
//  Copyright (c) 2014年 jzhone. All rights reserved.
//

import UIKit
import MediaPlayer
import QuartzCore

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, HttpProtocol, ChannelProtocol {
                            
    @IBOutlet weak var tv: UITableView!
    @IBOutlet weak var iv: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var playTime: UILabel!
    
    var eHttp:HttpController = HttpController()
    
    var tableData: NSArray = NSArray()
    var channelData: NSArray = NSArray()
    
    var imageCache = Dictionary<String, UIImage>()
    
    var audioPlayer: MPMoviePlayerController = MPMoviePlayerController()
    
    var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        eHttp.delegate = self
        eHttp.onSearch("http://www.douban.com/j/app/radio/channels")
        eHttp.onSearch("http://douban.fm/j/mine/playlist?type=n&channel=0&from=mainsite")
        progressView.progress = 0.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        var channelC: ChannelController = segue.destinationViewController as ChannelController
        channelC.delegate = self
        channelC.channelData = self.channelData
    }
    
    func onChangeChannel(channel: String) {
        let url: String = "http://douban.fm/j/mine/playlist?type=n&\(channel)&from=mainsite"
        eHttp.onSearch(url)
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int{
        return tableData.count
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!{
        let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "douban")
        let rowData: NSDictionary = self.tableData[indexPath.row] as NSDictionary
        cell.textLabel.text = rowData["title"] as String
        cell.detailTextLabel.text = rowData["artist"] as String
        cell.imageView.image = UIImage(named: "detail.jpg")
        let url = rowData["picture"] as String
        let image = self.imageCache[url] as UIImage!
        if image == nil {
            let imgURL: NSURL = NSURL(string: url)
            let request: NSURLRequest = NSURLRequest(URL: imgURL)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!, data:NSData!, error: NSError!) -> Void in
                let img = UIImage(data: data)
                cell.imageView.image = img
                self.imageCache[url] = img
                })
        } else {
            cell.imageView.image = image
        }
        return cell
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let rowData: NSDictionary = self.tableData[indexPath.row] as NSDictionary
        let audioUrl: String = rowData["url"] as String
        onSetAudio(audioUrl)
        let imageUrl: String = rowData["picture"] as String
        onSetImage(imageUrl)
    }
    
    func tableView(tableView: UITableView!, willDisplayCell cell: UITableViewCell!, forRowAtIndexPath indexPath: NSIndexPath!){
        cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1)
        UIView.animateWithDuration(0.25, animations: {
            cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
        })
    }
    
    func didiRecleveResults(results:NSDictionary){
        if (results["song"] != nil){
            self.tableData = results["song"] as NSArray
            self.tv.reloadData()
            
            let firDict: NSDictionary = self.tableData[0] as NSDictionary
            let audioUrl: String = firDict["url"] as String
            onSetAudio(audioUrl)
            let imageUrl: String = firDict["picture"] as String
            onSetImage(imageUrl)
            
            
        } else if (results["channels"] != nil){
            self.channelData = results["channels"] as NSArray

        }
        
    }
    
    func onSetAudio(url: String){
        timer?.invalidate()
        playTime.text = "00:00"
        self.audioPlayer.stop()
        self.audioPlayer.contentURL = NSURL(string: url)
        self.audioPlayer.play()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: "onUpdate", userInfo: nil, repeats: true)
    }
    
    func onUpdate(){
        let c = audioPlayer.currentPlaybackTime
        if c > 0.0{
            let t = audioPlayer.duration
            let p: CFloat = CFloat(c / t)
            progressView.setProgress(p, animated: true)
            
            let all: Int = Int(c)
            let m: Int = all % 60
            let f: Int = Int(all / 60)
            var time: String = ""
            if f < 10{
                time = "0\(f):"
            } else {
                time = "\(f):"
            }
            
            if m < 10{
                time += "0\(m)"
            } else {
                time += "\(m)"
            }
            playTime.text = time
        }
    }
    
    func onSetImage(url: String){
        let image = self.imageCache[url] as UIImage!
        if image == nil {
            let imgURL: NSURL = NSURL(string: url)
            let request: NSURLRequest = NSURLRequest(URL: imgURL)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!, data:NSData!, error: NSError!) -> Void in
                let img = UIImage(data: data)
                self.iv.image = img
                self.imageCache[url] = img
            })
        } else {
            self.iv.image = image
        }

    }

}

