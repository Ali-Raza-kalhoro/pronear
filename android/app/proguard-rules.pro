# ML Kit text recognition: the Flutter plugin references the Chinese / Devanagari /
# Japanese / Korean recognizer classes, but we only bundle the Latin model (CNIC
# numbers are Latin digits) to keep the app small. Tell R8 not to fail on them.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
