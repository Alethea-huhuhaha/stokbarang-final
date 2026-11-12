<?php
// Landing page sederhana untuk deployment Docker.
// Ganti file ini jika ingin memakai halaman utama sendiri.
$apps = [
    [
        'title' => 'Stok Barang',
        'desc'  => 'Aplikasi manajemen stok, kategori, barang masuk/keluar, dan laporan.',
        'url'   => '/stokbarang/',
    ],
    [
        'title' => 'Pariwisata',
        'desc'  => 'Website profil wisata Lampung.',
        'url'   => '/pariwisata/',
    ],
];
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Web Applications</title>
    <style>
        * { box-sizing: border-box; }
        body {
            margin: 0;
            min-height: 100vh;
            display: grid;
            place-items: center;
            padding: 40px 20px;
            font-family: "Segoe UI", Tahoma, sans-serif;
            color: #e8eefc;
            background: radial-gradient(circle at 50% 0%, #1e3a6e 0%, #081527 55%, #050d1a 100%);
        }
        main { width: min(880px, 100%); }
        h1 { margin: 0 0 8px; font-size: 1.9rem; }
        p.lead { margin: 0 0 32px; color: #9fb3d9; }
        .grid { display: grid; gap: 20px; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); }
        a.card {
            display: block;
            padding: 24px;
            border-radius: 14px;
            text-decoration: none;
            color: inherit;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.12);
            transition: transform .15s ease, border-color .15s ease;
        }
        a.card:hover { transform: translateY(-3px); border-color: #4f8cff; }
        a.card h2 { margin: 0 0 8px; font-size: 1.15rem; color: #7fb0ff; }
        a.card p { margin: 0; font-size: .92rem; line-height: 1.5; color: #b9c8e4; }
    </style>
</head>
<body>
<main>
    <h1>Web Applications</h1>
    <p class="lead">Pilih aplikasi yang ingin dibuka.</p>
    <div class="grid">
        <?php foreach ($apps as $app): ?>
            <a class="card" href="<?= htmlspecialchars($app['url'], ENT_QUOTES) ?>">
                <h2><?= htmlspecialchars($app['title']) ?></h2>
                <p><?= htmlspecialchars($app['desc']) ?></p>
            </a>
        <?php endforeach; ?>
    </div>
</main>
</body>
</html>
