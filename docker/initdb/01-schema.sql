-- ============================================================
-- Schema awal database stokbarang
-- File ini hanya dijalankan otomatis saat volume DB masih kosong.
-- Jika sudah punya database lokal, import dump Anda (lihat DOCKER.md).
-- ============================================================

CREATE DATABASE IF NOT EXISTS `stokbarang`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `stokbarang`;

CREATE TABLE IF NOT EXISTS `login` (
    `idlogin`  INT(11) NOT NULL AUTO_INCREMENT,
    `email`    VARCHAR(100) NOT NULL,
    `password` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`idlogin`),
    UNIQUE KEY `uq_login_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kategori` (
    `idkategori`  INT(11) NOT NULL AUTO_INCREMENT,
    `namakategori` VARCHAR(50) NOT NULL,
    PRIMARY KEY (`idkategori`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `stok` (
    `idbarang`    INT(11) NOT NULL AUTO_INCREMENT,
    `namabaraang` VARCHAR(150) NOT NULL,
    `deskripsi`   TEXT NULL,
    `idkategori`  INT(11) NULL DEFAULT NULL,
    `stock`       INT(11) NOT NULL DEFAULT 0,
    `stok_minimum` INT(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (`idbarang`),
    KEY `idx_stok_kategori` (`idkategori`),
    CONSTRAINT `fk_stok_kategori`
        FOREIGN KEY (`idkategori`) REFERENCES `kategori` (`idkategori`)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `masuk` (
    `idmasuk`    INT(11) NOT NULL AUTO_INCREMENT,
    `idbarang`   INT(11) NOT NULL,
    `keterangan` VARCHAR(255) NULL,
    `qty`        INT(11) NOT NULL DEFAULT 0,
    `tanggal`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`idmasuk`),
    KEY `idx_masuk_barang` (`idbarang`),
    KEY `idx_masuk_tanggal` (`tanggal`),
    CONSTRAINT `fk_masuk_stok`
        FOREIGN KEY (`idbarang`) REFERENCES `stok` (`idbarang`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `keluar` (
    `idkeluar`  INT(11) NOT NULL AUTO_INCREMENT,
    `idbarang`  INT(11) NOT NULL,
    `penerima`  VARCHAR(255) NULL,
    `qty`       INT(11) NOT NULL DEFAULT 0,
    `tanggal`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`idkeluar`),
    KEY `idx_keluar_barang` (`idbarang`),
    KEY `idx_keluar_tanggal` (`tanggal`),
    CONSTRAINT `fk_keluar_stok`
        FOREIGN KEY (`idbarang`) REFERENCES `stok` (`idbarang`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Akun login default. SEGERA ganti setelah login pertama.
-- Password disimpan plain-text karena kode login.php masih membandingkan langsung.
INSERT INTO `login` (`email`, `password`)
SELECT 'admin@example.com', 'admin123'
WHERE NOT EXISTS (SELECT 1 FROM `login` WHERE `email` = 'admin@example.com');

-- Contoh kategori awal (boleh dihapus)
INSERT INTO `kategori` (`namakategori`)
SELECT 'Umum'
WHERE NOT EXISTS (SELECT 1 FROM `kategori` WHERE `namakategori` = 'Umum');
