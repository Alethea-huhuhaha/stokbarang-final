# Web Applications (htdocs)

Kumpulan aplikasi web PHP yang dijalankan di atas **Apache + PHP 8.2** dan
**MariaDB 11** menggunakan Docker Compose.

Project ini berisi dua aplikasi utama:

| Aplikasi | Path | Deskripsi |
|---|---|---|
| **Stok Barang** | `/stokbarang/` | Manajemen stok barang: kategori, barang masuk/keluar, laporan, dan dashboard. Membutuhkan database. |
| **Pariwisata** | `/pariwisata/` | Website profil wisata Lampung (HTML/CSS/JS + data PHP statis). |
| **Landing page** | `/` | Halaman sederhana yang menautkan ke kedua aplikasi di atas. |

Halaman landing untuk deployment Docker berada di `docker/site/index.php`,
sehingga file `index.php` bawaan XAMPP tidak dipakai di container.

---

## Daftar Isi

1. [Teknologi](#teknologi)
2. [Struktur Project](#struktur-project)
3. [Prasyarat Server](#prasyarat-server)
4. [Instalasi Pertama Kali](#instalasi-pertama-kali)
5. [Konfigurasi Environment](#konfigurasi-environment)
6. [Update Project](#update-project)
7. [Perintah Harian](#perintah-harian)
8. [Backup & Restore](#backup--restore)
9. [Troubleshooting](#troubleshooting)
10. [Keamanan](#keamanan)
11. [Development Lokal](#development-lokal)

---

## Teknologi

- PHP **8.2** + Apache (`php:8.2-apache`)
- Ekstensi PHP: `mysqli`, `pdo_mysql`, `opcache`
- MariaDB **11.4**
- Docker Compose (Compose v2)
- phpMyAdmin 5 (opsional, hanya untuk maintenance)

---

## Struktur Project

```text
htdocs/
├── docker-compose.yml          # Definisi service web, db, phpMyAdmin
├── .env.example                # Template konfigurasi (copy ke .env)
├── DOCKER.md                   # Dokumentasi operasional tambahan
├── README.md                   # File ini
├── docker/
│   ├── php/
│   │   ├── Dockerfile          # Image PHP + ekstensi
│   │   ├── php.ini             # Konfigurasi PHP
│   │   └── apache.conf         # Konfigurasi Apache
│   ├── initdb/
│   │   └── 01-schema.sql       # Schema awal database (hanya saat volume kosong)
│   └── site/
│       └── index.php           # Landing page
├── stokbarang/                 # Aplikasi stok barang (PHP + MySQL)
├── pariwisata/                 # Website pariwisata
├── img/                        # Aset gambar
└── favicon.ico
```

Folder bawaan XAMPP seperti `xampp/`, `webalizer/`, dan `dashboard/` **tidak
di-mount** ke container, sehingga tidak dapat diakses dari browser.

---

## Prasyarat Server

- VPS/server Linux (Ubuntu 22.04/24.04 direkomendasikan)
- Minimal **1 vCPU, 1 GB RAM, 10 GB disk**
- Docker Engine 24+ dan Docker Compose v2
- Port yang akan dipakai sudah dibuka di firewall (default `8080`)

Cek versi:

```bash
docker --version
docker compose version
```

Jika Docker belum terpasang di Ubuntu:

```bash
# Install Docker Engine + plugin compose
curl -fsSL https://get.docker.com | sudo sh

# Agar tidak perlu sudo setiap menjalankan docker
sudo usermod -aG docker "$USER"
newgrp docker
```

---

## Instalasi Pertama Kali

### 1. Ambil source code

Jika project ada di Git:

```bash
sudo mkdir -p /var/www/htdocs
sudo chown "$USER":"$USER" /var/www/htdocs
git clone <URL-REPO-ANDA> /var/www/htdocs
cd /var/www/htdocs
```

Jika tidak memakai Git, upload folder project dari komputer lokal:

```bash
# contoh dari komputer lokal (Linux/macOS)
rsync -avz ./ user@IP-SERVER:/var/www/htdocs/
```

> Pastikan folder `stokbarang/`, `pariwisata/`, `docker/`, `docker-compose.yml`,
> dan `.env.example` ikut ter-upload. Jangan upload folder `xampp/`,
> `webalizer/`, dan `dashboard/` karena tidak dipakai.

### 2. Buat file `.env`

```bash
cd /var/www/htdocs
cp .env.example .env
nano .env
```

Ganti minimal password database:

```env
APP_PORT=8080
DB_ROOT_PASSWORD=password-root-yang-kuat
DB_DATABASE=stokbarang
DB_USERNAME=stokbarang
DB_PASSWORD=password-app-yang-kuat
```

### 3. Import database lama (opsional)

Jika ini deployment baru tanpa data, lewati langkah ini — schema awal akan
dibuat otomatis.

Jika sudah punya database dari XAMPP:

```bash
# di komputer lokal
mysqldump -u root stokbarang > stokbarang.sql

# upload ke server
scp stokbarang.sql user@IP-SERVER:/tmp/
```

**Cara A — sebelum container pertama kali dibuat:**

```bash
# di server
cp /tmp/stokbarang.sql /var/www/htdocs/docker/initdb/
cd /var/www/htdocs
docker compose up -d --build
```

Script di `docker/initdb/` hanya dijalankan saat volume database **masih
kosong**. Setelah import berhasil, hapus dump dari folder tersebut.

**Cara B — container sudah berjalan:**

```bash
cd /var/www/htdocs
docker compose cp /tmp/stokbarang.sql db:/tmp/stokbarang.sql
docker compose exec db sh -c \
  'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" stokbarang < /tmp/stokbarang.sql'
```

### 4. Jalankan aplikasi

```bash
cd /var/www/htdocs
docker compose up -d --build
```

Tunggu beberapa saat sampai database sehat, lalu cek status:

```bash
docker compose ps
docker compose logs -f web
```

### 5. Verifikasi

Buka di browser:

- `http://IP-SERVER:8080/` → landing page
- `http://IP-SERVER:8080/stokbarang/` → aplikasi stok barang
- `http://IP-SERVER:8080/pariwisata/` → website pariwisata

Login awal **stokbarang** (hanya jika database dibuat dari schema bawaan):

```text
Email    : admin@example.com
Password : admin123
```

Segera ganti akun tersebut setelah login pertama.

### 6. (Opsional) phpMyAdmin

```bash
docker compose --profile tools up -d
```

Akses `http://IP-SERVER:8081`, login memakai user database dari `.env`.
Matikan kembali setelah selesai:

```bash
docker compose --profile tools stop phpmyadmin
```

---

## Konfigurasi Environment

Semua konfigurasi dibaca dari file `.env` di root project.

| Variabel | Default | Keterangan |
|---|---|---|
| `APP_PORT` | `8080` | Port website di host |
| `PMA_PORT` | `8081` | Port phpMyAdmin di host |
| `TZ` | `Asia/Jakarta` | Zona waktu container |
| `DB_ROOT_PASSWORD` | – | Password root MariaDB |
| `DB_DATABASE` | `stokbarang` | Nama database aplikasi |
| `DB_USERNAME` | `stokbarang` | User database aplikasi |
| `DB_PASSWORD` | – | Password user database aplikasi |

> **Penting:** `DB_PASSWORD` dan `DB_USERNAME` hanya dipakai saat volume
> database pertama kali dibuat. Jika diubah setelah database ada, password di
> dalam database tidak ikut berubah. Gunakan `ALTER USER` di MariaDB atau
> buat ulang volume (data akan hilang).

Contoh mengubah password user database yang sudah berjalan:

```bash
docker compose exec -T db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD"' <<'SQL'
ALTER USER 'stokbarang'@'%' IDENTIFIED BY 'password-baru';
SQL
```

Lalu sesuaikan `DB_PASSWORD` di `.env` dan jalankan `docker compose up -d`.

---

## Update Project

### Sebelum update: backup

Selalu buat backup database sebelum melakukan update:

```bash
cd /var/www/htdocs
mkdir -p backup
docker compose exec -T db sh -c \
  'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --databases "$MARIADB_DATABASE"' \
  > "backup/db-$(date +%F-%H%M).sql"

# backup file .env juga
cp .env "backup/env-$(date +%F-%H%M).bak"
```

### 1. Update kode aplikasi

**Jika memakai Git:**

```bash
cd /var/www/htdocs
git pull origin main   # sesuaikan dengan nama branch Anda
```

**Jika memakai rsync dari lokal:**

```bash
rsync -avz --delete \
  --include='docker/initdb/01-schema.sql' \
  --exclude='docker/initdb/*.sql' \
  --exclude='.env' \
  ./ user@IP-SERVER:/var/www/htdocs/
```

> `--delete` akan menghapus file di server yang tidak ada di lokal. Pastikan
> `.env` dan dump database sudah di-exclude seperti contoh di atas.

### 2. Terapkan perubahan

| Perubahan | Perintah |
|---|---|
| Hanya file PHP/CSS/JS/HTML | `docker compose restart web` |
| `docker-compose.yml` berubah | `docker compose up -d` |
| `Dockerfile`, `php.ini`, `apache.conf` berubah | `docker compose build --pull && docker compose up -d` |
| Image MariaDB/phpMyAdmin ingin diperbarui | `docker compose pull db phpmyadmin && docker compose up -d` |

Karena source di-mount sebagai volume, perubahan file PHP biasanya langsung
terlihat. Restart web disarankan agar cache opcache dibersihkan. Jika yang
berubah adalah konfigurasi container, gunakan `docker compose up -d`.

### 3. Update schema database (jika ada)

Script di `docker/initdb/` **tidak** dijalankan ulang pada database yang sudah
ada. Jalankan migration secara manual:

```bash
docker compose cp migration.sql db:/tmp/migration.sql
docker compose exec db sh -c \
  'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE" < /tmp/migration.sql'
```

Untuk update fitur dashboard/kategori/laporan, gunakan file yang sudah ada:

```bash
docker compose cp stokbarang/database_update.sql db:/tmp/update.sql
docker compose exec db sh -c \
  'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" stokbarang < /tmp/update.sql'
```

### 4. Verifikasi setelah update

```bash
docker compose ps
docker compose logs -f --tail=100 web
curl -I http://localhost:8080/
```

Cek halaman utama, login, dashboard, dan laporan.

### 5. Rollback

Kode:

```bash
git log --oneline -5
git checkout <commit-sebelumnya>
docker compose up -d
```

Database:

```bash
docker compose cp backup/db-2026-01-01-1200.sql db:/tmp/restore.sql
docker compose exec db sh -c \
  'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" < /tmp/restore.sql'
```

---

## Perintah Harian

```bash
docker compose ps                  # status container
docker compose logs -f web         # log web
docker compose logs -f db          # log database
docker compose restart web         # restart web
docker compose stop                # stop semua container
docker compose start               # start lagi
docker compose down                # hapus container (volume DB tetap)
docker compose up -d               # buat/update container
docker compose config              # validasi & lihat konfigurasi final
```

Menjalankan shell di container:

```bash
docker compose exec web bash
docker compose exec db mariadb -ustokbarang -p stokbarang
```

---

## Backup & Restore

### Backup database

```bash
docker compose exec -T db sh -c \
  'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --databases "$MARIADB_DATABASE"' \
  > "backup/db-$(date +%F-%H%M).sql"
```

### Restore database

```bash
docker compose cp backup/db-2026-01-01-1200.sql db:/tmp/restore.sql
docker compose exec db sh -c \
  'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" < /tmp/restore.sql'
```

### Backup seluruh project (kecuali data container)

```bash
tar -czf htdocs-$(date +%F).tar.gz \
  --exclude='docker/initdb/*.sql' \
  --exclude='backup' \
  .
```

Backup volume database juga bisa dilakukan dengan volume export, tetapi cara
`mariadb-dump` di atas lebih mudah dipindahkan antar server.

Jadwalkan backup otomatis dengan cron, misalnya setiap hari pukul 02:00:

```cron
0 2 * * * cd /var/www/htdocs && docker compose exec -T db sh -c 'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --databases "$MARIADB_DATABASE"' > backup/db-$(date +\%F).sql
```

---

## Troubleshooting

### `port is already allocated`

Port host sudah dipakai proses lain. Cek:

```bash
sudo ss -tlnp | grep :8080
```

Solusi: ubah `APP_PORT` di `.env`, lalu `docker compose up -d`, atau hentikan
service yang memakai port tersebut.

### Container `web` jalan tapi database gagal connect

```bash
docker compose ps
docker compose logs db
```

Pastikan:

- Service `db` berstatus `healthy`
- `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD` di `.env` sama dengan yang
  dipakai container database
- Jika password diubah setelah volume DB dibuat, lihat bagian
  [Konfigurasi Environment](#konfigurasi-environment)

Tes koneksi dari container web:

```bash
docker compose exec web php -r \
  '$c = mysqli_connect("db", getenv("DB_USER"), getenv("DB_PASS"), getenv("DB_NAME")); echo $c ? "OK\n" : "GAGAL\n";'
```

### Error 500 / halaman kosong

```bash
docker compose logs -f web
```

`display_errors` dimatikan di production, jadi error PHP masuk ke log
container. Untuk debugging sementara, ubah `display_errors = On` di
`docker/php/php.ini`, lalu `docker compose restart web`.

### Error permission / 403

Pastikan file dapat dibaca user `www-data` di container:

```bash
sudo chmod -R a+rX /var/www/htdocs
```

Jangan memberi permission `777`.

### Perubahan file tidak muncul

Karena volume di-mount read-only, pastikan file diedit di host (bukan di dalam
container). Bersihkan cache opcache dengan restart:

```bash
docker compose restart web
```

### Database ter-reset / data hilang

`docker compose down -v` akan menghapus volume `db_data` beserta seluruh data.
Gunakan `docker compose down` tanpa `-v` untuk mempertahankan data.

---

## Keamanan

- Ganti semua password default di `.env` dan akun aplikasi.
- Jangan publish port database ke internet. Secara default port DB tidak
  di-publish.
- Aktifkan HTTPS melalui reverse proxy (Nginx, Caddy, atau Traefik) di depan
  port `8080`.
- Jangan biarkan phpMyAdmin aktif dalam jangka panjang.
- Batasi akses SSH dan gunakan firewall (UFW/security group).
- Backup database secara rutin dan simpan di lokasi terpisah.
- **Catatan teknis:** `stokbarang/login.php` masih menyimpan password sebagai
  plain-text dan menyusun query login dengan string interpolation. Sebelum
  dipakai publik, disarankan migrasi ke `password_hash()`/`password_verify()`
  dan prepared statement.
- Hapus `docker/initdb/*.sql` yang berisi data asli setelah import.

---

## Development Lokal

Untuk menjalankan di komputer lokal:

```bash
cp .env.example .env
docker compose up -d --build
```

Buka `http://localhost:8080`.

Jika ingin mengedit kode langsung dari host, volume sudah ter-mount, jadi
perubahan langsung terlihat. Untuk menghentikan:

```bash
docker compose down
```

Dokumentasi operasional tambahan tersedia di [`DOCKER.md`](DOCKER.md).
