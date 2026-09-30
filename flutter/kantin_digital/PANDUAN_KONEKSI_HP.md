# Panduan Menjalankan Aplikasi di HP (Koneksi ke Laptop)

Agar aplikasi Flutter di HP Anda bisa terhubung ke backend Laravel yang ada di Laptop, ikuti langkah berikut:

## 1. Pastikan Satu Jaringan
Pastikan Laptop dan HP Anda terhubung ke **WiFi yang sama**.

IP Laptop Anda saat ini (terdeteksi): `192.168.158.253`

## 2. Jalankan Server Laravel (PENTING!)
Secara default, `php artisan serve` hanya bisa diakses dari laptop itu sendiri. Anda harus membukanya ke jaringan.

Buka terminal di folder backend Laravel Anda (`projects_kantindigital`), lalu jalankan command ini:

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

> **Catatan:** Jangan tutup terminal ini selama aplikasi digunakan.

## 3. Konfigurasi Flutter
Saya sudah mengubah file `lib/core/config/api_config.dart` menjadi:
```dart
static const String baseUrl = 'http://192.168.158.253:8000/api';
```
Jika IP Laptop Anda berubah (misal ganti WiFi), Anda harus mengubah angka `192.168.158.253` di file tersebut sesuai IP baru. Cara cek IP: buka CMD ketik `ipconfig`.

## 4. Install ke HP
1. Hubungkan HP ke Laptop dengan kabel USB.
2. Aktifkan **USB Debugging** di HP (Developer Options).
3. Jalankan aplikasi dari VS Code atau terminal:
   ```bash
   flutter run -d <id_device_hp>
   ```
   Atau tekan tombol "Play" di VS Code dan pilih HP Anda.

## Troubleshooting
Jika masih tidak bisa connect:
1. **Firewall Windows**: Matikan sementara Firewall Windows atau izinkan port 8000.
   - Cara cepat: Buka "Windows Defender Firewall" -> "Turn Windows Defender Firewall on or off" -> Matikan keduanya (Ingat nyalakan lagi nanti).
2. **Ping**: Coba download aplikasi Terminal di HP, lalu ketik `ping 192.168.158.253`. Jika tidak connect, berarti jaringan memblokir komunikasi antar perangkat.
