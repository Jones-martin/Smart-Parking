# Flutter generated rules (keep default Flutter stuff)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# Keep Razorpay SDK classes
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Keep ProGuard annotations used by Razorpay
-keep class proguard.annotation.** { *; }
-dontwarn proguard.annotation.**

# Optional: Keep JSON parser classes used internally
-keep class org.json.** { *; }
-dontwarn org.json.**

# Optional: Keep AndroidX annotations (if using)
-keep class androidx.annotation.** { *; }
-dontwarn androidx.annotation.**
