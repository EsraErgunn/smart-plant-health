# 🌱 Smart Plant Health

Yaprak fotoğrafından bitki hastalığını **cihaz üzerinde** (TensorFlow Lite) tespit eden, hava durumuna göre hastalık riski analizi yapan ve en yakın zirai ilaç bayilerini haritada gösteren Flutter uygulaması.

## Özellikler

- **Hastalık tespiti:** Kamera veya galeriden alınan fotoğraf, MobileNetV2 tabanlı bir TFLite modeliyle çevrimdışı sınıflandırılır. Güven skoru %50'nin altındaysa sonuç gösterilmez, kullanıcıdan daha net bir fotoğraf istenir.
- **Reçete ekranı:** Belirtiler, nedenler, tedavi ve korunma yöntemleri ile risk seviyesi.
- **Plant Doctor AI:** Tespit edilen hastalık hakkında Google Gemini (`gemini-2.5-flash`) ile sohbet.
- **Hava durumu ve risk analizi:** OpenWeather verisiyle 5 günlük tahmin, nem ve sıcaklığa göre hastalık riski grafiği, sera modu.
- **Harita:** Google Places ile yakındaki zirai ilaç bayileri; Türkiye şehirleri arasında arama.
- **Teşhis geçmişi:** Çekilen fotoğraflar Hive ile cihazda saklanır.
- **Türkçe / İngilizce** arayüz, açık/koyu tema, bildirimler.

### Desteklenen bitkiler ve sınıflar (16)

| Bitki | Sınıflar |
|---|---|
| Elma | Kara leke (scab), siyah çürüklük, sedir pası, sağlıklı |
| Mısır | Gri yaprak lekesi (Cercospora), pas, kuzey yaprak yanıklığı, sağlıklı |
| Üzüm | Siyah çürüklük, Esca, yaprak yanıklığı, sağlıklı |
| Domates | Bakteriyel leke, erken yanıklık, geç yanıklık, sağlıklı |

## Kurulum

### Gereksinimler

- Flutter 3.38+ (Dart 3.3+)
- Android Studio / Android SDK (iOS için Xcode)

### 1. Bağımlılıkları yükle

```bash
flutter pub get
```

### 2. API anahtarlarını ayarla

Anahtarlar **repoya eklenmez**. İki dosya oluşturman gerekir:

**a) `env.json`** (proje kök dizini, Dart kodu için):

```bash
cp env.example.json env.json
```

```json
{
  "GOOGLE_GEMINI_KEY": "...",
  "OPENWEATHER_API_KEY": "...",
  "GOOGLE_MAPS_API_KEY": "..."
}
```

**b) `android/local.properties`** (Android'de harita görüntüsü için; Flutter bu dosyayı otomatik oluşturur, sonuna ekle):

```properties
GOOGLE_MAPS_API_KEY=...
```

| Anahtar | Nereden alınır | Kullanıldığı yer |
|---|---|---|
| `GOOGLE_GEMINI_KEY` | [Google AI Studio](https://aistudio.google.com/apikey) | Plant Doctor AI sohbeti |
| `OPENWEATHER_API_KEY` | [OpenWeather](https://home.openweathermap.org/api_keys) | Hava durumu, şehir arama |
| `GOOGLE_MAPS_API_KEY` | [Google Cloud Console](https://console.cloud.google.com/google/maps-apis) (Maps SDK for Android + Places API) | Harita ve bayi araması |

### 3. Çalıştır

```bash
flutter run --dart-define-from-file=env.json
```

VS Code kullanıyorsan `.vscode/launch.json` bu parametreyi zaten ekler; F5 yeterli.

Release derleme:

```bash
flutter build apk --release --dart-define-from-file=env.json
```

> `--dart-define-from-file` verilmezse uygulama açılır ama AI sohbeti, hava durumu ve bayi araması çalışmaz.

## Testler

```bash
flutter test
flutter analyze
```

Testler etiket ayrıştırmayı, olasılık dönüşümünü ve `labels.txt` ile `disease_data.json` arasındaki eşleşmeyi doğrular.

## Proje yapısı

```
lib/
├── config/      # Tema, Env (API anahtarları)
├── data/        # Türkiye şehir listesi
├── l10n/        # Çeviri dosyaları (arb) ve üretilmiş kod
├── models/      # Veri modelleri
├── providers/   # Provider state yönetimi
├── screens/     # Tespit, reçete, hava durumu, harita, bilgi, ayarlar
├── services/    # TFLite, Gemini, OpenWeather, Maps, Hive, bildirim
└── widgets/     # Ortak bileşenler
assets/
├── model/       # plant_disease_model.tflite, labels.txt
└── data/        # disease_data.json (hastalık bilgileri)
```

## Güvenlik notları

- `env.json`, `.env` ve `android/local.properties` `.gitignore` içindedir; **asla commit etme**.
- Mobil uygulamaya gömülen her anahtar APK'dan çıkarılabilir. Bu yüzden Google Cloud Console'da anahtarları kısıtla:
  - **Maps anahtarı:** *Application restrictions → Android apps* (paket adı + SHA-1) ve *API restrictions → Maps SDK for Android, Places API*.
  - **Gemini anahtarı:** *API restrictions → Generative Language API* ve bir kota/bütçe uyarısı.
- Üretim ortamı için önerilen yöntem, Gemini çağrılarını bir backend veya [Firebase AI Logic + App Check](https://firebase.google.com/docs/ai-logic) üzerinden yapmaktır.

## Lisans

Bu proje eğitim amaçlı geliştirilmiştir.
