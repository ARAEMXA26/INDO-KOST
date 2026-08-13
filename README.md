# 🧹 Indo Kos — Auto Clean & Utility Hub

Script Roblox Lua otomatis (Auto Clean & Utilities) khusus untuk game **Indo Kos**. Dirancang dengan sistem **Strict Boss Zone Isolation**, pembersihan 3 tahap otomatis, serta pengatur fisik karakter (WalkSpeed, JumpPower, dan Fly Mode).

---

## ⚡ Loadstring (Cara Penggunaan)

Salin dan tempel (paste) satu baris perintah di bawah ini ke executor Roblox Anda (misalnya **Opiumware** / Mac Execs):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ARAEMXA26/INDO-KOST/main/AutoCleanIndoKos.lua"))()
```

---

## ✨ Fitur Utama

### 1. 🤖 Auto Clean (Zona Kerja Bos Saja)
- **Pengecekan Status Pekerjaan Otomatis**: Memeriksa apakah Anda sudah melamar kerja sebagai petugas kebersihan sebelum Auto Clean diaktifkan. Jika belum, notifikasi peringatan akan muncul dan script tetap OFF.
- **Deteksi Zona Bos Real-Time**: Otomatis mendeteksi lokasi kosan tempat Anda melamar kerja tanpa perlu input manual/hardcode.
- **Auto Blacklist Zona Non-Bos**: Jika menyentuh kotoran milik pemain lain yang memicu peringatan *"Bukan Zona Kerjamu"*, script secara otomatis mem-blacklist area tersebut dan berpindah ke zona bos yang sah.
- **Alur Kerja 3-Tahap Otomatis**:
  1. **`Dirt Clean`**: Membersihkan seluruh noda/kotoran lantai & dinding di zona kerja.
  2. **`Garbage Take`**: Mengambil seluruh kantong/keranjang sampah di zona kerja.
  3. **`Garbage Bin Discard`**: Membawa & membuang sampah ke bak sampah (Garbage Bin).
- **Verifikasi Ganda (Double Verification)**: Script tidak akan berhenti sampai seluruh kotoran dan sampah di zona bos terverifikasi **100% Bersih & Habis Total**.

### 2. 🏃 Player Utilities & Movement Bypass
- **WalkSpeed Slider (16 – 200)**: Pengatur kecepatan jalan dengan Cframe Translate Bypass (mencegah game me-reset kecepatan karakter Anda).
- **JumpPower Slider (50 – 300)**: Pengatur tinggi lompatan dengan Assembly Linear Velocity Impulse (bypassing JumpPower locks).
- **Fly Mode & FlySpeed Slider (20 – 200)**: Fitur terbang bebas menggunakan kontrol keyboard (**WASD** + **Space** untuk naik, **LeftShift** untuk turun).
- **Auto Re-Apply**: Pengaturan fisik karakter otomatis kembali aktif saat karakter respawns/mati.

### 3. 🎨 Wide GUI Interface & Window Controls
- **Modern Wide Shape Design (480px)**: Tampilan UI gelap bergaya modern yang lebih lebar dan bersih.
- **Minimize Control (`-`)**: Melipat UI menjadi bar header tipis secara otomatis (Smooth Tweening).
- **Close Control (`X`) & Floating Icon (`IK`)**: Menyembunyikan jendela GUI dan menampilkan icon melayang **`IK`** di pinggir layar yang dapat diklik kapan saja untuk membuka kembali menu.

---

## 🛠️ Persyaratan & Executor
- **Game Target**: Roblox — *Indo Kos*
- **Executor**: Opiumware (Mac/OSX), Synapse, Hydrogen, Wave, ScriptWare, atau Executor berbasis `loadstring` & `game:HttpGet` lainnya.

---

## 📜 Lisensi & Kontribusi
Dibuat untuk memudahkan otomatisasi pembersihan kerja di game Indo Kos.
Pull requests dan masukan dipersilakan!