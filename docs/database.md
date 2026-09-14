# PucungHub Database Plan

Dokumen ini adalah rencana database berdasarkan spesifikasi PucungHub v0.1. Phase 0 tidak membuat schema atau migration.

## Tabel yang Direncanakan

- `profiles`: data anggota dan role.
- `projects`: container pekerjaan studio.
- `tasks`: unit pekerjaan yang terhubung ke project dan assignee.
- `task_submissions`: setiap versi hasil pekerjaan.
- `task_reviews`: approval atau revision beserta feedback.
- `attendance`: check-in, check-out, lokasi, dan status kehadiran.
- `notifications`: notifikasi internal per user.
- `attendance_settings`: lokasi studio dan allowed radius.

## Relasi Utama

- `profiles.id` menjadi referensi untuk user pada `attendance`, `tasks`, `task_submissions`, dan `notifications`.
- `projects.id` direferensikan oleh `tasks.project_id`.
- `tasks.id` direferensikan oleh `task_submissions.task_id`.
- `task_submissions.id` direferensikan oleh `task_reviews.submission_id`.
- Field pembuat, assignee, reviewer, dan pengubah settings menggunakan relasi ke `profiles.id` sesuai kebutuhan spesifikasi.

## Aturan Data Penting

- Histori submission lama tidak boleh dihapus ketika ada submission baru.
- Progress project versi awal dihitung dari approved tasks dibagi total tasks.
- Attendance kedua pada tanggal yang sama harus ditolak.
- WFH tidak memakai validasi radius studio.
- Detail migration, tipe ID, constraint, index, dan policy RLS ditentukan pada phase database/auth yang relevan, bukan pada Phase 0.

## Hal yang Masih Memerlukan Konfirmasi

Spesifikasi modul project menyebut `project_manager` dan `art_director`, sedangkan daftar tabel `projects` hanya mencantumkan `created_by`. Perbedaan ini tidak diputuskan atau ditambahkan pada Phase 0.
