//
//  ViewController.swift
//  AVFoundation_Sample
//
//  Created by Harris on 2022/4/6.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {

    @IBOutlet weak var playImv: UIImageView!
    @IBOutlet weak var timeLab: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    var player:AVPlayer?
    var myPlayer: AVPlayerLayer?
    var playItem: AVPlayerItem?
    var myplayer: AVPlayerLayer?
    var status: AVPlayerItem.Status?
    var timeObserverToken: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGes = UITapGestureRecognizer.init(target: self, action: #selector(playVideo(_:)))
        playImv.isUserInteractionEnabled = true
        playImv.addGestureRecognizer(tapGes)
        playImv.image = UIImage(systemName: "play.circle.fill")
        playImv.tintColor = UIColor.systemGreen
        slider.setThumbImage(UIImage(systemName: "circle.fill"), for: .normal)
        slider.addTarget(self, action: #selector(changeSliderValue), for: .valueChanged)
        slider.addTarget(self, action: #selector(finalSliderValue), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderTouchDown), for: .touchDown)
        let file = Bundle.main.path(forResource: "123", ofType: "MP4")
//        let url = URL.init(fileURLWithPath: file!)
        let remoteURL = URL.init(string: "http://wxsnsdy.tc.qq.com/105/20210/snsdyvideodownload?filekey=30280201010421301f0201690402534804102ca905ce620b1241b726bc41dcff44e00204012882540400&bizid=1023&hy=SH&fileparam=302c020101042530230204136ffd93020457e3c4ff02024ef202031e8d7f02030f42400204045a320a0201000400")
        let asset = AVAsset.init(url: remoteURL!)
//        let asset = AVAsset.init(url: url)
        playItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playItem!)
        myplayer = AVPlayerLayer.init(player: player)
        myplayer!.frame = CGRect.init(x: 0, y: 100, width: UIScreen.main.bounds.size.width, height: 300)
        myplayer!.videoGravity = .resizeAspect
        view.layer.addSublayer(myplayer!)
        playItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new, .old], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playFinish), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        addTimeObserver()
    }
    
    func addTimeObserver() {
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 1, preferredTimescale: timeScale)
        timeObserverToken = player!.addPeriodicTimeObserver(forInterval:time, queue: .main) {
            [weak self] time in
            self!.timeLab.text = "\(self!.getCurrentTimeString())/\(self!.getTotalDurationString())"
            self!.slider.value = Float(self!.getCurrentTime() / self!.getTotalDuration())
        }
    }
    
    @objc func sliderTouchDown(sender: UISlider) {
        if let timeObserverToken = timeObserverToken {
            player!.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    func settingTimeLabel(value: Float) -> String {
        let totalSeconds = CMTimeGetSeconds(playItem!.duration)
        let current = Float(totalSeconds) * value
        let seconds = Int(current) % 60
        let minutes = Int(current) / 60
        let res = String(format: "%.2d:%.2d", minutes, seconds)
        return res
    }
    
    @objc func changeSliderValue(sender: UISlider) {
        let res = settingTimeLabel(value: sender.value)
        timeLab.text = "\(res)/\(getTotalDurationString())"
    }
    
    @objc func finalSliderValue(sender: UISlider) {
        let res = settingTimeLabel(value: sender.value)
        timeLab.text = "\(res)/\(getTotalDurationString())"
        slider.value = sender.value
        let current = Float(getTotalDuration()) * sender.value
        playItem?.seek(to: CMTime.init(value: CMTimeValue(600 * current), timescale: 600), completionHandler: { flag in
            self.addTimeObserver()
        })
    }
    
    @objc func playVideo(_ sender: Any) {
        if status == .unknown {
            print("unknown")
        } else if status == .readyToPlay {
            timeLab.text = "\(getCurrentTimeString())/\(getTotalDurationString())"
            if myplayer?.player?.rate == 0.0 {
                myplayer?.player?.play()
                playImv.image = UIImage(systemName: "pause.circle.fill")
            } else {
                myplayer?.player?.pause()
                playImv.image = UIImage(systemName: "play.circle.fill")
            }
        } else {
            print("failed")
        }
        
        
        
//        let controller = AVPlayerViewController()
//        controller.player = player
//        present(controller, animated: true) {
//            controller.player?.play()
//        }
        
        
        
    }
    
    
    
    
    func getTotalDuration() -> Double {
        return CMTimeGetSeconds(playItem!.duration)
    }
    
    func getTotalDurationString() -> String {
        let totalSeconds = getTotalDuration()
        let seconds = Int(totalSeconds) % 60
        let minutes = Int(totalSeconds) / 60
        let res = String(format: "%.2d:%.2d", minutes, seconds)
        return res
    }
    
    func getCurrentTime() -> Double {
        return CMTimeGetSeconds(playItem!.currentTime())
    }
    
    func getCurrentTimeString() -> String {
        let currentTime = getCurrentTime()
        let seconds = Int(currentTime) % 60
        let minutes = Int(currentTime) / 60
        let res = String(format: "%.2d:%.2d", minutes, seconds)
        return res
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            switch status {
            case .readyToPlay:
                timeLab.text = "\(getCurrentTimeString())/\(getTotalDurationString())"
            case .failed:
                print("failed")
            case .unknown:
                print("unknown")
            case .none:
                print("none")
            @unknown default:
                print("default")
            }
        }
    }
    
    
    @objc func playFinish(noty: Notification) {
        let playItem = noty.object as! AVPlayerItem
        playItem.seek(to: CMTime.init(value: 0, timescale: 1))
        slider.value = 0
        player?.pause()
        playImv.image = UIImage(systemName: "play.circle.fill")
    }
    
    
    

}

