# 🎯 Sinyal Jeneratörü - Kullanım Kılavuzu

## 🚀 Hızlı Başlangıç

### 1. Uygulamayı Çalıştırma

iOS cihazda:
```bash
flutter run
```

Belirli bir cihaz seçmek için:
```bash
flutter devices
flutter run -d [DEVICE_ID]
```

### 2. İlk Kullanım

1. **Uygulama Açılışı**
   - Uygulama açıldığında modern neon temalı ana ekran sizi karşılayacak
   - Üst kısımda "Sinyal Jeneratörü" başlığı ve Bluetooth durum göstergesi var
   - Sağ üst köşede Bluetooth bağlantı butonu bulunuyor

2. **Bluetooth Bağlantısı Kurma**
   - Bluetooth butonuna (🔵) dokunun
   - "Cihazları Ara" butonuna basın
   - Yakındaki Bluetooth cihazları listelenecek
   - Osiloskop tablet'inizi listeden seçin
   - Bağlantı kurulduğunda yeşil onay göreceksiniz

3. **Sinyal Üretme**
   - Ana ekrana dönün
   - 4 sinyal türünden birini seçin:
     * 🔵 **Sinüs** - Yumuşak dalga
     * 🟣 **Kare** - Keskin geçişli dalga
     * 🟢 **Üçgen** - Doğrusal dalga
     * 🟠 **Testere** - Rampa dalga

4. **Parametreleri Ayarlama**
   - **Frekans**: 1 Hz - 10 kHz (Dalga hızı)
   - **Amplitüd**: 0.1V - 5.0V (Dalga yüksekliği)
   - **Faz**: 0° - 360° (Dalga kayması)
   - **DC Offset**: -5V - +5V (Ortalama seviye)

5. **Sinyal Gönderme**
   - Parametreleri ayarladıktan sonra
   - "Sinyal Gönder" butonuna basın
   - Sinyal Bluetooth üzerinden tablet'e gönderilecek
   - Tablet'teki osiloskop uygulaması sinyali gösterecek

## 🎨 Özellikler

### Görsel Efektler
- ✨ Neon renkler her sinyal tipi için farklı
- 💫 Gerçek zamanlı animasyonlu dalga görselleştirme
- 🌟 Glassmorphism (cam efekti) tasarım
- 🎭 Sinematik geçişler ve animasyonlar
- 💡 Işıldayan (glow) efektler

### Teknik Özellikler
- 📊 360 örnek/periyot hassasiyetle sinyal üretimi
- 📡 JSON formatında veri iletimi
- 🔄 Gerçek zamanlı parametre güncelleme
- 📱 iOS 12.0+ desteği
- 🎯 Bluetooth Low Energy (BLE) iletişimi

## 📊 Veri Formatı

Gönderilen JSON yapısı:
```json
{
  "version": "1.0",
  "signal": {
    "type": "sine",           // sine, square, triangle, sawtooth
    "frequency": 1000,        // Hz
    "amplitude": 3.3,         // Volt
    "phase": 0,              // Derece
    "offset": 0,             // Volt
    "samples": [0.0, 0.1, ...], // 360 adet örnek
    "timestamp": 1699012345   // Unix timestamp (ms)
  }
}
```

## 🔧 Sorun Giderme

### Bluetooth Bağlanamıyor
- ✅ Bluetooth'un açık olduğundan emin olun
- ✅ Uygulama izinlerini kontrol edin (Ayarlar > Gizlilik)
- ✅ Cihazı yeniden başlatın
- ✅ Tablet'in Bluetooth modunda olduğunu doğrulayın

### Sinyal Görünmüyor
- ✅ Bluetooth bağlantısını kontrol edin
- ✅ Tablet'teki osiloskop uygulamasının çalıştığından emin olun
- ✅ Frekans ve amplitüd değerlerini kontrol edin
- ✅ "Sinyal Gönder" butonuna bastığınızdan emin olun

### Uygulama Donuyor/Kapanıyor
- ✅ Flutter'ın güncel olduğundan emin olun
- ✅ `flutter clean && flutter pub get` çalıştırın
- ✅ Uygulamayı release modda derleyin: `flutter run --release`

## 💡 İpuçları

1. **Optimum Performans İçin**
   - Düşük frekanslarda (< 100 Hz) daha iyi görselleştirme
   - Yüksek frekanslarda (> 1 kHz) örnekleme sayısını artırabilirsiniz

2. **Pil Tasarrufu**
   - Kullanmadığınızda Bluetooth bağlantısını kesin
   - Gereksiz sinyal gönderiminden kaçının

3. **En İyi Sonuçlar**
   - Cihazlar arası mesafeyi 5 metre altında tutun
   - Metal engellerin olmadığı ortamlarda kullanın
   - Tablet'in şarj seviyesini yüksek tutun

## 📱 Sistem Gereksinimleri

### Minimum
- iOS 12.0+
- iPhone 6s veya üzeri
- Bluetooth 4.0+
- 100 MB boş alan

### Önerilen
- iOS 15.0+
- iPhone X veya üzeri
- Bluetooth 5.0+
- 200 MB boş alan

## 🆘 Destek

Sorun yaşarsanız:
1. Uygulamayı kapatıp tekrar açın
2. Cihazı yeniden başlatın
3. En son sürümü kullandığınızdan emin olun
4. Issue açarak bildirin

---

**İyi Kullanımlar! 🎵**
