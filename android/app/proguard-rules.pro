# ProGuard / R8 rules for Home Workers (Flutter + Firebase + Google Play Services)
# Goal: keep required classes for runtime/reflection while enabling shrinking/optimization.

# Keep common metadata/annotations and debugging info that may be useful
-keepattributes Exceptions,InnerClasses,Signature,Deprecated,SourceFile,LineNumberTable,*Annotation*,EnclosingMethod

# Flutter embedding and plugin registrant (usually safe even without these, but we keep conservatively)
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase & Google Play Services (most SDKs ship consumer rules; these are conservative keeps)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Maps Android & utils (used by google_maps_flutter)
-keep class com.google.maps.** { *; }
-dontwarn com.google.maps.**

# Keep enum methods (useful when reflection is used)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# WebView JS interfaces (if any plugin uses @JavascriptInterface)
-keepclassmembers class ** {
    @android.webkit.JavascriptInterface <methods>;
}

# GSON/Moshi style reflection (if any 3rd party plugin uses them under the hood)
#-keep class com.google.gson.** { *; }
#-dontwarn com.google.gson.**

# OkHttp/Okio (used by some plugins). Uncomment if you see warnings in release build.
#-dontwarn okhttp3.**
#-dontwarn okio.**
