# SitCheck Product Requirements Document (PRD)

## 1. Overview
- **Tagline**: Know Before You Go.
- **Concept**: Cross-platform Flutter app that lets diners see live restaurant occupancy, browse menus/pricing/reviews, and book tables. Restaurant owners manage occupancy, menu content, and bookings via an in-app dashboard.
- **Experience Goals**: Smooth, modern UI aligned with provided designs, low-friction browsing/booking, real-time transparency for both diners and owners.

## 2. Goals & Objectives
- **Primary**: (1) Users quickly discover restaurants, occupancy, and book tables. (2) Owners manage availability, menus, and real-time presence. (3) Maintain UI parity with design system.
- **Secondary**: Improve diner decision-making, reduce wait times/overcrowding, and streamline restaurant digital presence plus flow control.

## 3. Target Users
- **End Users**: Diners looking for nearby restaurants, occupancy-aware visitors, quick bookers.
- **Restaurant Owners**: SMB operators needing occupancy tools; large venues seeking digital menu visibility and demand management.

## 4. User Flows
1. **App Launch**: Splash → role selection (User vs Owner).
2. **Authentication**: Sign up (username/email/password) or log in (email/password) with role-based routing (User Dashboard vs Owner Dashboard). Profile completion follows signup.

## 5. Core Features
### 5.1 Common
- **Authentication**: Role selection, signup/login, profile creation.
- **Bottom Navigation**: Home, Map, Profile tabs for both roles.

### 5.2 User Experience
- **Home Dashboard**: Search, AI suggestions (future), restaurant cards with name, rating/reviews, distance, price category, occupancy (Empty/Partial/Full).
- **Restaurant Details**: Banner image, info (name, cuisine, rating w/ count, price range, specialty tags), review cards, real-time occupancy pie (green/yellow/red) with total tables + live availability, actions (Directions deep link, Book Table).
- **Table Booking**: Grid floor plan with color-coded tables (green available, yellow selected, red occupied). Booking updates table state and occupancy chart instantly.

### 5.3 Owner Experience
- **Owner Dashboard**: Snapshot of available vs occupied tables, upcoming bookings, quick occupancy adjustments.
- **Restaurant Setup**: Manage banner, menu images, specialties, pricing, cuisine, description. Configure tables (add, seats per table, availability toggles).
- **Live Occupancy Management**: Toggle table states (occupied/empty) with real-time sync to users.
- **Booking Management**: Accept/reject requests (optional), view history, auto-update occupancy from bookings.

## 6. Maps Module
- **User View**: Google Maps with colored markers (green empty, yellow partial, red full). Marker tap opens bottom sheet (name, rating, occupancy, actions for directions & view details).
- **Owner View**: Shows owner restaurant only; allows pin updates.

## 7. Profile Module
- **User Profile**: Display picture upload, editable name/bio/email/phone with save.
- **Owner Profile**: Owner name, contact, restaurant details, banner management.

## 8. UI / UX Guidelines
- **Theme**: Soft beige background (`#F5E6D3`), red primary buttons, rounded cards with shadows, Montserrat/Inter typography, iconography for dining/map/navigation.
- **Charts & Colors**: Pie segments—green available, yellow partial, red occupied.
- **Tables**: Square/rounded seats labelled (T1, T2, ...).

## 9. Technical Requirements
- **Stack**: Flutter frontend (Cursor IDE). State mgmt via Provider/Riverpod/BLoC. Backend Firebase or Supabase (Firestore/Postgres). Firebase Auth, Firestore or Supabase real-time, Firebase Storage for images. Google Maps API.

## 10. Data Models
- **User**: `userId`, `role`, `name`, `email`, `bio`, `profilePhoto`, `phoneNumber`.
- **Restaurant**: `restaurantId`, `ownerId`, `name`, `cuisine`, `rating`, `priceRange`, `bannerImage`, `menuImages[]`, `location (lat,lng)`, `description`, `specialties[]`, `tables[]`.
- **Table**: `tableId`, `seats`, `status (available/occupied)`, `lastUpdated`.
- **Booking**: `bookingId`, `userId`, `restaurantId`, `tableId`, `timestamp`.

## 11. Success Metrics
- **User-side**: Bookings per day, session duration, restaurants viewed per session.
- **Owner-side**: Occupancy accuracy, booking conversion rate, restaurant page visits.

