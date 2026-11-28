# Koi Kingdom

Proyek simulasi kehidupan dan kerajaan original untuk Android native, dibangun dengan Godot 4 dan GDScript. Arah desainnya adalah dunia otonom dengan empat kerajaan, penduduk yang memiliki kehidupan sendiri, keluarga lintas generasi, pemerintahan, ekonomi, petualangan, dungeon, crafting, dan event.

## Fondasi

- Godot 4, GDScript, renderer GL Compatibility.
- Empat kerajaan data-driven: Asteria, Mizuhara, Verdantia, dan Drakemont.
- Waktu dunia: 2 menit game per 1 detik nyata.
- Simulasi ekonomi harian awal: pangan, pajak, kas kerajaan, stabilitas, dan pertumbuhan penduduk.
- Roster 12 warga contoh dengan ID unik, nama, usia, pekerjaan, gender, ras, kepribadian, dan kebutuhan.
- Jadwal otonom berbasis pekerjaan dan kebutuhan hunger, energy, social.
- Save JSON berversi dengan file sementara dan cadangan.
- Offline progress clock dibatasi maksimal 2 jam waktu nyata (10 hari game); catch-up warga dibatasi selaras dengan clock.
- Peta isometrik 18×18, ketuk tanah untuk menggerakkan pemain dan ketuk warga untuk membuka profil.
- NPC bergerak menuju lokasi kerja, makan, tidur, bersosialisasi, atau santai berdasarkan aktivitas.
- Posisi pemain dan posisi visual NPC disimpan dalam bagian `map` pada save JSON.
- Visual masih placeholder bentuk/geometri; sprite anime HD belum dipasang.

## Struktur

```text
project.godot
scenes/main.tscn
scripts/main.gd
scripts/autoload/
  save_manager.gd
  simulation_clock.gd
  world_manager.gd
  citizen_manager.gd
scripts/world/
  isometric_world.gd
tests/
  smoke_test.gd
```

## Pengujian

Dengan Godot 4.3 atau versi Godot 4 yang kompatibel:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/smoke_test.gd
godot --path .
```

Smoke test memeriksa empat kerajaan, waktu offline, roster warga, jadwal kerja, catch-up dan pemulihan save. Test tambahan memeriksa 12 posisi NPC visual dan pemulihan posisi peta.

## Status

Prototipe peta dan gerakan ini bukan versi final grafis. Selanjutnya perlu asset sprite, collision/pathfinding, lokasi rumah/pekerjaan nyata, dan kontrol mobile yang lebih lengkap. APK native belum diuji pada perangkat.
