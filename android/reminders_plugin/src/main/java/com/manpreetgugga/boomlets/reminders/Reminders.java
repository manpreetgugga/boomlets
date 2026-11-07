package com.manpreetgugga.boomlets.reminders;

import android.Manifest;
import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Calendar;

/**
 * Sets, keeps and posts the play reminders. The game hands over a plan (which
 * day, what time, which words); the alarms and the plan are saved here so a
 * reboot can set them again without the game running.
 */
final class Reminders {
    static final String TAG = "BoomletsReminders";
    static final String ACTION_FIRE = "com.manpreetgugga.boomlets.reminders.FIRE";
    static final String EXTRA_TITLE = "title";
    static final String EXTRA_BODY = "body";
    static final String EXTRA_SLOT = "slot";
    /** When the reminder was due (epoch ms). */
    static final String EXTRA_AT = "at";
    /**
     * A reminder held back longer than this (a phone dozing on its charger can
     * hold an alarm for hours) is dropped rather than posted at 2 AM.
     */
    static final long MAX_LATE_MS = 90 * 60_000L;
    /** Put on the intent that opens the game from a reminder: which slot it was. */
    static final String EXTRA_OPENED = "boomlets_reminder_slot";

    private static final String PREFS = "boomlets_reminders";
    private static final String KEY_PLAN = "plan";
    private static final String KEY_COUNT = "count";
    private static final String CHANNEL = "play_reminders";
    /** One id for every reminder, so a new one replaces an unread one. */
    private static final int NOTIFICATION_ID = 4501;
    private static final int ACCENT = 0xFFF2A541;
    private static final long WINDOW_MS = 15 * 60_000L;

    private Reminders() {}

    /**
     * Replaces the saved reminders with [planJson]: an array of
     * {day (0 = today), minute (after local midnight), slot, title, body}.
     * Any falling sooner than [quietMinutes] from now are left out.
     * Returns how many were set.
     */
    static int schedule(Context ctx, String planJson, int quietMinutes) {
        long earliest = System.currentTimeMillis() + quietMinutes * 60_000L;
        JSONArray plan = new JSONArray();
        try {
            JSONArray in = new JSONArray(planJson);
            for (int i = 0; i < in.length(); i++) {
                JSONObject e = in.getJSONObject(i);
                int minute = e.getInt("minute");
                Calendar c = Calendar.getInstance();
                c.add(Calendar.DAY_OF_YEAR, e.getInt("day"));
                c.set(Calendar.HOUR_OF_DAY, minute / 60);
                c.set(Calendar.MINUTE, minute % 60);
                c.set(Calendar.SECOND, 0);
                c.set(Calendar.MILLISECOND, 0);
                long at = c.getTimeInMillis();
                if (at < earliest) {
                    continue;
                }
                JSONObject s = new JSONObject();
                s.put("at", at);
                s.put(EXTRA_SLOT, e.optString(EXTRA_SLOT));
                s.put(EXTRA_TITLE, e.optString(EXTRA_TITLE));
                s.put(EXTRA_BODY, e.optString(EXTRA_BODY));
                plan.put(s);
            }
        } catch (JSONException ex) {
            Log.w(TAG, "Bad reminder plan", ex);
            return 0;
        }
        prefs(ctx).edit().putString(KEY_PLAN, plan.toString()).apply();
        arm(ctx, plan);
        return plan.length();
    }

    static void cancelAll(Context ctx) {
        JSONArray none = new JSONArray();
        prefs(ctx).edit().putString(KEY_PLAN, none.toString()).apply();
        arm(ctx, none);
    }

    /** After a reboot or an update: sets the saved reminders again. */
    static void restore(Context ctx) {
        try {
            arm(ctx, new JSONArray(prefs(ctx).getString(KEY_PLAN, "[]")));
        } catch (JSONException ex) {
            Log.w(TAG, "Bad saved reminder plan", ex);
        }
    }

    /** Sets one alarm per reminder still to come and cancels any left over from before. */
    private static void arm(Context ctx, JSONArray plan) {
        AlarmManager am = ctx.getSystemService(AlarmManager.class);
        if (am == null) {
            return;
        }
        SharedPreferences p = prefs(ctx);
        int before = p.getInt(KEY_COUNT, 0);
        long now = System.currentTimeMillis();
        for (int i = 0; i < plan.length(); i++) {
            JSONObject s = plan.optJSONObject(i);
            if (s == null || s.optLong("at") <= now) {
                cancel(ctx, am, i);
                continue;
            }
            Intent fire = fireIntent(ctx)
                    .putExtra(EXTRA_AT, s.optLong("at"))
                    .putExtra(EXTRA_SLOT, s.optString(EXTRA_SLOT))
                    .putExtra(EXTRA_TITLE, s.optString(EXTRA_TITLE))
                    .putExtra(EXTRA_BODY, s.optString(EXTRA_BODY));
            PendingIntent pi = PendingIntent.getBroadcast(ctx, i, fire,
                    PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
            // Inexact on purpose (no exact-alarm permission): within 15 minutes
            // of its time (plain inexact alarms may drift an hour), or, on a
            // phone left idle, when it next wakes (too late: see MAX_LATE_MS).
            am.setWindow(AlarmManager.RTC_WAKEUP, s.optLong("at"), WINDOW_MS, pi);
        }
        for (int i = plan.length(); i < before; i++) {
            cancel(ctx, am, i);
        }
        p.edit().putInt(KEY_COUNT, plan.length()).apply();
    }

    private static void cancel(Context ctx, AlarmManager am, int code) {
        PendingIntent pi = PendingIntent.getBroadcast(ctx, code, fireIntent(ctx),
                PendingIntent.FLAG_NO_CREATE | PendingIntent.FLAG_IMMUTABLE);
        if (pi != null) {
            am.cancel(pi);
            pi.cancel();
        }
    }

    private static Intent fireIntent(Context ctx) {
        return new Intent(ctx, ReminderReceiver.class).setAction(ACTION_FIRE);
    }

    static boolean hasPermission(Context ctx) {
        return Build.VERSION.SDK_INT < 33
                || ctx.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED;
    }

    /** Whether a reminder posted now would show: permission given, and neither the app's notifications nor its channel are switched off. */
    static boolean canNotify(Context ctx) {
        if (!hasPermission(ctx)) {
            return false;
        }
        NotificationManager nm = ctx.getSystemService(NotificationManager.class);
        if (nm == null || !nm.areNotificationsEnabled()) {
            return false;
        }
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel ch = nm.getNotificationChannel(CHANNEL);
            return ch == null || ch.getImportance() != NotificationManager.IMPORTANCE_NONE;
        }
        return true;
    }

    static void ensureChannel(Context ctx) {
        if (Build.VERSION.SDK_INT < 26) {
            return;
        }
        NotificationManager nm = ctx.getSystemService(NotificationManager.class);
        if (nm == null || nm.getNotificationChannel(CHANNEL) != null) {
            return;
        }
        NotificationChannel ch = new NotificationChannel(CHANNEL, "Play reminders",
                NotificationManager.IMPORTANCE_DEFAULT);
        ch.setDescription("A friendly nudge from Pip in the morning, the evening and at night");
        nm.createNotificationChannel(ch);
    }

    /** Posts one reminder; tapping it opens the game. */
    static void show(Context ctx, String title, String body, String slot) {
        if (!canNotify(ctx)) {
            return;
        }
        NotificationManager nm = ctx.getSystemService(NotificationManager.class);
        Intent open = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
        if (nm == null || open == null) {
            return;
        }
        ensureChannel(ctx);
        open.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        open.putExtra(EXTRA_OPENED, slot);
        PendingIntent tap = PendingIntent.getActivity(ctx, 0, open,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Notification.Builder b = Build.VERSION.SDK_INT >= 26
                ? new Notification.Builder(ctx, CHANNEL)
                : new Notification.Builder(ctx);
        b.setSmallIcon(R.drawable.boomlets_reminder_icon)
                .setColor(ACCENT)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(new Notification.BigTextStyle().bigText(body))
                .setContentIntent(tap)
                .setAutoCancel(true)
                .setShowWhen(true);
        Bitmap face = appIcon(ctx);
        if (face != null) {
            b.setLargeIcon(face);
        }
        try {
            nm.notify(NOTIFICATION_ID, b.build());
        } catch (SecurityException ex) {
            Log.w(TAG, "Not allowed to post a reminder", ex);
        }
    }

    /**
     * The game's icon as a picture. (The icon is an adaptive one, an XML
     * drawable, which BitmapFactory cannot read, so it is drawn instead.)
     */
    private static Bitmap appIcon(Context ctx) {
        try {
            Drawable d = ctx.getPackageManager().getApplicationIcon(ctx.getApplicationInfo());
            int size = ctx.getResources().getDimensionPixelSize(android.R.dimen.notification_large_icon_width);
            if (size <= 0) {
                size = 128;
            }
            Bitmap bm = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888);
            d.setBounds(0, 0, size, size);
            d.draw(new Canvas(bm));
            return bm;
        } catch (RuntimeException ex) {
            Log.w(TAG, "No icon for the reminder", ex);
            return null;
        }
    }

    private static SharedPreferences prefs(Context ctx) {
        return ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }
}
