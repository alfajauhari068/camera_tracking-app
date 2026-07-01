# TECH-CONSTRAINTS.md

# Technical Constraints

Framework:

* Flutter 3.x

Design:

* Material Design 3

Architecture:

* Clean Architecture
* Feature First Structure

State Management:

* Riverpod

Dependency Injection:

* GetIt

Storage:

* Hive
* SharedPreferences

GPS:

* geolocator

Camera:

* camera package

Rules:

Dilarang:

* business logic di UI
* magic number
* hardcoded color
* hardcoded size
* hardcoded positioning

Wajib:

* theme centralized
* responsive layout
* reusable widget
* custom component

Performance:

* startup <2 detik
* UI rendering <16ms/frame

Security:

* permission validation
* secure local storage
