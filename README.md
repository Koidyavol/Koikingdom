# Koi Kingdom

Proyek simulasi kehidupan dan kerajaan original untuk Android native, dibangun dengan Godot 4 dan GDScript. Arah desainnya adalah dunia otonom dengan empat kerajaan, penduduk yang memiliki kehidupan sendiri, keluarga lintas generasi, pemerintahan, ekonomi, petualangan, dungeon, crafting, dan event.

## Fondasi yang sedang dibangun

- Godot 4, GDScript, renderer GL Compatibility untuk jangkauan perangkat Android yang lebih luas.
- Empat kerajaan data-driven: Asteria, Mizuhara, Verdantia, dan Drakemont.
- Waktu dunia: 2 menit dalam game per 1 detik nyata.
- Simulasi ekonomi harian awal: pangan, pajak, kas kerajaan, stabilitas, dan pertumbuhan penduduk.
- Simpanan JSON berversi dengan file sementara dan cadangan.
- Offline progress dibatasi maksimal 2 jam nyata per sesi agar pemrosesan tetap terkendali.
- UI saat ini adalah panel prototipe untuk memeriksa data empat kerajaan; belum merupakan tampilan game final.

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
tests/
  smoke_test.gd
~~~

## Keputusan teknis

1. **Data simulasi dipisah dari UI.** WorldManager menyimpan dan memproses keadaan kerajaan; main.gd hanya menampilkan ringkasan dan mengatur save.
2. **Waktu disimpan sebagai total menit integer.** Ini menghindari drift kalender dan memudahkan catch-up offline.
3. **Offline progress dibatasi.** Maksimal dua jam waktu nyata diproses saat kembali membuka game. Batas ini bisa diubah setelah biaya simulasi NPC diketahui.
4. **Save memiliki cadangan.** Data ditulis ke file sementara, save lama dipindahkan menjadi backup, lalu file baru dipasang.
5. **Batas data diterapkan saat load dan simulasi.** Pajak, stabilitas, populasi, pangan, dan kas memiliki rentang agar ekonomi tidak melonjak tanpa batas.

## Menjalankan dan menguji

Dengan Godot 4.3 atau versi Godot 4 yang kompatibel:

~~~bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/smoke_test.gd
godot --path .
~~~

Smoke test memeriksa jumlah kerajaan, validitas data awal, perpindahan satu hari simulasi, konversi waktu offline, dan batas offline dua jam.

## Status

Fondasi simulasi kerajaan ini belum menjadi APK dan belum diuji pada perangkat Android. Tahap berikutnya adalah memisahkan data warga/NPC menjadi model tersendiri, lalu menghubungkan pekerjaan, kebutuhan, jadwal, dan relasi ke simulasi harian tanpa menaruh logika itu di UI.
