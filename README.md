# 🎵 Sinyal Jeneratörü

Modern ve şık bir Flutter mobil uygulaması ile profesyonel sinyal üretimi ve Bluetooth iletimi.

## ✨ Özellikler

### 🌊 Sinyal Türleri
- **Sinüs Dalgası** - Klasik sinüzoidal dalga formu
- **Kare Dalga** - Dijital sinyal uygulamaları için
- **Üçgen Dalga** - Doğrusal rampa sinyalleri
- **Testere Dişi** - Tarama ve modülasyon uygulamaları

### ⚙️ Ayarlanabilir Parametreler
- **Frekans**: 1 Hz - 10 kHz aralığında ayarlanabilir
- **Amplitüd**: 0.1V - 5.0V arası voltaj kontrolü
- **Faz**: 0° - 360° faz kayması
- **DC Offset**: -5V ile +5V arası DC seviye kontrolü

### 📡 İletişim Özellikleri
- **Bluetooth Bağlantısı**: Kolay cihaz eşleştirme
- **Gerçek Zamanlı İletim**: Anlık sinyal gönderimi
- **JSON Protokol**: Standart veri formatı
- **Otomatik Cihaz Tarama**: Yakındaki Bluetooth cihazlarını bulma

### 🎨 Modern Kullanıcı Arayüzü
- **Neon Renkler**: Sinyal türüne göre renk kodlaması
  - 🔵 Mavi: Sinüs dalgası
  - 🟣 Mor: Kare dalga
  - 🟢 Yeşil: Üçgen dalga
  - 🟠 Turuncu: Testere dişi
- **Glassmorphism**: Modern cam efekti tasarımı
- **Animasyonlu Geçişler**: Yumuşak ve sinematik geçişler
- **Gerçek Zamanlı Dalga Görselleştirme**: Canlı dalga formu animasyonu
- **Işıldayan Efektler**: Neon glow ve pulse animasyonları

## 📱 Kurulum

### Gereksinimler
- Flutter SDK (3.0+)
- iOS 12.0+ veya Android 5.0+
- Bluetooth özelliği olan cihaz

### Adımlar

1. **Bağımlılıkları yükleyin**
```bash
flutter pub get
```

2. **iOS için ek ayarlar**
```bash
cd ios
pod install
cd ..
```

3. **Uygulamayı çalıştırın**
```bash
flutter run
```

## 🚀 Kullanım

### 1. Bluetooth Bağlantısı
1. Ana ekranda sağ üstteki Bluetooth simgesine dokunun
2. "Cihazları Ara" butonuna basın
3. Listeden osiloskop cihazınızı seçin
4. Bağlantı otomatik olarak kurulacaktır

### 2. Sinyal Üretimi
1. İstediğiniz sinyal türünü seçin (Sinüs, Kare, Üçgen, Testere)
2. Parametreleri ayarlayın:
   - Frekans slider'ı ile frekansı ayarlayın
   - Amplitüd slider'ı ile voltaj seviyesini belirleyin
   - Faz slider'ı ile faz kayması ekleyin
   - DC Offset ile sinyale DC bileşen ekleyin
3. Dalga formunu gerçek zamanlı olarak görselleştirme ekranında izleyin

### 3. Sinyal Gönderimi
1. Parametreleri ayarladıktan sonra "Sinyal Gönder" butonuna basın
2. Sinyal Bluetooth üzerinden osiloskoba gönderilecektir
3. Gönderim durumu ekranda gösterilir

## 📊 Veri Formatı

Uygulama JSON formatında veri gönderir:

```json
{
  "version": "1.0",
  "signal": {
    "type": "sine",
    "frequency": 1000,
    "amplitude": 3.3,
    "phase": 0,
    "offset": 0,
    "samples": [...],
    "timestamp": 1234567890
  }
}
```

## 🔧 Teknik Detaylar

### Kullanılan Teknolojiler
- **Flutter**: Cross-platform mobil uygulama framework'ü
- **flutter_blue_plus**: Bluetooth Low Energy iletişimi
- **provider**: State management
- **custom_paint**: Özel dalga formu çizimi
- **glassmorphism**: Modern UI efektleri

### Mimari
```
lib/
├── models/              # Veri modelleri
│   ├── signal_type.dart
│   ├── signal_parameters.dart
│   └── signal_generator.dart
├── services/           # İş mantığı servisleri
│   └── bluetooth_service.dart
├── screens/            # Uygulama ekranları
│   ├── home_screen.dart
│   └── bluetooth_screen.dart
├── widgets/            # Özel widget'lar
│   ├── waveform_widget.dart
│   ├── neon_slider.dart
│   └── signal_type_selector.dart
├── theme/              # Tema ve renkler
│   └── app_theme.dart
└── main.dart           # Uygulama giriş noktası
```

## ⚠️ Önemli Notlar

- iOS için Bluetooth izinleri `Info.plist` dosyasında tanımlıdır
- Android için `AndroidManifest.xml` dosyasında Bluetooth izinleri gereklidir
- Uygulama gerçek cihazda test edilmelidir (simülatörde Bluetooth çalışmaz)
- İlk kullanımda Bluetooth izni verilmesi gerekir

---

**Keyifli Sinyal Üretimi! 🎵🌊**
