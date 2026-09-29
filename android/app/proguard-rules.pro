# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Cloud Firestore and Firebase Core
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.** { *; }
-keep class io.grpc.** { *; }
-keep class com.google.protobuf.** { *; }

# Suppress missing class warnings for R8
-dontwarn com.google.android.play.core.**
-dontwarn com.squareup.okhttp.**
