//
//  VideoChat.swift
//  APIExample
//
//  Created by XC on 2021/1/12.
//  Copyright © 2021 Agora Corp. All rights reserved.
//

import UIKit
import AgoraRtcKit
import AGEVideoLayout

enum VideoLayout {
    case grid2x3
    case framework
    func description() -> String {
        switch self {
        case .grid2x3:
            return "2x3 Grid Layout".localized
        case .framework:
            return "Frame Layout".localized
        }
    }
}

class VideoChatEntry: UIViewController {
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var channelTextField: UITextField!
    let identifier = "VideoChat"
    @IBOutlet var layoutBtn: UIButton!
    var layoutType:VideoLayout = .grid2x3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutBtn.setTitle(layoutType.description(), for: .normal)
    }
    
    func getLayoutAction(_ layout:VideoLayout) -> UIAlertAction{
        return UIAlertAction(title: layout.description(), style: .default, handler: {[unowned self] action in
            self.layoutType = layout
            self.layoutBtn.setTitle(layoutType.description(), for: .normal)
        })
    }
    
    @IBAction func setLayoutType() {
        let alert = UIAlertController(title: "Set Layout Type".localized, message: nil, preferredStyle: UIDevice.current.userInterfaceIdiom == .pad ? UIAlertController.Style.alert : UIAlertController.Style.actionSheet)
        alert.addAction(getLayoutAction(.grid2x3))
        alert.addAction(getLayoutAction(.framework))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func doJoinPressed(sender: UIButton) {
        guard let channelName = channelTextField.text else {return}
        //resign channel text field
        channelTextField.resignFirstResponder()
        
        let storyBoard: UIStoryboard = UIStoryboard(name: identifier, bundle: nil)
        // create new view controller every time to ensure we get a clean vc
        guard let newViewController = storyBoard.instantiateViewController(withIdentifier: identifier) as? BaseViewController else { return }
        newViewController.title = channelName
        newViewController.configs = ["channelName": channelName, "layoutType": layoutType]
        self.navigationController?.pushViewController(newViewController, animated: true)
    }
}

class VideoChatMain: BaseViewController {
    var agoraKit: AgoraRtcEngineKit!
    @IBOutlet weak var containerView: AGEVideoContainer!
    var videoViews: [UInt:VideoView] = [:]
    
    // indicate if current instance has joined channel
    var isJoined: Bool = false
    
    override func viewDidLoad(){
        super.viewDidLoad()
        containerView.delegate = self
        // set up agora instance when view loadedlet config = AgoraRtcEngineConfig()
        let config = AgoraRtcEngineConfig()
        config.appId = KeyCenter.AppId
        config.areaCode = GlobalSettings.shared.area.rawValue
        // setup log file path
        let logConfig = AgoraLogConfig()
        logConfig.level = .info
        config.logConfig = logConfig
        
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        
        // get channel name from configs
        guard let channelName = configs["channelName"] as? String,
              let resolution = GlobalSettings.shared.getSetting(key: "resolution")?.selectedOption().value as? CGSize,
              let fps = GlobalSettings.shared.getSetting(key: "fps")?.selectedOption().value as? AgoraVideoFrameRate,
              let orientation = GlobalSettings.shared.getSetting(key: "orientation")?.selectedOption().value as? AgoraVideoOutputOrientationMode else {return}
        
        // make myself a broadcaster
        agoraKit.setChannelProfile(.liveBroadcasting)
        agoraKit.setClientRole(.broadcaster)
        
        // enable video module
        agoraKit.enableVideo()
        agoraKit.setVideoEncoderConfiguration(
            AgoraVideoEncoderConfiguration(
                size: resolution,
                frameRate: fps,
                bitrate: AgoraVideoBitrateStandard,
                orientationMode: orientation
            )
        )
        /**
         To minimize bandwidth consumption and ensure smooth communication in a video scenario with multiple users, Agora recommends the following:

         All publishers enable dual-stream mode.
         Every subscriber receives the high-quality video stream of only one publisher, and the low-quality stream of the other publishers.
         */
        agoraKit.enableDualStreamMode(true)
        // set up local video to render your local camera preview
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        
        let localVideo = Bundle.loadVideoView(type: .local, audioOnly: false)
        // the view to be binded
        videoCanvas.view = localVideo.videoView
        videoCanvas.renderMode = .hidden
        agoraKit.setupLocalVideo(videoCanvas)
        
        videoViews[0] = localVideo
        setVideoLayout()
        
        // Set audio route to speaker
        agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        
        // start joining channel
        // 1. Users can only see each other after they join the
        // same channel successfully using the same app id.
        // 2. If app certificate is turned on at dashboard, token is needed
        // when joining channel. The channel name and uid used to calculate
        // the token has to match the ones used for channel join
        let option = AgoraRtcChannelMediaOptions()
        let result = agoraKit.joinChannel(byToken: KeyCenter.Token, channelId: channelName, info: nil, uid: 0, options: option)
        if result != 0 {
            // Usually happens with invalid parameters
            // Error code description can be found at:
            // en: https://docs.agora.io/en/Voice/API%20Reference/oc/Constants/AgoraErrorCode.html
            // cn: https://docs.agora.io/cn/Voice/API%20Reference/oc/Constants/AgoraErrorCode.html
            self.showAlert(title: "Error", message: "joinChannel call failed: \(result), please check your params")
        }
    }
    
    override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            // leave channel when exiting the view
            if isJoined {
                agoraKit.leaveChannel { (stats) -> Void in
                    LogUtils.log(message: "left channel, duration: \(stats.duration)", level: .info)
                }
            }
        }
    }
    
    func cleanStickyVideo() {
        videoViews.values.forEach({
            $0.sticky = false
            agoraKit.setRemoteVideoStream($0.uid, type: .low)
        })
    }
    
    func sortedViews() -> [VideoView] {
        return Array(videoViews.values).sorted(by: { $0.sticky || $0.uid < $1.uid })
    }
    
    func setVideoLayout() {
        switch configs["layoutType"] as? VideoLayout {
        case .grid2x3:
            setGridLayout()
        case .framework:
            setFrameLayout()
        default:
            setGridLayout()
        }
    }
    
    
    func setGridLayout() {
        // layout render view
        containerView.removeAllLayouts()
        containerView.layoutStream2x3(views: sortedViews())
    }
    
    func setFrameLayout() {
        let list = sortedViews()
        let fullLayout = AGEVideoLayout(level: 0)
            .startPoint(x: 0, y: 0)
            .size(.scale(CGSize(width: 1, height: 1)))
            .itemSize(.scale(CGSize(width: 1, height: 1)))
        

        let scrollLayout = AGEVideoLayout(level: 1)
            .scrollType(.scroll(.vertical))
            .startPoint(x: 30, y: 30)
            .size(.constant(CGSize(width: 120, height: self.containerView.bounds.height - 30)))
            .itemSize(.constant(CGSize(width: 120, height: 90)))

        containerView
            .listCount { (level: Int) -> Int in
                if level == 0 {
                    return 1
                } else {
                    return list.count - 1
                }
            }.listItem({ (index) -> AGEView in
                if index.level == 0 {
                    return list[index.item]
                } else {
                    return list[index.item + 1]
                }
            })
        containerView.removeAllLayouts()
        containerView.setLayouts([fullLayout, scrollLayout], animated: false)
    }
    
}

/// agora rtc engine delegate events
extension VideoChatMain: AgoraRtcEngineDelegate {
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
    
    /// callback when the local user joins a specified channel.
    /// @param channel
    /// @param uid uid of local user
    /// @param elapsed time elapse since current sdk instance join the channel in ms
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        isJoined = true
        LogUtils.log(message: "Join \(channel) with uid \(uid) elapsed \(elapsed)ms", level: .info)
        //videoViews[0]?.uid = uid
    }
    
    /// callback when a remote user is joinning the channel, note audience in live broadcast mode will NOT trigger this event
    /// @param uid uid of remote joined user
    /// @param elapsed time elapse since current sdk instance join the channel in ms
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        LogUtils.log(message: "remote user join: \(uid) \(elapsed)ms", level: .info)
        
        let remoteVideo = Bundle.loadVideoView(type: .remote, audioOnly: false)
        remoteVideo.uid = uid
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        // the view to be binded
        videoCanvas.view = remoteVideo.videoView
        videoCanvas.renderMode = .hidden
        
        switch configs["layoutType"] as? VideoLayout {
        case .grid2x3:
            agoraKit.setRemoteVideoStream(uid, type: .high)
        case .framework:
            agoraKit.setRemoteVideoStream(uid, type: .low)
        default:
            agoraKit.setRemoteVideoStream(uid, type: .high)
        }
        agoraKit.setupRemoteVideo(videoCanvas)
        
        self.videoViews[uid] = remoteVideo
        setVideoLayout()
    }
    
    /// callback when a remote user is leaving the channel, note audience in live broadcast mode will NOT trigger this event
    /// @param uid uid of remote joined user
    /// @param reason reason why this user left, note this event may be triggered when the remote user
    /// become an audience in live broadcasting profile
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        LogUtils.log(message: "remote user left: \(uid) reason \(reason)", level: .info)
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        // the view to be binded
        videoCanvas.view = nil
        videoCanvas.renderMode = .hidden
        agoraKit.setupRemoteVideo(videoCanvas)
        
        //remove remote audio view
        self.videoViews.removeValue(forKey: uid)
        setVideoLayout()
    }
    
    /// Reports which users are speaking, the speakers' volumes, and whether the local user is speaking.
    /// @params speakers volume info for all speakers
    /// @params totalVolume Total volume after audio mixing. The value range is [0,255].
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        for volumeInfo in speakers {
            if let videoView = videoViews[volumeInfo.uid] {
                videoView.setInfo(text: "Volume:\(volumeInfo.volume)")
            }
        }
    }
    
    /// Reports the statistics of the current call. The SDK triggers this callback once every two seconds after the user joins the channel.
    /// @param stats stats struct
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportRtcStats stats: AgoraChannelStats) {
        videoViews[0]?.statsInfo?.updateChannelStats(stats)
    }
    
    /// Reports the statistics of the uploading local video streams once every two seconds.
    /// @param stats stats struct
    func rtcEngine(_ engine: AgoraRtcEngineKit, localVideoStats stats: AgoraRtcLocalVideoStats) {
        videoViews[0]?.statsInfo?.updateLocalVideoStats(stats)
    }
    
    /// Reports the statistics of the uploading local audio streams once every two seconds.
    /// @param stats stats struct
    func rtcEngine(_ engine: AgoraRtcEngineKit, localAudioStats stats: AgoraRtcLocalAudioStats) {
        videoViews[0]?.statsInfo?.updateLocalAudioStats(stats)
    }
    
    /// Reports the statistics of the video stream from each remote user/host.
    /// @param stats stats struct
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStats stats: AgoraRtcRemoteVideoStats) {
        videoViews[stats.uid]?.statsInfo?.updateVideoStats(stats)
    }
    
    /// Reports the statistics of the audio stream from each remote user/host.
    /// @param stats stats struct for current call statistics
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteAudioStats stats: AgoraRtcRemoteAudioStats) {
        videoViews[stats.uid]?.statsInfo?.updateAudioStats(stats)
    }
}

extension VideoChatMain: AGEVideoContainerDelegate {
    func container(_ container: AGEVideoContainer, didSelected itemView: AGEView, index: AGEIndex) {
        if index.level == 1 {
            print(index.description)
            cleanStickyVideo()
            (itemView as! VideoView).sticky = true
            agoraKit.setRemoteVideoStream((itemView as! VideoView).uid, type: .high)
            setFrameLayout()
        }
    }
}
