# Google ML Kit Text Recognition
# Suppress R8 missing class warnings for optional unbundled language recognizers
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.**

# Keep ML Kit core interfaces & classes
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }

