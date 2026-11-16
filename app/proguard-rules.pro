# Lemon proguard rules
-keepclassmembers class com.lemon.app.data.** {
    <init>(...);
}
-keep class com.lemon.app.data.** { *; }
-dontwarn org.jetbrains.annotations.**
