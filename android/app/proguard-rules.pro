# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep annotation
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Gson / JSON serialization
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# GeoFire / GeoFlutterFire
-keep class com.firebase.geofire.** { *; }

# Prevent R8 from removing classes used via reflection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Card.io
-keep class io.card.** { *; }
-dontwarn io.card.**
