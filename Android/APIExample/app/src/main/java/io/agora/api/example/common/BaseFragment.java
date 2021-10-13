package io.agora.api.example.common;

import android.content.Context;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.Fragment;

import net.voicemod.agora.VoicemodAudioFrameObserver;
import net.voicemod.android.usdk.VoicemodUSDK;
import net.voicemod.android.usdk.VoicemodUSDKException;

public class BaseFragment extends Fragment
{
    protected Handler handler;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
    }

    @Override
    public void onResume() {
        super.onResume();
        VoicemodUSDK.startEngine();
        try {
            VoicemodUSDK.loadVoice(VoicemodAudioFrameObserver.currentVoice);
        } catch (VoicemodUSDKException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        VoicemodUSDK.stopEngine();
    }

    protected void showAlert(String message)
    {
        Context context = getContext();
        if (context == null) {
            return;
        }

        new AlertDialog.Builder(context).setTitle("Tips").setMessage(message)
                .setPositiveButton("OK", (dialog, which) -> dialog.dismiss())
                .show();
    }

    protected final void showLongToast(final String msg)
    {
        handler.post(new Runnable()
        {
            @Override
            public void run()
            {
                if (BaseFragment.this == null || getContext() == null)
                {return;}
                Toast.makeText(getContext().getApplicationContext(), msg, Toast.LENGTH_LONG).show();
            }
        });
    }
}
