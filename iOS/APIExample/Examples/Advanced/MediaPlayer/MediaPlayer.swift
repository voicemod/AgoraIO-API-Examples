//
//  JoinChannelVC.swift
//  APIExample
//
//  Created by 张乾泽 on 2020/4/17.
//  Copyright © 2020 Agora Corp. All rights reserved.
//
import UIKit
import AGEVideoLayout
import AgoraRtcKit
//TODO
//#if false

class MediaPlayerEntry : UIViewController
{
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var channelTextField: UITextField!
    let identifier = "MediaPlayer"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func doJoinPressed(sender: UIButton) {
        guard let channelName = channelTextField.text else {return}
        //resign channel text field
        channelTextField.resignFirstResponder()
        
        let storyBoard: UIStoryboard = UIStoryboard(name: identifier, bundle: nil)
        // create new view controller every time to ensure we get a clean vc
        guard let newViewController = storyBoard.instantiateViewController(withIdentifier: identifier) as? BaseViewController else {return}
        newViewController.title = channelName
        newViewController.configs = ["channelName":channelName]
        self.navigationController?.pushViewController(newViewController, animated: true)
    }
    
}

class MediaPlayerMain: BaseViewController {
    var localVideo = Bundle.loadView(fromNib: "VideoView", withType: VideoView.self)
    var remoteVideo = Bundle.loadView(fromNib: "VideoView", withType: VideoView.self)
    
    @IBOutlet weak var container: AGEVideoContainer!
    @IBOutlet weak var mediaUrlField: UITextField!
    @IBOutlet weak var playerControlStack: UIStackView!
    @IBOutlet weak var playerProgressSlider: UISlider!
    @IBOutlet weak var playerVolumeSlider: UISlider!
    @IBOutlet weak var playerDurationLabel: UILabel!
    var agoraKit: AgoraRtcEngineKit!
    var mediaPlayerKit: AgoraRtcMediaPlayerProtocol!
    var timer:Timer?
    private lazy var channelMediaOptions = AgoraRtcChannelMediaOptions()
    // indicate if current instance has joined channel
    var isJoined: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // layout render view
        localVideo.setPlaceholder(text: "No Player Loaded")
        remoteVideo.setPlaceholder(text: "Remote Host".localized)
        container.layoutStream1x2(views: [localVideo,remoteVideo])
        // set up agora instance when view loaded
        let config = AgoraRtcEngineConfig()
        config.appId = KeyCenter.AppId
        config.areaCode = GlobalSettings.shared.area
        config.channelProfile = .liveBroadcasting
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraKit.setLogFile(LogUtils.sdkLogPath())
        
        // get channel name from configs
        guard let channelName = configs["channelName"] as? String else {return}
        
        // become a live broadcaster
        agoraKit.setClientRole(.broadcaster)
        
        // enable video module and set up video encoding configs
        agoraKit.enableVideo()
        agoraKit.setVideoEncoderConfiguration(AgoraVideoEncoderConfiguration(size: AgoraVideoDimension640x360,
                                                                             frameRate: .fps30,
                                                                             bitrate: AgoraVideoBitrateStandard,
                                                                             orientationMode: .adaptative, mirrorMode: .auto))
        mediaPlayerKit = agoraKit.createMediaPlayer(with: self)
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        // the view to be binded
        videoCanvas.view = localVideo.videoView
        videoCanvas.renderMode = .hidden
        agoraKit.setupLocalVideo(videoCanvas)
        // you have to call startPreview to see local video
        agoraKit.startPreview()
        agoraKit.setVideoFrameDelegate(self)
        // start joining channel
        // 1. Users can only see each other after they join the
        // same channel successfully using the same app id.
        // 2. If app certificate is turned on at dashboard, token is needed
        // when joining channel. The channel name and uid used to calculate
        // the token has to match the ones used for channel join
        let result = agoraKit.joinChannel(byToken: nil, channelId: channelName, info: nil, uid: 0) {[unowned self] (channel, uid, elapsed) -> Void in
            self.isJoined = true
            LogUtils.log(message: "Join \(channel) with uid \(uid) elapsed \(elapsed)ms", level: .info)
        }
        if result != 0 {
            // Usually happens with invalid parameters
            // Error code description can be found at:
            // en: https://docs.agora.io/en/Voice/API%20Reference/oc/Constants/AgoraErrorCode.html
            // cn: https://docs.agora.io/cn/Voice/API%20Reference/oc/Constants/AgoraErrorCode.html
            self.showAlert(title: "Error", message: "joinChannel call failed: \(result), please check your params")
        }
    }
    
    @IBAction func doOpenMediaUrl(sender: UIButton) {
        guard let url = mediaUrlField.text else {return}
        //resign text field
        mediaUrlField.resignFirstResponder()
        mediaPlayerKit.open(url, startPos: 0)
    }
    
    @IBAction func doPlay(sender: UIButton) {
        mediaPlayerKit.play()
    }
    
    @IBAction func doStop(sender: UIButton) {
        mediaPlayerKit.stop()
    }
    
    @IBAction func doPause(sender: UIButton) {
        mediaPlayerKit.pause()
    }
    
    @IBAction func doResume(sender: UIButton) {
        mediaPlayerKit.resume()
    }
    
    @IBAction func doPublish(sender: UIButton) {
        agoraKit.stopPreview()
        channelMediaOptions.clientRoleType = .broadcaster
        channelMediaOptions.publishCameraTrack = false
        channelMediaOptions.publishAudioTrack  = false
        channelMediaOptions.enableAudioRecordingOrPlayout = false
        channelMediaOptions.publishMediaPlayerId = self.mediaPlayerKit.getMediaPlayerId()
        channelMediaOptions.publishMediaPlayerVideoTrack = true
        channelMediaOptions.publishMediaPlayerAudioTrack = true
        mediaPlayerKit.play()
        self.mediaPlayerKit.setView(self.localVideo.videoView)
        self.agoraKit.updateChannel(with: channelMediaOptions)
    }
    
    @IBAction func doUnpublish(sender: UIButton) {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        // the view to be binded
        videoCanvas.view = localVideo.videoView
        videoCanvas.renderMode = .hidden
        agoraKit.setupLocalVideo(videoCanvas)
        agoraKit.startPreview()
        mediaPlayerKit.pause()
        channelMediaOptions.clientRoleType = .broadcaster
        channelMediaOptions.publishMediaPlayerVideoTrack = false
        channelMediaOptions.publishMediaPlayerAudioTrack = false
        channelMediaOptions.publishCameraTrack = true
        self.agoraKit.updateChannel(with: channelMediaOptions)
    }
    
    @IBAction func doSeek(sender: UISlider) {
        mediaPlayerKit.seek(toPosition: Int(sender.value * Float(mediaPlayerKit.getDuration())))
    }
    
    @IBAction func doAdjustPlayoutVolume(sender: UISlider) {
        mediaPlayerKit.adjustPlayoutVolume(Int32(sender.value))
    }
    
    @IBAction func doAdjustPublishVolume(sender: UISlider) {
        mediaPlayerKit.adjustPublishSignalVolume(Int32(sender.value))
    }
    
    func startProgressTimer() {
        // begin timer to update progress
        if(timer == nil) {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self](timer:Timer) in
                guard let weakself = self else {return}
                let progress = Float(weakself.mediaPlayerKit.getPosition()) / Float(weakself.mediaPlayerKit.getDuration())
                if(!weakself.playerProgressSlider.isTouchInside) {
                    weakself.playerProgressSlider.setValue(progress, animated: true)
                }
            })
        }
    }
    
    func stopProgressTimer() {
        // stop timer
        if(timer != nil) {
            timer?.invalidate()
            timer = nil
        }
    }
    
    override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            // leave channel when exiting the view
            // deregister packet processing
            
            AgoraCustomEncryption.deregisterPacketProcessing(agoraKit)
            if isJoined {
                agoraKit.destroyMediaPlayer(mediaPlayerKit)
                agoraKit.leaveChannel { (stats) -> Void in
                    LogUtils.log(message: "left channel, duration: \(stats.duration)", level: .info)
                }
            }
        }
    }
}

extension MediaPlayerMain:AgoraVideoFrameDelegate {
    func onTranscodedVideoFrame(_ videoFrame: AgoraOutputVideoFrame) -> Bool {
        return false
    }
    
    func onCapture(_ videoFrame: AgoraOutputVideoFrame) -> Bool {
        return false
    }
    
    func onScreenCapture(_ videoFrame: AgoraOutputVideoFrame) -> Bool {
        return false
    }
    
    func onRenderVideoFrame(_ videoFrame: AgoraOutputVideoFrame, uid: UInt, connectionId: UInt) -> Bool {
        return false
    }
    
    func onMediaPlayerVideoFrame(_ videoFrame: AgoraOutputVideoFrame, mediaPlayerId: Int32) -> Bool {
        return false
    }
}
/// agora rtc engine delegate events
extension MediaPlayerMain: AgoraRtcEngineDelegate {
    /// callback when warning occured for agora sdk, warning can usually be ignored, still it's nice to check out
    /// what is happening
    /// Warning code description can be found at:
    /// en: https://docs.agora.io/en/Voice/API%20Reference/oc/Constants/AgoraWarningCode.html
    /// cn: https://docs.agora.io/cn/Voice/API%20Reference/oc/Constants/AgoraWarningCode.html
    /// @param warningCode warning code of the problem
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        LogUtils.log(message: "warning: \(warningCode.description)", level: .warning)
    }
    
    /// callback when error occured for agora sdk, you are recommended to display the error descriptions on demand
    /// to let user know something wrong is happening
    /// Error code description can be found at:
    /// en: https://docs.agora.io/en/Voice/API%20Reference/oc/Constants/AgoraErrorCode.html
    /// cn: https://docs.agora.io/cn/Voice/API%20Reference/oc/Constants/AgoraErrorCode.html
    /// @param errorCode error code of the problem
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        LogUtils.log(message: "error: \(errorCode)", level: .error)
        self.showAlert(title: "Error", message: "Error \(errorCode.description) occur")
    }
    
    /// callback when a remote user is joinning the channel, note audience in live broadcast mode will NOT trigger this event
    /// @param uid uid of remote joined user
    /// @param elapsed time elapse since current sdk instance join the channel in ms
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        LogUtils.log(message: "remote user join: \(uid) \(elapsed)ms", level: .info)
        
        // Only one remote video view is available for this
        // tutorial. Here we check if there exists a surface
        // view tagged as this uid.
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        // the view to be binded
        videoCanvas.view = remoteVideo.videoView
        videoCanvas.renderMode = .hidden
        agoraKit.setupRemoteVideo(videoCanvas)
    }
    
    /// callback when a remote user is leaving the channel, note audience in live broadcast mode will NOT trigger this event
    /// @param uid uid of remote joined user
    /// @param reason reason why this user left, note this event may be triggered when the remote user
    /// become an audience in live broadcasting profile
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        LogUtils.log(message: "remote user left: \(uid) reason \(reason)", level: .info)
        
        // to unlink your view from sdk, so that your view reference will be released
        // note the video will stay at its last frame, to completely remove it
        // you will need to remove the EAGL sublayer from your binded view
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        // the view to be binded
        videoCanvas.view = nil
        videoCanvas.renderMode = .hidden
        agoraKit.setupRemoteVideo(videoCanvas)
    }
}

extension MediaPlayerMain: AgoraRtcMediaPlayerDelegate
{
    func agoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
        LogUtils.log(message: "media player state changed to: \(state.rawValue), error: \(error.rawValue)", level: .info)
        
        DispatchQueue.main.async {[weak self] in
            guard let weakself = self else {return}
            switch state {
            case .failed:
                weakself.showAlert(message: "media player error: \(error.rawValue)")
                break
            case .openCompleted:
                let duration = weakself.mediaPlayerKit.getDuration()
                weakself.playerControlStack.isHidden = false
                weakself.playerDurationLabel.text = "\(String(format: "%02d", duration / 60)) : \(String(format: "%02d", duration % 60))"
                weakself.agoraKit.stopPreview()
                let videoCanvas = AgoraRtcVideoCanvas()
                videoCanvas.uid = 0
                // the view to be binded
                videoCanvas.view = weakself.localVideo.videoView
                videoCanvas.renderMode = .hidden
                videoCanvas.sourceType = .mediaPlayer
                videoCanvas.sourceId = weakself.mediaPlayerKit.getMediaPlayerId()
                weakself.mediaPlayerKit.setView(weakself.localVideo.videoView)
                weakself.agoraKit.setupLocalVideo(videoCanvas)
                break
            case .stopped:
                weakself.playerControlStack.isHidden = true
//                weakself.stopProgressTimer()
                break
            case .opening: break
            case .playing:
//                weakself.startProgressTimer()
                break
            case .paused:
//                weakself.stopProgressTimer()
                break;
            case .playBackCompleted:
//                weakself.stopProgressTimer()
                break
            default: break
            }
        }
    }
    
    func agoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedToPosition position: Int) {
        let progress = Float(position) / Float(self.mediaPlayerKit.getDuration())
        DispatchQueue.main.async {[weak self] in
            guard let weakself = self else {return}
        if(!weakself.playerProgressSlider.isTouchInside) {
            weakself.playerProgressSlider.setValue(progress, animated: true)
        }
        }
    }
}
//#endif
