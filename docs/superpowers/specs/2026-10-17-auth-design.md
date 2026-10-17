# Authentication System Design (Firebase Auth)

**Date**: 2026-10-17  
**Topic**: Care-Flash Authentication Subsystem  
**Status**: Approved (MVP / Production-Ready)  

## 1. Overview
This document specifies the design for the authentication subsystem of the Care-Flash Flutter application. It fulfills requirements for account creation, login, and session persistence as outlined in `Care-Flash_SRS_IEEE830.md` (`FR-CS-1`), utilizing Firebase Authentication with a focus on email/password login first, while leaving an interface ready for future social providers (e.g., Google).

## 2. Architecture & Layering

The design follows a clean architecture pattern separating interfaces, implementations, and UI.

```
apps/care_flash/
├── lib/
│   ├── features/
│   │   └── auth/                  # UI and State Management (BLoC)
│   └── infrastructure/
│       └── auth/                  # Firebase Implementation
packages/care_flash_core/
└── lib/
    └── auth/                      # Abstract Interfaces & Models
```

- **Domain/Core (`packages/care_flash_core`)**: Defines the abstract `AuthRepository` interface and user domain models to allow reuse across both `care_flash` and `care_merchant` applications.
- **Infrastructure (`apps/care_flash`)**: Implements `AuthRepository` using the `firebase_auth` SDK.
- **Presentation (`apps/care_flash`)**: Handles UI, form validation, and interacts exclusively with the `AuthRepository` interface via `AuthBloc`.

## 3. Component Details

### 3.1 Domain Layer (`care_flash_core`)
- **`AuthUser`**: Value object containing `id`, `email`, and optional profile metadata.
- **`AuthRepository`**:
  ```dart
  abstract class AuthRepository {
    Stream<AuthUser?> get authStateChanges;
    AuthUser? get currentUser;
    Future<void> signInWithEmailAndPassword({required String email, required String password});
    Future<void> signUpWithEmailAndPassword({required String email, required String password});
    Future<void> signOut();
  }
  ```

### 3.2 Infrastructure Layer (`care_flash`)
- **`FirebaseAuthRepository`**:
  - Implements `AuthRepository`.
  - Wraps `FirebaseAuth.instance`.
  - Maps `User` from Firebase to `AuthUser`.
  - Translates `FirebaseAuthException` into strongly-typed domain errors (e.g., `UserNotFoundException`, `WrongPasswordException`).

### 3.3 Presentation Layer (`care_flash`)
- **`AuthBloc`**:
  - **Events**: `AuthStarted`, `SignInRequested`, `SignUpRequested`, `SignOutRequested`.
  - **States**: `AuthInitial`, `AuthLoading`, `Authenticated`, `Unauthenticated`, `AuthFailure`.
- **UI Screens**:
  - `LoginScreen`: Form for email/password with validation and "Don't have an account? Sign up" toggle.
  - `SignUpScreen`: Form for new registration.

## 4. Error Handling
Firebase exceptions are caught in the repository and mapped to user-facing domain failures:
- `user-not-found` / `wrong-password` -> "Invalid email or password."
- `email-already-in-use` -> "An account already exists for that email."
- `network-request-failed` -> "Network error. Please check your connection."

## 5. Testing Strategy
- **Unit Testing**:
  - Mock `AuthRepository` to test `AuthBloc` states.
  - Use `firebase_auth_mocks` to test `FirebaseAuthRepository` logic.
- **Widget Testing**:
  - Verify `LoginScreen` renders properly and dispatches events on button clicks.
