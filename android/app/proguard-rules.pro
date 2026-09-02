# Keep Google Play Services classes
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep geolocator classes
-keep class io.flutter.plugins.geolocator.** { *; }
-dontwarn io.flutter.plugins.geolocator.**

# Keep Flutter plugin classes
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**
