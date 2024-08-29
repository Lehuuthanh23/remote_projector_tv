# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

####################################################################################
# RETROFIT
####################################################################################
-dontwarn okhttp3.**
-dontwarn retrofit2.**

####################################################################################
# GSON
####################################################################################
# Gson specific classes
-dontwarn sun.misc.**

####################################################################################
# Model
-keep class com.example.play_box.model.** { *; }
-dontwarn com.example.play_box.model.**

####################################################################################
# Dependency Inject
-keep class com.example.play_box.base.api.** { *; }
-dontwarn com.example.play_box.base.api.**

####################################################################################
# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.android.gms.**

####################################################################################
# Keep the annotated things annotated
-keepattributes *Annotation*, Exceptions, Signature, Deprecated, SourceFile, SourceDir, LineNumberTable, LocalVariableTable, LocalVariableTypeTable, Synthetic, EnclosingMethod, RuntimeVisibleAnnotations, RuntimeInvisibleAnnotations, RuntimeVisibleParameterAnnotations, RuntimeInvisibleParameterAnnotations, AnnotationDefault, InnerClasses