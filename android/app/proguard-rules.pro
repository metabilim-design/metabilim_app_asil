# Flutter's default rules.
-dontwarn io.flutter.embedding.**

# ML Kit'in ihtiyaç duyduğu ve R8 tarafından yanlışlıkla silinebilecek
# tüm sınıfları koruma altına alıyoruz.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
