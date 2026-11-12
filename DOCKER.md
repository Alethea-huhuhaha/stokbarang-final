# Deploy dengan Docker Compose

Setup ini menjalankan:

| Service      | Image                 | Fungsi                              |
|--------------|-----------------------|-------------------------------------|
| `web`        | PHP 8.2 + Apache      | Web server (`pariwisata`, `stokbarang`) |
| `db`         | MariaDB 11.4          | Database `stokbarang`                |
| `phpmyadmin` | phpMyAdmin 5          | Opsional, hanya untuk maintenance    |

> Folder XAMPP (`xampp/`, `webalizer/`, `dashboard/`), `docker/`, dan `.env`
> **tidak** di-mount ke container, jadi tidak bisa diakses dari browser.

---

## 1. Persiapan

Di server, pastikan Docker + Docker Compose plugin sudah terpasang:

```bash
docker --version
docker compose version
```

Copy file environment lalu ubah password-nya:

```bash
cp .env.example .env
nano .env
```

Isi minimal yang **wajib diganti**:

```env
DB_ROOT_PASSWORD=password-root-yang-kuat
DB_PASSWORD=password-app-yang-kuat
APP_PORT=8080
```

## 2. Jalankan

```bash
docker compose up -d --build
```

Cek status dan log:

```bash
docker compose ps
docker compose logs -f web
```

Akses:

- Landing page : `http://IP-SERVER:8080/`
- Stok Barang  : `http://IP-SERVER:8080/stokbarang/`
- Pariwisata   : `http://IP-SERVER:8080/pariwisata/`

Login awal stokbarang (dari schema bawaan):

```
email    : admin@example.com
password : admin123
```

**Segera ganti** akun tersebut, karena `login.php` masih menyimpan password
sebagai plain-text. Kalau database Anda hasil import dari XAMPP, gunakan akun
yang sudah ada di tabel `login`.

## 3. Import database yang sudah ada (XAMPP lama)

Schema awal hanya dipakai jika volume database masih kosong.

### Cara A — sebelum `docker compose up` pertama

1. Export database lokal:

   ```bash
   mysqldump -u root stokbarang > stokbarang.sql
   ```

   Windows (cmd):

   ```bat
   C:\xampp\mysql\bin\mysqldump.exe -u root stokbarang > stokbarang.sql
   ```

2. Copy `stokbarang.sql` ke folder `docker/initdb/`.
3. Baru jalankan `docker compose up -d --build`.
4. Setelah import selesai, file dump boleh dihapus dari `docker/initdb/`.

### Cara B — database sudah berjalan

```bash
docker compose cp stokbarang.sql db:/tmp/stokbarang.sql
docker compose exec db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" stokbarang < /tmp/stokbarang.sql'
```

Jika dump berisi `CREATE DATABASE` sendiri, hilangkan nama database di akhir
perintah atau import tanpa argumen database.

## 4. phpMyAdmin (opsional)

```bash
docker compose --profile tools up -d
```

Buka `http://IP-SERVER:8081` dan login dengan user database dari `.env`.
Matikan lagi setelah selesai:

```bash
docker compose --profile tools stop phpmyadmin
```

Jangan biarkan phpMyAdmin terbuka ke internet.

## 5. Perintah harian

```bash
docker compose logs -f          # lihat log
docker compose restart web      # restart web
docker compose down             # stop (data DB tetap ada di volume)
docker compose up -d            # start lagi
docker compose build --no-cache # rebuild image PHP
```

## 6. Backup & restore

Backup:

```bash
docker compose exec -T db sh -c 'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --databases "$MARIADB_DATABASE"' > backup-$(date +%F).sql
```

Restore:

```bash
docker compose cp backup-2026-01-01.sql db:/tmp/restore.sql
docker compose exec db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" < /tmp/restore.sql'
```

## 7. Update kode aplikasi

Karena source di-mount sebagai volume read-only, cukup ganti file di server
lalu restart web:

```bash
docker compose restart web
```

Tidak perlu rebuild image, kecuali mengubah `docker/php/Dockerfile`.

## 8. Catatan keamanan untuk production

1. Ganti semua password default di `.env` dan akun login aplikasi.
2. Jangan publish port database (sudah tidak di-publish secara default).
3. Gunakan reverse proxy (Nginx/Caddy/Traefik) + HTTPS di depan port `8080`.
4. Jangan aktifkan phpMyAdmin dalam jangka panjang.
5. Backup volume `db_data` secara berkala.
6. Hapus/rename `stokbarang/database_update.sql` dari server jika sudah tidak dipakai.
