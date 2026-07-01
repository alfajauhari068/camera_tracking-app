# PROJECT-SRS.md

# Camera Tracking GPS System Requirement Specification

## Project Information

Project Name:
Camera Tracking GPS

Project Type:
Flutter Mobile Application

Platform:
Android

Architecture:
Clean Architecture + Feature First + Modular Structure

---

## Project Goal

Membangun aplikasi dokumentasi lapangan berbasis kamera yang mampu:

* Mengambil foto
* Mengambil video
* Tracking objek
* Menyimpan koordinat GPS
* Menambahkan metadata
* Menampilkan AI detection
* Mendukung penggunaan outdoor

---

## Critical Functional Requirements

FR-001

Sistem harus menampilkan Camera Preview secara realtime.

FR-002

Sistem harus menyimpan:

* latitude
* longitude
* timestamp
* device information
* image metadata

FR-003

Sistem harus mendukung mode:

* Photo
* Video
* Tracking
* Detection

FR-004

Sistem harus mendukung zoom:

* Wide
* Standard
* Tele

FR-005

Sistem harus mendukung AI object tracking overlay.

---

## Critical UI Rules

Camera Preview:

* minimal 85% layar
* tidak boleh tertutup panel permanen

Top Bar:

* fixed
* tinggi maksimal 56dp

Bottom Controls:

* fixed
* tidak boleh overlap

Overlay:

* transparan
* tidak boleh menghalangi objek utama

Zoom Slider:

* tersembunyi secara default
* tampil saat ditekan
* auto hide 5 detik

---

## Critical Architecture Rules

Dilarang:

* business logic dalam widget
* nested Stack > 3 level
* hardcoded position
* hardcoded padding
* full-screen transparent container
* GestureDetector fullscreen

Wajib:

* reusable widget
* responsive widget
* state management terpisah
* service layer terpisah
