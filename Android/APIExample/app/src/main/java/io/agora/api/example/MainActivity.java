package io.agora.api.example;

import android.content.Intent;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.util.Log;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.constraintlayout.solver.GoalRow;
import androidx.navigation.ActionOnlyNavDirections;
import androidx.navigation.NavController;
import androidx.navigation.Navigation;
import androidx.navigation.ui.AppBarConfiguration;
import androidx.navigation.ui.NavigationUI;

import io.agora.api.component.Constant;
import io.agora.api.example.annotation.Example;
import io.agora.api.example.common.model.ExampleBean;

import net.voicemod.android.usdk.VoicemodUSDK;
import net.voicemod.android.usdk.VoicemodUSDKException;
import net.voicemod.android.usdk.VoiceQuality;

/**
 * @author cjw
 */
public class MainActivity extends AppCompatActivity implements MainFragment.OnListFragmentInteractionListener {
    private AppBarConfiguration appBarConfiguration;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        try {
            VoicemodUSDK.initSDK(this.getApplication(), getString(R.string.voicemod_client_key));
            VoicemodUSDK.setVoiceQuality(VoiceQuality.MEDIUM);
        } catch (VoicemodUSDKException e) {
            e.printStackTrace();
        }
        NavController navController = Navigation.findNavController(this, R.id.nav_host_fragment);
        appBarConfiguration = new AppBarConfiguration.Builder(navController.getGraph()).build();
        NavigationUI.setupActionBarWithNavController(this, navController, appBarConfiguration);
    }

    @Override
    public boolean onSupportNavigateUp() {
        NavController navController = Navigation.findNavController(this, R.id.nav_host_fragment);
        return NavigationUI.navigateUp(navController, appBarConfiguration)
                || super.onSupportNavigateUp();
    }

    @Override
    public void onListFragmentInteraction(Example item) {
        ExampleBean exampleBean = new ExampleBean(item.index(), item.group(), item.name(), item.actionId(), item.tipsId());
        Bundle bundle = new Bundle();
        bundle.putParcelable(Constant.DATA, exampleBean);
        Navigation.findNavController(this, R.id.nav_host_fragment)
                .navigate(R.id.action_mainFragment_to_Ready, bundle);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_main_activity, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        if (item.getItemId() == R.id.setting) {
            startActivity(new Intent(this, SettingActivity.class));
        }
        return false;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        try {
            VoicemodUSDK.destroySDK();
        } catch (VoicemodUSDKException e) {
            e.printStackTrace();
        }
    }
}
