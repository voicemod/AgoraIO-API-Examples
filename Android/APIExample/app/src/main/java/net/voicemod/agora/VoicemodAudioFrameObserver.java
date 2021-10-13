package net.voicemod.agora;

import android.content.Context;
import android.util.Log;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CompoundButton;
import android.widget.Switch;

import androidx.appcompat.widget.AppCompatSpinner;

import net.voicemod.android.usdk.VoiceQuality;
import net.voicemod.android.usdk.VoicemodUSDK;
import net.voicemod.android.usdk.VoicemodUSDKException;

import java.nio.ByteBuffer;

import io.agora.api.example.R;
import io.agora.rtc.AudioFrame;
import io.agora.rtc.Constants;
import io.agora.rtc.IAudioFrameObserver;
import io.agora.rtc.audio.AudioParams;

public class VoicemodAudioFrameObserver implements IAudioFrameObserver, AdapterView.OnItemSelectedListener, CompoundButton.OnCheckedChangeListener {
    private String TAG = "net.voicemod.usdk";
    private final int sampleRate;
    private final int sampleNumOfChannel;
    private final int samplesPerCall;

    public boolean enabled = false;

    private Switch voiceSwitch;
    private AppCompatSpinner voiceSpinner;
    private String[] voices;
    public static String currentVoice = "clean";

    public VoicemodAudioFrameObserver() {
        this(null, null, null);
    }

    public VoicemodAudioFrameObserver(Integer sampleRate, Integer sampleNumOfChannel, Integer samplesPerCall) {
        super();
        this.sampleRate = sampleRate != null ? sampleRate : 44100;
        this.sampleNumOfChannel = sampleNumOfChannel != null ? sampleNumOfChannel : 2;
        this.samplesPerCall = samplesPerCall != null ? samplesPerCall : 4410;
    }

    // Voice controls

    public void setVoiceControls(View view) {
        voiceSwitch = view.findViewById(R.id.voicemod_switch);
        voiceSpinner = view.findViewById(R.id.voice_spinner);
    }

    public void configureVoiceControls(Context context) {
        try {
            voices = VoicemodUSDK.getPresetsNames(VoiceQuality.MEDIUM);
        } catch (VoicemodUSDKException e) {
            e.printStackTrace();
        }
        voiceSwitch.setOnCheckedChangeListener(this);
        voiceSpinner.setAdapter(new ArrayAdapter<String>(context,android.R.layout.simple_spinner_dropdown_item, voices));
        voiceSpinner.setOnItemSelectedListener(this);
        for (int n = 0; n < voices.length; n++) {
            if (voices[n].equals(currentVoice)) {
                voiceSpinner.setSelection(n);
                break;
            }
        }
    }

    public void setEnabled(boolean en) {
        voiceSwitch.setEnabled(en);
    }

    @Override
    public void onCheckedChanged(CompoundButton compoundButton, boolean b) {
        enabled = b;
    }

    @Override
    public void onItemSelected(AdapterView<?> adapterView, View view, int i, long l) {
        if(adapterView.getId() == R.id.voice_spinner){
            try {
                VoicemodUSDK.loadVoice(voices[i]);
                currentVoice = voices[i];
            } catch (VoicemodUSDKException e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public void onNothingSelected(AdapterView<?> adapterView) {

    }

    // Audio Frame Listener

    @Override
    public boolean onRecordFrame(AudioFrame audioFrame) {
        if(!enabled)
            return true;
        Log.i(TAG, "onRecordAudioFrame ");
        ByteBuffer byteBuffer = audioFrame.samples;
        byte[] origin = new byte[byteBuffer.remaining()];
        byteBuffer.get(origin);
        byteBuffer.flip();
        try {
            VoicemodUSDK.processBuffer(origin);
        } catch (VoicemodUSDKException e) {
            Log.e(TAG, e.getLocalizedMessage());
        }
        byteBuffer.put(origin, 0, byteBuffer.remaining());
        return true;
    }

    @Override
    public boolean onPlaybackFrame(AudioFrame audioFrame) {
        return false;
    }

    @Override
    public boolean onPlaybackFrameBeforeMixing(AudioFrame audioFrame, int uid) {
        return false;
    }

    @Override
    public boolean onMixedFrame(AudioFrame audioFrame) {
        return false;
    }

    @Override
    public boolean isMultipleChannelFrameWanted() {
        return false;
    }

    @Override
    public boolean onPlaybackFrameBeforeMixingEx(AudioFrame audioFrame, int uid, String channelId) {
        return false;
    }

    @Override
    public int getObservedAudioFramePosition() {
        return IAudioFrameObserver.POSITION_RECORD | IAudioFrameObserver.POSITION_MIXED;
    }

    @Override
    public AudioParams getRecordAudioParams() {
        return new AudioParams(sampleRate, sampleNumOfChannel, Constants.RAW_AUDIO_FRAME_OP_MODE_READ_WRITE, samplesPerCall);
    }

    @Override
    public AudioParams getPlaybackAudioParams() {
        return new AudioParams(sampleRate, sampleNumOfChannel, Constants.RAW_AUDIO_FRAME_OP_MODE_READ_ONLY, samplesPerCall);
    }

    @Override
    public AudioParams getMixedAudioParams() {
        return new AudioParams(sampleRate, sampleNumOfChannel, Constants.RAW_AUDIO_FRAME_OP_MODE_READ_ONLY, samplesPerCall);
    }

}
