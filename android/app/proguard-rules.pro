# Keep Play Billing so release shrinking does not drop the library version.
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# LevelPlay (ironSource) rules from Unity's Flutter integration guide.
-keepclassmembers class com.ironsource.sdk.controller.IronSourceWebView$JSInterface {
    public *;
}
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
-keep public class com.google.android.gms.ads.** {
   public *;
}
-keep class com.ironsource.adapters.** { *;}
-keep class com.ironsource.unity.androidbridge.** { *;}
-dontwarn com.ironsource.mediationsdk.**
-dontwarn com.ironsource.adapters.**
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Local reminders (flutter_local_notifications) read their saved schedule by
# reflection; shrinking must not rename it.
-keep class com.dexterous.** { *; }
