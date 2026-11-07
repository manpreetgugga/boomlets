package com.manpreetgugga.boomlets.reminders;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Posts a reminder when its alarm goes off, and sets the saved ones again after a reboot or an update. */
public class ReminderReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context ctx, Intent intent) {
        String action = intent.getAction();
        if (Reminders.ACTION_FIRE.equals(action)) {
            // Never nudge someone who is already playing, nor hours late (a
            // dozing phone holds alarms back: a night one could come at 2 AM).
            long at = intent.getLongExtra(Reminders.EXTRA_AT, 0L);
            boolean stale = at > 0 && System.currentTimeMillis() - at > Reminders.MAX_LATE_MS;
            if (!RemindersPlugin.appVisible && !stale) {
                Reminders.show(ctx, intent.getStringExtra(Reminders.EXTRA_TITLE),
                        intent.getStringExtra(Reminders.EXTRA_BODY),
                        intent.getStringExtra(Reminders.EXTRA_SLOT));
            }
        } else if (Intent.ACTION_BOOT_COMPLETED.equals(action)
                || Intent.ACTION_MY_PACKAGE_REPLACED.equals(action)) {
            Reminders.restore(ctx);
        }
    }
}
