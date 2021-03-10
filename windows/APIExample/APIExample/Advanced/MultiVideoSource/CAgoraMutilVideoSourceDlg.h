#pragma once
#include "AGVideoWnd.h"

class CVideoSourceObserver :
	public agora::media::IVideoFrameObserver
{
public:
	CVideoSourceObserver() {  }
	virtual ~CVideoSourceObserver() {  }
	/*
		Obtain video data from the local camera.After successfully registering
		a video data observer, the SDK triggers this callback when each video
		frame is captured. You can retrieve the video data from the local camera
		in the callback, and then pre-process the video data according to the needs
		of the scene.After the preprocessing is done, you can send the processed
		video data back to the SDK in this callback.
		annotations:
		If the video data type you get is RGBA, Agora does not support sending the
		processed RGBA data back to the SDK through this callback.
		parameter:
		videoFrame :VideoFramedata, see VideoFrame for more details
		return If the video pre-processing fails,whether to ignore the video frame:
		True: No ignore.
		False: Ignored, the frame data is not sent back to the SDK.
	*/
	virtual bool onCaptureVideoFrame(VideoFrame& videoFrame);
	/**
	 * Occurs each time the SDK receives a video frame sent by the remote user.
	 *
	 * After you successfully register the video frame observer, the SDK triggers this callback each time a
	 * video frame is received. In this callback, you can get the video data sent by the remote user. You
	 * can then post-process the data according to your scenarios.
	 *
	 * After post-processing, you can send the processed data back to the SDK by setting the `videoFrame`
	 * parameter in this callback.
	 *
	 * @param uid ID of the remote user who sends the current video frame.
	 * @param connectionId ID of the connection.
	 * @param videoFrame A pointer to the video frame: VideoFrame
	 * @return Determines whether to ignore the current video frame if the post-processing fails:
	 * - true: Do not ignore.
	 * - false: Ignore, in which case this method does not sent the current video frame to the SDK.
	 */
	virtual bool onRenderVideoFrame(rtc::uid_t uid, rtc::conn_id_t connectionId,
		VideoFrame& videoFrame) {
		return true;
	}

	virtual bool onScreenCaptureVideoFrame(VideoFrame& videoFrame)override;
	virtual bool onSecondaryCameraCaptureVideoFrame(VideoFrame& videoFrame)override { return true; }
	virtual bool onTranscodedVideoFrame(VideoFrame& videoFrame)override { return true; }
	virtual bool onSecondaryScreenCaptureVideoFrame(VideoFrame& videoFrame) override { return true; }
	virtual bool onMediaPlayerVideoFrame(VideoFrame& videoFrame, int mediaPlayerId) override { return true; }

};

class CAgoraMultiVideoSourceEventHandler : public agora::rtc::IRtcEngineEventHandler
{
public:
	//set the message notify window handler
	void SetMsgReceiver(HWND hWnd) { m_hMsgHanlder = hWnd; }

	int GetChannelId() { return m_channelId; };
	void SetChannelId(int id) { m_channelId = id; };

	std::string GetChannelName() { return m_strChannel; }
	/*
	note:
		Join the channel callback.This callback method indicates that the client
		successfully joined the specified channel.Channel ids are assigned based
		on the channel name specified in the joinChannel. If IRtcEngine::joinChannel
		is called without a user ID specified. The server will automatically assign one
	parameters:
		channel:channel name.
		uid: user ID。If the UID is specified in the joinChannel, that ID is returned here;
		Otherwise, use the ID automatically assigned by the Agora server.
		elapsed: The Time from the joinChannel until this event occurred (ms).
	*/
	virtual void onJoinChannelSuccess(const char* channel, agora::rtc::uid_t uid, int elapsed) override;
	/*
	note:
		In the live broadcast scene, each anchor can receive the callback
		of the new anchor joining the channel, and can obtain the uID of the anchor.
		Viewers also receive a callback when a new anchor joins the channel and
		get the anchor's UID.When the Web side joins the live channel, the SDK will
		default to the Web side as long as there is a push stream on the
		Web side and trigger the callback.
	parameters:
		uid: remote user/anchor ID for newly added channel.
		elapsed: The joinChannel is called from the local user to the delay triggered
		by the callback(ms).
	*/
	virtual void onUserJoined(agora::rtc::uid_t uid, int elapsed) override;
	/*
	note:
		Remote user (communication scenario)/anchor (live scenario) is called back from
		the current channel.A remote user/anchor has left the channel (or dropped the line).
		There are two reasons for users to leave the channel, namely normal departure and
		time-out:When leaving normally, the remote user/anchor will send a message like
		"goodbye". After receiving this message, determine if the user left the channel.
		The basis of timeout dropout is that within a certain period of time
		(live broadcast scene has a slight delay), if the user does not receive any
		packet from the other side, it will be judged as the other side dropout.
		False positives are possible when the network is poor. We recommend using the
		Agora Real-time messaging SDK for reliable drop detection.
	parameters:
		uid: The user ID of an offline user or anchor.
		reason:Offline reason: USER_OFFLINE_REASON_TYPE.
	*/
	virtual void onUserOffline(agora::rtc::uid_t uid, agora::rtc::USER_OFFLINE_REASON_TYPE reason) override;
	/*
	note:
		When the App calls the leaveChannel method, the SDK indicates that the App
		has successfully left the channel. In this callback method, the App can get
		the total call time, the data traffic sent and received by THE SDK and other
		information. The App obtains the call duration and data statistics received
		or sent by the SDK through this callback.
	parameters:
		stats: Call statistics.
	*/
	virtual void onLeaveChannel(const agora::rtc::RtcStats& stats) override;
	/**
		Occurs when the remote video state changes.
		@note This callback does not work properly when the number of users (in the Communication profile) or broadcasters (in the Live-broadcast profile) in the channel exceeds 17.

		@param uid ID of the remote user whose video state changes.
		@param state State of the remote video. See #REMOTE_VIDEO_STATE.
		@param reason The reason of the remote video state change. See
		#REMOTE_VIDEO_STATE_REASON.
		@param elapsed Time elapsed (ms) from the local user calling the
		\ref agora::rtc::IRtcEngine::joinChannel "joinChannel" method until the
		SDK triggers this callback.
	 */
	virtual void onRemoteVideoStateChanged(agora::rtc::uid_t uid, agora::rtc::REMOTE_VIDEO_STATE state, agora::rtc::REMOTE_VIDEO_STATE_REASON reason, int elapsed) override;


	/** Occurs when the connection state of the SDK to the server is changed.

	@param state See #CONNECTION_STATE_TYPE.
	@param reason See #CONNECTION_CHANGED_REASON_TYPE.
	*/
	void onConnectionStateChanged(CONNECTION_STATE_TYPE state, CONNECTION_CHANGED_REASON_TYPE reason)
	{
		if (m_hMsgHanlder) {
			::PostMessage(m_hMsgHanlder, WM_MSGID(EID_CONNECTION_STATE_CHANGED), reason, state);
		}
	}
private:
	HWND m_hMsgHanlder;
	std::string m_strChannel;
	int m_channelId;
};



class CAgoraMutilVideoSourceDlg : public CDialogEx
{
	DECLARE_DYNAMIC(CAgoraMutilVideoSourceDlg)

public:
	CAgoraMutilVideoSourceDlg(CWnd* pParent = nullptr);   
	virtual ~CAgoraMutilVideoSourceDlg();

	enum { IDD = IDD_DIALOG_MUTI_SOURCE };
	static const int VIDOE_COUNT = 2;
	//Initialize the Agora SDK
	bool InitAgora();
	//UnInitialize the Agora SDK
	void UnInitAgora();
	//set control text from config.
	void InitCtrlText();
	//render local video from SDK local capture.
	void RenderLocalVideo();
	// resume window status.
	void ResumeStatus();

	void StartDesktopShare();
private:
	bool m_joinChannel = false;
	bool m_initialize = false;

	std::string m_strChannel;

	agora::rtc::IRtcEngine* m_rtcEngine = nullptr;
	std::vector<CAgoraMultiVideoSourceEventHandler *> m_vecVidoeSourceEventHandler;
	conn_id_t m_conn_screen;
	conn_id_t m_conn_camera;
	
	bool m_bPublishScreen = false;
	CAGVideoWnd m_videoWnds[VIDOE_COUNT];
protected:
	virtual void DoDataExchange(CDataExchange* pDX);  
	// agora sdk message window handler
	afx_msg LRESULT OnEIDConnectionStateChanged(WPARAM wParam, LPARAM lParam);
	BOOL RegisterVideoFrameObserver(BOOL bEnable, IVideoFrameObserver * videoFrameObserver);
	LRESULT OnEIDJoinChannelSuccess(WPARAM wParam, LPARAM lParam);
	LRESULT OnEIDLeaveChannel(WPARAM wParam, LPARAM lParam);
	LRESULT OnEIDUserJoined(WPARAM wParam, LPARAM lParam);
	LRESULT OnEIDUserOffline(WPARAM wParam, LPARAM lParam);
	LRESULT OnEIDRemoteVideoStateChanged(WPARAM wParam, LPARAM lParam);
	DECLARE_MESSAGE_MAP()
public:
	CStatic m_staVideoArea;
	CListBox m_lstInfo;
	CStatic m_staChannel;
	CEdit m_edtChannel;
	CButton m_btnJoinChannel;
	CStatic m_staVideoSource;
	
	CButton m_btnPublish;
	CStatic m_staDetail;
	afx_msg void OnShowWindow(BOOL bShow, UINT nStatus);
	virtual BOOL OnInitDialog();
	virtual BOOL PreTranslateMessage(MSG* pMsg);
	afx_msg void OnBnClickedButtonJoinchannel();
	afx_msg void OnBnClickedButtonPublish();
	

	CVideoSourceObserver m_observer;
	
	CButton m_chkRawVideo;
	afx_msg void OnBnClickedCheckRawVideo();
};
