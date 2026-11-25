# Koi Kingdom

Proyek simulasi kehidupan dan kerajaan original untuk Android native, dibangun dengan Godot 4 dan GDScript. Arah desainnya adalah dunia otonom dengan empat kerajaan, penduduk yang memiliki kehidupan sendiri, keluarga lintas generasi, pemerintahan, ekonomi, petualangan, dungeon, crafting, dan event.

## Fondasi yang sedang dibangun

- Godot 4, GDScript, renderer GL Compatibility untuk jangkauan perangkat Android yang lebih luas.
- Empat kerajaan data-driven: Asteria, Mizuhara, Verdantia, dan Drakemont.
- Waktu dunia: 2 menit dalam game per 1 detik nyata.
- Simulasi ekonomi harian awal: pangan, pajak, kas kerajaan, stabilitas, dan pertumbuhan penduduk.
- Roster 12 warga contoh (3 per kerajaan) dengan ID unik, nama, usia, pekerjaan, gender, ras, kepribadian, dan kebutuhan.
- Jadwal otonom berbasis pekerjaan: petani, pedagang, penjaga, tabib, dan pelajar; kebutuhan hunger, energy, dan social berubah per menit game.
- Save JSON berversi dengan file sementara dan cadangan, termasuk roster dan kebutuhan warga.
- Offline progress clock dibatasi maksimal 2 jam waktu nyata (10 hari game). Catch-up warga dibatasi 14.400 menit game agar batasnya selaras dengan clock offline dan tetap menjaga performa.
- UI saat ini adalah panel prototipe untuk memeriksa ekonomi kerajaan dan jumlah warga contoh berdasarkan aktivitas; belum merupakan tampilan game final.

## Struktur

~~~text
project.godot
scenes/
  main.tscn
scripts/
  main.gd
  autoload/
    save_manager.gd
    simulation_clock.gd
    world_manager.gd
    citizen_manager.gd
tests/
  smoke_test.gd
~~~

## Keputusan teknis

1. **Data simulasi dipisah dari UI.** WorldManager mengurus ekonomi kerajaan; CitizenManager mengurus roster dan kebutuhan warga; main.gd menampilkan ringkasan serta menghubungkan sinyal.
2. **Waktu disimpan sebagai total menit integer.** Ini menghindari drift kalender dan memudahkan catch-up offline.
3. **Roster awal sengaja kecil.** 12 warga contoh cukup untuk menguji jadwal dan save/load; bukan representasi seluruh populasi kerajaan.
4. **Offline progress dibatasi.** Maksimal dua jam waktu nyata diproses saat kembali membuka game. Catch-up warga selaras dengan batas ini, yaitu 10 hari game.
5. **Save memiliki cadangan.** Data ditulis ke file sementara, save lama dipindahkan menjadi backup, lalu file baru dipasang.
6. **Batas data diterapkan saat load dan simulasi.** Pajak, stabilitas, populasi, pangan, kas, dan kebutuhan warga memiliki rentang.

## Menjalankan dan menguji

Dengan Godot 4.3 atau versi Godot 4 yang kompatibel:

~~~bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/smoke_test.gd
godot --path .
~~~

Smoke test memeriksa jumlah kerajaan, validitas data awal, perpindahan satu hari simulasi, konversi dan batas waktu offline, roster 12 warga, ID unik, atribut gender dan ras, jadwal kerja Asteria pukul 09.00, catch-up warga hingga 10 hari, serta pemulihan roster dari data save.

## Status

Proyek masih berupa prototipe simulasi berbasis UI; belum ada sprite NPC, pergerakan warga di peta isometrik, atau APK yang diuji di perangkat. Tahap berikutnya adalah menyiapkan scene world isometric dan menghubungkan beberapa warga ini ke lokasi serta gerakan visual, tanpa mengubah engine menjadi WebView.
