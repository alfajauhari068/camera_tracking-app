/*
# ARCHITECTURE DOCUMENTATION - STEP 1

## 📐 Dependency Flow (MUST NOT BE VIOLATED)

```
UI (Presentation)
  ↓
UseCase (Domain) → CaptureTracking
  ↓ depends on
Domain Services (abstract)
  ├── CameraService (abstract)
  ├── LocationService (abstract)
  ├── GeocodingService (abstract)
  └── TrackingRepository (abstract)
  ↓ implemented by
Data Layer
  ├── TrackingLocalDataSourceImpl
  └── TrackingRepositoryImpl
  ↓ uses
Local Storage (File System)
  └── tracking.json
```

## 🔒 Layer Boundaries

### Domain Layer (/domain/)
- ✅ Contains: Entity, Service contracts, Repository contract, UseCase
- ❌ Does NOT import: anything from data layer, external packages, file I/O
- 🎯 Responsibility: Business logic orchestration

### Data Layer (/data/)
- ✅ Contains: Models, DataSources, Repository implementations
- ✅ Imports: domain layer entities and contracts
- ❌ Does NOT import: presentation layer, UI packages
- 🎯 Responsibility: Data persistence and retrieval

### Presentation Layer (/presentation/)
- ✅ Contains: Widgets, Controllers, Pages
- ✅ Imports: domain layer (UseCase only)
- 🎯 Responsibility: UI rendering

## 📋 File Structure

```
lib/features/tracking/
├── domain/
│   ├── entities/
│   │   └── tracking.dart                  # Pure entity, NO JSON
│   ├── repositories/
│   │   └── tracking_repository.dart       # Abstract contract
│   ├── services/
│   │   ├── camera_service.dart            # Abstract
│   │   ├── location_service.dart          # Abstract
│   │   └── geocoding_service.dart         # Abstract
│   ├── usecases/
│   │   └── capture_tracking.dart          # Orchestrator
│   └── fakes/
│       ├── fake_camera_service.dart       # For testing
│       ├── fake_location_service.dart     # For testing
│       ├── fake_geocoding_service.dart    # For testing
│       └── fake_tracking_repository.dart  # For testing
│
├── data/
│   ├── datasources/
│   │   ├── tracking_local_datasource.dart
│   │   └── tracking_local_datasource_impl.dart
│   ├── models/
│   │   └── tracking_model.dart            # Extends Tracking, has JSON
│   └── repositories/
│       └── tracking_repository_impl.dart
│
└── presentation/
    ├── controllers/
    ├── pages/
    └── widgets/
```

## 🔑 Key Principles Applied

### 1. Dependency Injection
- Services are injected into UseCase via constructor
- No global singletons or service locators in UseCase
- Easy to mock for testing

### 2. Separation of Concerns
- Domain knows WHAT needs to be done (abstract)
- Data knows HOW to do it (implementation)
- Presentation knows WHERE to display (UI)

### 3. Entity vs Model
- Entity: Pure domain object, no serialization methods
- Model: Extends Entity, has toJson/fromJson methods
- This keeps domain layer clean and unaware of data format

### 4. Repository as Bridge
- Repository is contract in domain
- Repository implementation converts Tracking (entity) ↔ TrackingModel
- DataSource handles file I/O

## ✅ Self-Test Validation Criteria

### TEST 1 - Swap Storage
Change `TrackingLocalDataSourceImpl` → `TrackingRemoteDataSourceImpl`
Result: UseCase continues to work? ✅ YES (no changes needed)

### TEST 2 - Mock Services
Replace real services with fake ones in UseCase constructor
Result: UseCase continues to work? ✅ YES (uses abstraction)

### TEST 3 - UI Independence
Can UI call `useCase.execute()` without knowing about GPS/Camera/Geocoding?
Result: ✅ YES (UI only needs to know UseCase)

## 🚀 Next Steps (STEP 2)
- Implement real CameraService (using camera package)
- Implement real LocationService (using geolocator package)
- Implement real GeocodingService (using Google Maps API)
- Setup Dependency Injection (GetIt or Riverpod)
- Create Riverpod providers for state management
*/
