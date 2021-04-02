package io.agora.api.example.examples.advanced;

import static io.agora.api.example.common.model.Examples.ADVANCED;
import static io.agora.rtc2.Constants.VideoSourceType.VIDEO_SOURCE_CAMERA_PRIMARY;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.SurfaceView;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.View.OnTouchListener;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.SeekBar;
import android.widget.SeekBar.OnSeekBarChangeListener;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.agora.api.example.R;
import io.agora.api.example.annotation.Example;
import io.agora.api.example.common.BaseFragment;
import io.agora.extension.ExtensionManager;
import io.agora.extension.ResourceHelper;
import io.agora.extension.UtilsAsyncTask;
import io.agora.rtc2.Constants;
import io.agora.rtc2.IAgoraEventHandler;
import io.agora.rtc2.IRtcEngineEventHandler;
import io.agora.rtc2.RtcEngine;
import io.agora.rtc2.RtcEngineConfig;
import io.agora.rtc2.video.VideoCanvas;
import io.agora.rtc2.video.VideoEncoderConfiguration;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * 主要介绍如何对接美颜功能。
 */
@Example(
    index = 1617247071,
    group = ADVANCED,
    name = R.string.item_beauty,
    actionId = R.id.action_mainFragment_to_beauty,
    tipsId = R.string.beauty
)
public class Beauty extends BaseFragment implements OnClickListener, OnSeekBarChangeListener,
    UtilsAsyncTask.OnUtilsAsyncTaskEvents, io.agora.rtc2.IMediaExtensionObserver {

  private Button btCompare;
  private SeekBar seekBar;
  private FrameLayout flLocal;
  private TextView tvMsg;

  private RtcEngine mRtcEngine;
  private IAgoraEventHandler mIAgoraEventHandler = new IRtcEngineEventHandler() {

  };

  @Nullable
  @Override
  public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
      @Nullable Bundle savedInstanceState) {
    return inflater.inflate(R.layout.fragment_beauty, container, false);
  }

  @Override
  public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
    super.onViewCreated(view, savedInstanceState);
    btCompare = view.findViewById(R.id.btCompare);
    seekBar = view.findViewById(R.id.seekBar);
    flLocal = view.findViewById(R.id.flLocal);
    tvMsg = view.findViewById(R.id.tvMsg);

    btCompare.setOnTouchListener(new OnTouchListener() {
      @Override
      public boolean onTouch(View v, MotionEvent event) {
        if (event.getAction() == MotionEvent.ACTION_DOWN) {
          disableEffect();
        } else if (event.getAction() == MotionEvent.ACTION_UP) {
          enableEffect();
        } else if (event.getAction() == MotionEvent.ACTION_CANCEL) {
          enableEffect();
        }
        return true;
      }
    });
    seekBar.setOnSeekBarChangeListener(this);
  }

  @Override
  public void onActivityCreated(@Nullable Bundle savedInstanceState) {
    super.onActivityCreated(savedInstanceState);

    initRtcEngineSDK();
    checkResource();

    startPlay();
  }

  private void initRtcEngineSDK() {
    RtcEngineConfig config = new RtcEngineConfig();
    /**
     * The context of Android Activity
     */
    config.mContext = requireContext().getApplicationContext();
    /**
     * The App ID issued to you by Agora. See <a href="https://docs.agora.io/en/Agora%20Platform/token#get-an-app-id"> How to get the App ID</a>
     */
    config.mAppId = getString(R.string.agora_app_id);
    /** Sets the channel profile of the Agora RtcEngine.
     CHANNEL_PROFILE_COMMUNICATION(0): (Default) The Communication profile.
     Use this profile in one-on-one calls or group calls, where all users can talk freely.
     CHANNEL_PROFILE_LIVE_BROADCASTING(1): The Live-Broadcast profile. Users in a live-broadcast
     channel have a role as either broadcaster or audience. A broadcaster can both send and receive streams;
     an audience can only receive streams.*/
    config.mChannelProfile = Constants.CHANNEL_PROFILE_LIVE_BROADCASTING;
    /**
     * IRtcEngineEventHandler is an abstract class providing default implementation.
     * The SDK uses this class to report to the app on SDK runtime events.
     */
    config.mEventHandler = mIAgoraEventHandler;
    config.mAudioScenario = Constants.AudioScenario
        .getValue(Constants.AudioScenario.HIGH_DEFINITION);
    long provider = ExtensionManager
        .nativeGetExtensionProvider(requireContext(), ExtensionManager.VENDOR_NAME);
    config.addExtension(ExtensionManager.VENDOR_NAME, provider);
    config.mExtensionObserver = this;

    try {
      mRtcEngine = RtcEngine.create(config);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  private void startPlay() {
    SurfaceView view = RtcEngine.CreateRendererView(requireContext());
    view.setZOrderMediaOverlay(true);
    flLocal.addView(view);

    mRtcEngine.setupLocalVideo(new VideoCanvas(view, VideoCanvas.RENDER_MODE_HIDDEN, 0));
    mRtcEngine.setLocalRenderMode(Constants.RENDER_MODE_HIDDEN);

    VideoEncoderConfiguration configuration = new VideoEncoderConfiguration(640, 360,
        VideoEncoderConfiguration.FRAME_RATE.FRAME_RATE_FPS_30,
        VideoEncoderConfiguration.STANDARD_BITRATE,
        VideoEncoderConfiguration.ORIENTATION_MODE.ORIENTATION_MODE_ADAPTIVE);
    mRtcEngine.setVideoEncoderConfiguration(configuration);
    mRtcEngine.setChannelProfile(Constants.CHANNEL_PROFILE_LIVE_BROADCASTING);
    mRtcEngine.setClientRole(Constants.CLIENT_ROLE_BROADCASTER);
    mRtcEngine.enableLocalVideo(true);
    mRtcEngine.enableVideo();
    mRtcEngine.enableAudio();
    mRtcEngine.joinChannel("", "Test", "", 0);
    mRtcEngine.startPreview();
  }

  private void checkResource() {
    if (!ResourceHelper.isResourceReady(requireContext(), 1)) {
      onPrepareStatus();
      new UtilsAsyncTask(requireContext(), this).execute();
    } else {
      onCompletedStatus();
    }
  }

  private void onPrepareStatus() {
    tvMsg.setText("正在加载资源，请等待。。。");
    tvMsg.setVisibility(View.VISIBLE);
    disableEffect();
    btCompare.setEnabled(false);
    seekBar.setEnabled(false);
  }

  private void onCompletedStatus() {
    tvMsg.setText("");
    tvMsg.setVisibility(View.GONE);
    enableEffect();
    btCompare.setEnabled(true);
    seekBar.setEnabled(true);
  }

  private boolean isEnableEffect = false;

  private void enableEffect() {
    if (isEnableEffect) {
      return;
    }

    JSONObject o = new JSONObject();
    try {
      o.put("plugin.bytedance.licensePath", ResourceHelper.getLicensePath(requireContext()));
      o.put("plugin.bytedance.modelDir", ResourceHelper.getModelDir(requireContext()));
      o.put("plugin.bytedance.aiEffectEnabled", true);

      o.put("plugin.bytedance.faceAttributeEnabled", true);
      o.put("plugin.bytedance.faceDetectModelPath",
          ResourceHelper.getFaceModelPath(requireContext()));
      o.put("plugin.bytedance.faceAttributeModelPath",
          ResourceHelper.getFaceAttriModelPath(requireContext()));

      o.put("plugin.bytedance.faceStickerEnabled", true);
      o.put("plugin.bytedance.faceStickerItemResourcePath",
          ResourceHelper.getStickerPath(requireContext(), "leisituer"));

      o.put("plugin.bytedance.handDetectEnabled", true);
      o.put("plugin.bytedance.handDetectModelPath",
          ResourceHelper.getHandModelPath(requireContext(), ResourceHelper.DetectParamFile));
      o.put("plugin.bytedance.handBoxModelPath",
          ResourceHelper.getHandModelPath(requireContext(), ResourceHelper.BoxRegParamFile));
      o.put("plugin.bytedance.handGestureModelPath",
          ResourceHelper.getHandModelPath(requireContext(), ResourceHelper.GestureParamFile));
      o.put("plugin.bytedance.handKPModelPath",
          ResourceHelper.getHandModelPath(requireContext(), ResourceHelper.KeyPointParamFile));

      JSONObject node1 = new JSONObject();
      node1.put("path", ResourceHelper.getComposePath(requireContext()) + "beauty_Android_live");
      node1.put("key", "smooth");
      node1.put("intensity", 0.5f);

      mRtcEngine
          .setExtensionProperty(VIDEO_SOURCE_CAMERA_PRIMARY, ExtensionManager.VENDOR_NAME, "key",
              o.toString());

      isEnableEffect = true;
    } catch (JSONException e) {
      e.printStackTrace();
    }
  }

  private void disableEffect() {
    if (isEnableEffect == false) {
      return;
    }

    JSONObject o = new JSONObject();
    try {
      o.put("plugin.bytedance.aiEffectEnabled", false);
      o.put("plugin.bytedance.faceAttributeEnabled", false);
      o.put("plugin.bytedance.faceStickerEnabled", false);
      o.put("plugin.bytedance.handDetectEnabled", false);
      mRtcEngine
          .setExtensionProperty(VIDEO_SOURCE_CAMERA_PRIMARY, ExtensionManager.VENDOR_NAME, "key",
              o.toString());

      isEnableEffect = false;
    } catch (JSONException e) {
      e.printStackTrace();
    }
  }

  @Override
  public void onClick(View v) {

  }

  @Override
  public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
    if (fromUser) {
      JSONObject o = new JSONObject();
      try {

        JSONObject node1 = new JSONObject();
        node1.put("path", ResourceHelper.getComposePath(requireContext()) + "beauty_Android_live");
        node1.put("key", "smooth");
        node1.put("intensity", progress / 100F);

        JSONArray arr = new JSONArray();
        arr.put(node1);
        o.put("plugin.bytedance.ai.composer.nodes", arr);
      } catch (JSONException e) {
        e.printStackTrace();
      }

      mRtcEngine
          .setExtensionProperty(VIDEO_SOURCE_CAMERA_PRIMARY, ExtensionManager.VENDOR_NAME, "key",
              o.toString());
    }
  }

  @Override
  public void onStartTrackingTouch(SeekBar seekBar) {

  }

  @Override
  public void onStopTrackingTouch(SeekBar seekBar) {

  }

  @Override
  public void onPreExecute() {

  }

  @Override
  public void onPostExecute() {
    ResourceHelper.setResourceReady(requireContext(), true, 1);
    onCompletedStatus();
  }

  @Override
  public void onEvent(String vendor, String key, String value) {
    try {
      JSONObject o = new JSONObject(value);
      if (o.has("plugin.bytedance.light.info")) {

      }

      if (o.has("plugin.bytedance.hand.info")) {

      }

      if (o.has("plugin.bytedance.face.info")) {

      }
    } catch (JSONException e) {
      e.printStackTrace();
    }
  }
}
