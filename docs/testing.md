# PucungHub Testing Plan

Testing mengikuti Definition of Done pada `docs/PUCUNGHUB_SPEC.txt`.

## Definition of Done

Setiap fitur harus memenuhi:

- Fungsi utama berjalan.
- UI tidak rusak pada mobile dan desktop.
- Data tersimpan dan diambil dengan benar.
- Permission dasar telah diuji.
- Error ditampilkan ketika terjadi kesalahan.
- Happy path, invalid input, unauthorized access, empty state, dan mobile test dilakukan.
- Fitur didokumentasikan.

## Attendance Scenarios

1. User berada dalam radius studio: `CHECK-IN SUCCESS`.
2. User berada di luar radius: `CHECK-IN REJECTED`.
3. GPS tidak diberikan: `LOCATION REQUIRED`.
4. User check-in dua kali: `ALREADY CHECKED IN`.

## Task, Submission, dan Review Scenarios

1. Art Director membuat task, lalu task muncul pada assignee.
2. Intern submit task, lalu status menjadi `SUBMITTED` atau `REVIEW`.
3. Art Director meminta revision, lalu status menjadi `REVISION`.
4. Intern resubmission, lalu submission baru tercatat dan histori lama tetap ada.
5. Art Director approve, lalu status task menjadi `APPROVED`.

## Phase 0 Check

Phase 0 hanya memvalidasi struktur, dokumentasi, environment example, dan komponen UI generik. Tidak ada pengujian workflow bisnis karena workflow tersebut belum dibuat.
