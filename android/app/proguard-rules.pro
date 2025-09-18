# Flutter's default rules.
-dontwarn io.flutter.embedding.**

# --- GOOGLE ML KIT İÇİN KESİN ÇÖZÜM KURALLARI ---

# Bu kural, ML Kit'in tüm modellerini ve bileşenlerini korur.
-keep public class com.google.mlkit.** {
    public *;
}

# Bu kural, Google Play servislerinin ML Kit ile ilgili kısımlarını korur.
-keep public class com.google.android.gms.internal.mlkit_vision_common.** {
    public *;
}

# Metin tanıma (Text Recognition) modülünün tüm alt bileşenlerini korur.
# Önceki hatanın kaynağı olan Çince, Japonca vb. tüm diller dahildir.
-keep public class com.google.android.gms.internal.mlkit_vision_text_common.** {
    public *;
}