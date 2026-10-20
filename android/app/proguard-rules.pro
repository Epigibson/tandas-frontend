# Flutter SharedPreferences keep rule to prevent R8 stripping Pigeon methods in Release
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**
