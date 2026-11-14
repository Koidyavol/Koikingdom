# Koi Kingdom

Prototipe game simulasi kehidupan kerajaan berbasis Godot 4 untuk Android. Proyek ini masih dikembangkan bertahap; fitur di bawah adalah yang sudah ada di source saat ini, bukan klaim bahwa seluruh dunia open-world telah selesai.

## Fitur prototipe saat ini

- Antarmuka utama dengan halaman Map, Job, Karakter, dan Profil.
- Profil karakter dan beberapa NPC bernama.
- Pendaftaran murid serta pencatatan kegiatan Akademi.
- Pendaftaran petualang, misi guild sederhana, poin, dan peringkat.
- Ekspedisi dungeon otomatis dengan pertarungan turn-based.
- Ekspor Android melalui preset Godot dan GitHub Actions.

## Penyimpanan

Semua data persisten prototipe disimpan terpusat di `user://world_state.json` melalui autoload `SaveManager`.

Bagian data saat ini:
- `academy`: daftar murid dan pemeriksaan jadwal sekolah.
- `guild`: anggota, poin, misi selesai, dan misi aktif.
- `dungeon`: ekspedisi aktif, hasil, hadiah, dan riwayat.

Saat pertama kali dijalankan setelah pembaruan, `SaveManager` mencoba memigrasikan data lama dari `academy.cfg`, `guild.cfg`, dan `dungeon.cfg`. File lama tidak dihapus. Penulisan JSON memakai file sementara dan file cadangan agar save sebelumnya dapat dipulihkan jika penulisan terganggu.

## Struktur penting

- `project.godot`: konfigurasi Godot dan autoload.
- `scenes/main.tscn`: scene utama.
- `scripts/main.gd`: antarmuka dan alur fitur prototipe saat ini.
- `scripts/autoload/save_manager.gd`: penyimpanan JSON terpusat dan migrasi data lama.
- `export_presets.cfg`: preset ekspor Android.

Build Android memakai debug keystore yang disimpan melalui GitHub Actions cache agar tanda tangan APK tetap sama pada build berikutnya. Build pertama setelah cache diperkenalkan memakai kunci baru, jadi mungkin perlu memasang ulang sekali. Kunci ini hanya untuk build pengembangan, bukan rilis produksi.

## Cara menguji penyimpanan

1. Buka proyek dengan Godot 4.4.1.
2. Jalankan scene utama.
3. Tambahkan murid di Akademi, daftarkan anggota Guild, lalu mulai atau selesaikan ekspedisi Dungeon.
4. Tutup aplikasi sepenuhnya dan jalankan kembali.
5. Pastikan data Akademi, anggota Guild, poin, dan riwayat Dungeon tetap tersedia.
6. Pada instalasi lama yang memiliki file `.cfg`, pastikan data lama terbaca setelah pembaruan pertama.

## Batasan yang masih terbuka

Prototipe saat ini belum menjadi simulasi kerajaan open-world penuh. Dunia isometrik yang dapat dijelajahi, pergerakan karakter di dunia, simulasi kebutuhan dan jadwal warga secara umum, struktur pemerintahan, ekonomi kerajaan, serta sistem generasi NPC masih perlu dibangun sebagai modul terpisah.
