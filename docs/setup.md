# PucungHub Setup Notes

Dokumen ini menjadi panduan awal untuk developer yang melanjutkan repository.

## Project

PucungHub v0.1 menggunakan Next.js, React, TypeScript, dan Tailwind CSS sesuai scaffold yang tersedia.

## Environment

Buat environment lokal berdasarkan `.env.example`. Isi credential hanya pada environment lokal atau platform deployment yang sesuai. Jangan commit nilai credential ke GitHub.

Variable yang direncanakan:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` untuk server-side saja

## Phase 0 Boundary

Phase 0 belum menyiapkan Supabase client, Auth, database schema, migration, atau fitur bisnis.

## Development Sequence

Ikuti urutan pada spesifikasi:

1. Preparation
2. Authentication
3. Dashboard
4. Attendance
5. Project
6. Task
7. Submission
8. Review
9. Notification

Setiap phase harus diuji dan didokumentasikan sebelum phase berikutnya dimulai.

## Source of Truth

`docs/PUCUNGHUB_SPEC.txt` adalah acuan utama. Fitur di luar MVP v0.1 tidak boleh ditambahkan tanpa persetujuan.
