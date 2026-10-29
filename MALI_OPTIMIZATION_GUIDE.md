# Panduan Optimasi & Konfigurasi Mali GPU (Samsung Exynos / Mali-G78)

Dokumen ini berisi panduan konfigurasi, penjelasan teknis, dan perbaikan performa untuk **Forza Horizon 2 Recompiled** pada perangkat ber-GPU **ARM Mali** dan chipset **Samsung Exynos / MediaTek Dimensity**, khususnya diuji pada:

- **Perangkat Uji:** Samsung Galaxy S21 FE 5G (`SM-G990E`)
- **SoC:** Samsung Exynos 2100 (1x Cortex-X1 @ 2.9 GHz + 3x Cortex-A78 @ 2.8 GHz + 4x Cortex-A55 @ 2.2 GHz)
- **GPU:** ARM Mali-G78 MP14 (Vulkan 1.1.213 / Driver ArmProprietary v1.r38p0)
- **Sistem Operasi:** Android 16 (API 36)

---

## 1. Perbaikan Bug CPU Affinity (Core Affinity Fix)

### Masalah Asli:
Pada SoC dengan konfigurasi cluster **1 + 3 + 4** (seperti Exynos 2100, Snapdragon 888, dan Google Tensor):
- **Core 7:** Cortex-X1 (Kapasitas 1024 - Prime Core)
- **Core 4, 5, 6:** Cortex-A78 (Kapasitas 871 - Big Cores)
- **Core 0, 1, 2, 3:** Cortex-A55 (Kapasitas 202 - Little Cores hemat daya)

Di versi sebelumnya, fungsi `OtherCores()` di `android/app/src/main/cpp/android_rendimiento.cpp` memiliki batas minimum `kMinGameCores = 3`. 
Ketika mode `jogo-rapido` aktif:
- Core 7 dialokasikan untuk thread utama game.
- Core 6 dialokasikan untuk worker Vulkan (`GPU anillo nati`).
- Sisa Big Core yang tersedia hanya **2** (Core 4 dan 5). Karena `2 < 3`, sistem menganggap core kencang tidak mencukupi dan membuang semua thread lainnya ke fallback `every` (`0+1+2+3+4+5`).

Akibatnya, thread komputasi dan emulasi terlempar ke **Cortex-A55 (Core 0–3)** yang 5x lebih lambat. Di saat yang sama, Core 7 dipaksa berjalan pada 100% beban kerja hingga memicu panas baterai > 40.5 °C (`termico 1.00`). Samsung DVFS kemudian mencekik (thermal throttle) kecepatan seluruh CPU hingga **900 MHz**, menyebabkan FPS drop drastis dari 60 FPS ke **0.6 – 1.0 FPS**.

### Solusi di Build Ini:
Nilai `kMinGameCores` telah disesuaikan menjadi `2`. Sisa thread game kini terkunci penuh di **Core 4 + Core 5 (Cortex-A78 @ 2.8 GHz)** dan tidak akan pernah dibuang ke Core hemat daya (A55).

---

## 2. Karakteristik GPU ARM Mali (TBDR Architecture)

GPU Mali menggunakan arsitektur **Tile-Based Deferred Rendering (TBDR)**:
1. **Hindari MSAA (Multi-Sample Anti-Aliasing):**
   - Resolving multi-sample pada TBDR GPU menghabiskan bandwidth memory internal dan memicu lonjakan panas. Gunakan **Anti-Aliasing = Off** atau **FXAA**.
2. **Kerapatan Rumput & Objek (*World Grass*):**
   - Game Forza Horizon 2 memiliki geometri vegetasi yang sangat padat. Pada GPU Mali, disarankan mengatur `World Grass` ke **0.25** atau **Off (0)** untuk memangkas ribuan draw call yang membebani command buffer Vulkan.
3. **Penyelarasan VSync / Refresh Rate:**
   - Memilih `fps = 0` (unlimited) memaksa vblank berjalan pada **240 Hz**, menyebabkan CPU berputar pada siklus spin-lock 100%. Batasi ke **30 FPS** atau **60 FPS** agar CPU memiliki jeda tidur (*sleep interval*) dan tidak terkena thermal throttling.

---

## 3. Setelan Launcher Terbaik (Recommended Settings)

Untuk mendapatkan gameplay yang stabil, dingin, dan bebas stuttering di Samsung Galaxy S21 FE / GPU Mali:

### A. Tampilan & Layar (Display)
- **Resolution:** `480p` atau `720p`
- **Render Scale:** `70%` – `100%`
- **Present Mode:** `FIFO (vsync)`
- **FPS Limit:** **`30`** (Sangat stabil & dingin) atau **`60`** (Maksimum performa)
  *(Peringatan: Hindari opsi `0 / Unlimited` agar HP tidak overheat!)*

### B. Grafis (Graphics)
- **Renderer:** `Native` (Menggunakan library `fh2_shaders.nfsp`)
- **Anti-Aliasing:** `Off`
- **World Grass (Rumput):** `0.25` atau `Off (0)`
- **World Shadows (Bayangan):** `0.5` atau `1.0`
- **Shadow Map Scale:** `50%` atau `Off (0)`
- **Reflection Stagger:** `On` (Merender kubus pantulan mobil secara bergantian per frame)

### C. Kinerja & Prosesor (Performance)
- **Pin Threads (Kunci Core):** `On`
- **Jogo Rápido:** `Off` (Rekomendasi: gunakan mode **Auto** bawaan agar thread render Vulkan ditempatkan di Cortex-X1 Core 7).
- **Vertex Cache:** `On`
- **Index Cache:** `On`
- **Vertex No Wait:** `On`
- **Tight Area:** `On`
