# ==============================================================================
# ExamCraft AI - ProGuard & R8 Optimization and Keep Rules
# Target: Flutter 3.x, AGP 9.0+, Android SDK 36
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Flutter Engine, Embedding, and Core Framework
# ------------------------------------------------------------------------------
-keep class io.flutter.** { *; }
-keep interface io.flutter.** { *; }
-dontwarn io.flutter.**

-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class io.flutter.plugins.** { *; }

# Keep all native JNI methods invoked by the Flutter Engine and Dart VM
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve attributes necessary for reflection, debugging, and stack traces
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,Exceptions

# ------------------------------------------------------------------------------
# 2. Platform Channels, Binary Messenger, and Codecs
# ------------------------------------------------------------------------------
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.BasicMessageChannel { *; }
-keep class io.flutter.plugin.common.EventChannel { *; }
-keep class io.flutter.plugin.common.StandardMessageCodec { *; }
-keep class io.flutter.plugin.common.BinaryMessenger { *; }
-keep class io.flutter.plugin.common.PluginRegistry { *; }
-keep class io.flutter.plugin.common.PluginRegistry$* { *; }

# ------------------------------------------------------------------------------
# 3. Dart JNI & JNIgen Interop (jni & jni_flutter - path_provider_android)
# ------------------------------------------------------------------------------
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
-dontwarn com.github.dart_lang.jni.**
-dontwarn com.github.dart_lang.jni_flutter.**

# ------------------------------------------------------------------------------
# 4. Printing & PDF Conversion Plugin (printing: ^5.13.1)
# ------------------------------------------------------------------------------
-keep class net.nfet.flutter.printing.** { *; }
-keep interface net.nfet.flutter.printing.** { *; }
-dontwarn net.nfet.flutter.printing.**

# Printing relies on custom android.print.PdfConvert helper
-keep class android.print.PdfConvert { *; }
-keep class android.print.PdfConvert$* { *; }
-dontwarn android.print.**

# ------------------------------------------------------------------------------
# 5. File Picker Plugin (file_picker: ^8.1.7)
# ------------------------------------------------------------------------------
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**

# ------------------------------------------------------------------------------
# 6. Open Filex Plugin (open_filex: ^4.5.0)
# ------------------------------------------------------------------------------
-keep class com.crazecoder.openfile.** { *; }
-dontwarn com.crazecoder.openfile.**

# ------------------------------------------------------------------------------
# 7. Plus Plugins (connectivity_plus, share_plus)
# ------------------------------------------------------------------------------
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**

-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# ------------------------------------------------------------------------------
# 8. Storage & File Plugins (shared_preferences, path_provider)
# ------------------------------------------------------------------------------
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# ------------------------------------------------------------------------------
# 9. Dio / OkHttp / Okio / Network Stack
# ------------------------------------------------------------------------------
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# ------------------------------------------------------------------------------
# 10. AndroidX & Lifecycle Support
# ------------------------------------------------------------------------------
-keep class androidx.lifecycle.** { *; }
-keep interface androidx.lifecycle.** { *; }
-keep class androidx.annotation.Keep
-keep @androidx.annotation.Keep class * { *; }
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <fields>;
}

# ------------------------------------------------------------------------------
# 11. Serialization & Enum Preservation
# ------------------------------------------------------------------------------
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ------------------------------------------------------------------------------
# 12. General Optimization Directives
# ------------------------------------------------------------------------------
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose
