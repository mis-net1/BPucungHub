# PucungHub Security Plan

Dokumen ini mencatat rencana keamanan PucungHub v0.1. Implementasi keamanan dilakukan pada phase terkait.

## Authentication

Semua area aplikasi internal harus memerlukan login. Session Supabase Auth harus diperiksa sebelum data internal ditampilkan.

## Authorization

Permission harus diperiksa pada UI dan pada server/database. UI hanya membantu pengalaman pengguna; UI bukan batas keamanan.

Role yang digunakan spesifikasi:

- Admin
- Art Director
- Staff
- Intern

## Row Level Security

Supabase PostgreSQL wajib menggunakan RLS. Policy harus membatasi akses berdasarkan user dan role, termasuk task milik user, notification milik user, pengaturan studio untuk Admin, serta akses review dan project sesuai kewenangan.

## Storage

File upload harus memiliki batas ukuran, tipe file yang diizinkan, bucket yang sesuai, dan storage policy. File internal tidak boleh dibuat public tanpa alasan yang disetujui.

## Environment Variables

Credential disimpan di environment, bukan source code. `.env.example` hanya berisi nama variable dan tidak berisi nilai asli.

`SUPABASE_SERVICE_ROLE_KEY` hanya boleh digunakan server-side dan tidak boleh dikirim ke browser atau dimasukkan ke repository.

## GPS

Versi 0.1 memakai koordinat browser, koordinat studio, perhitungan jarak, allowed radius, timestamp, dan pencatatan hasil. GPS bukan sistem keamanan absolut karena dapat dipalsukan atau tidak akurat.

## Phase 0 Boundary

Phase 0 tidak membuat Auth, Supabase client, RLS policy, Storage policy, GPS logic, atau database migration.
