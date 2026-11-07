package com.manpreetgugga.boomlets.reminders;

import android.Manifest;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.view.View;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

/**
 * The game's side of the play reminders (core/Reminders.gd talks to this as
 * the "BoomletsReminders" singleton).
 */
public class RemindersPlugin extends GodotPlugin {
    private static final int ASK_CODE = 4502;

    /** True while the game is on screen; a reminder due then is skipped. */
    static volatile boolean appVisible = false;

    private String openedSlot = "";

    public RemindersPlugin(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "BoomletsReminders";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("permission_result", Boolean.class));
        return signals;
    }

    @Override
    public View onMainCreate(Activity activity) {
        if (activity != null) {
            Reminders.ensureChannel(activity);
            takeOpened(activity.getIntent());
        }
        return null;
    }

    @Override
    public void onMainResume() {
        appVisible = true;
        Activity a = getActivity();
        if (a != null) {
            takeOpened(a.getIntent());
        }
    }

    @Override
    public void onMainPause() {
        appVisible = false;
    }

    @Override
    public void onMainDestroy() {
        appVisible = false;
    }

    private void takeOpened(Intent intent) {
        if (intent == null) {
            return;
        }
        String slot = intent.getStringExtra(Reminders.EXTRA_OPENED);
        if (slot != null) {
            openedSlot = slot;
            intent.removeExtra(Reminders.EXTRA_OPENED);
        }
    }

    @UsedByGodot
    public int sdkVersion() {
        return Build.VERSION.SDK_INT;
    }

    /** Android 13+: whether the player has allowed notifications. Always true below 13. */
    @UsedByGodot
    public boolean hasPermission() {
        return Reminders.hasPermission(getContext());
    }

    /** Whether a reminder would show if posted now. */
    @UsedByGodot
    public boolean canNotify() {
        return Reminders.canNotify(getContext());
    }

    /** Shows Android's "Allow notifications?" prompt; answers with permission_result. */
    @UsedByGodot
    public void requestPermission() {
        Activity a = getActivity();
        if (Build.VERSION.SDK_INT < 33 || a == null || Reminders.hasPermission(a)) {
            answer(Reminders.canNotify(getContext()));
            return;
        }
        runOnUiThread(() -> a.requestPermissions(new String[] {Manifest.permission.POST_NOTIFICATIONS}, ASK_CODE));
    }

    @Override
    public void onMainRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode != ASK_CODE) {
            return;
        }
        boolean granted = grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED;
        answer(granted);
    }

    private void answer(boolean granted) {
        runOnRenderThread(() -> emitSignal("permission_result", granted));
    }

    /** Opens the game's notification settings (after Android stops asking). */
    @UsedByGodot
    public void openSettings() {
        Activity a = getActivity();
        if (a == null) {
            return;
        }
        Intent i = new Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, a.getPackageName());
        try {
            a.startActivity(i);
        } catch (ActivityNotFoundException ex) {
            a.startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", a.getPackageName(), null)));
        }
    }

    /** Replaces the planned reminders (see Reminders.schedule); returns how many were set. */
    @UsedByGodot
    public int schedule(String planJson, int quietMinutes) {
        return Reminders.schedule(getContext(), planJson, quietMinutes);
    }

    @UsedByGodot
    public void cancelAll() {
        Reminders.cancelAll(getContext());
    }

    /** The slot of the reminder that opened the game ("" if none), once. */
    @UsedByGodot
    public String takeOpenedSlot() {
        String s = openedSlot;
        openedSlot = "";
        return s;
    }

    /** Test builds: posts one reminder right away. */
    @UsedByGodot
    public void showNow(String title, String body) {
        Reminders.show(getContext(), title, body, "test");
    }
}
