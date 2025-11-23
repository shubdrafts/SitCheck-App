# SitCheck

“Know Before You Go” – SitCheck surfaces live restaurant occupancy for diners and gives owners real‑time controls over their digital presence, menus, tables, and bookings.

## Feature Highlights

- **Dual-role auth** with role selection, Supabase-backed sign-in/sign-up, and guest mode for diners.
- **Diner experience**
  - Curated home feed with smart suggestion tiles and occupancy-aware cards.
  - Restaurant detail page with live pie chart, availability pills, specialties, menu gallery, review cards, and instant booking grid.
  - Rich Google Map view (markers color-coded by occupancy) plus profile editor with avatar/bio/contact fields.
- **Owner experience**
  - Bottom-nav shell covering dashboard, live map (long-press to move pin), and detailed setup/profile form.
  - Dashboard includes occupancy metrics, interactive table layout, and booking workflow (accept/reject).
  - Restaurant setup lets owners edit branding, menu images, specialties, and table layout (add/edit/delete tables).
- **Shared look & feel** driven by custom theme (soft beige, Montserrat/Inter), rounded cards, and consistent chips/badges.

## Requirements

- Flutter 3.19+ (Dart 3.9+) – see `pubspec.yaml` for constraints.
- Supabase project (already wired via `SupabaseConfig`).
- Google Maps SDK keys for Android & iOS.
- On Windows, enable **Developer Mode** so Flutter can create plugin symlinks:
  ```
  start ms-settings:developers
  ```

## Google Maps API Keys

1. Create/obtain a Maps SDK key that allows both Android & iOS.
2. **Android:** update `android/app/src/main/res/values/google_maps_api.xml`
   ```xml
   <string name="google_maps_api_key">YOUR_KEY</string>
   ```
3. **iOS:** update `ios/Runner/Info.plist`
   ```xml
   <key>GMSApiKey</key>
   <string>YOUR_KEY</string>
   ```
4. Rebuild the app. Without keys, the map tabs will render blank.

## Running the app

```bash
flutter pub get
flutter run
```

Use the role selector on launch to explore the diner (UserShell) or owner (OwnerShell) flows. The mock data ships with three restaurants and seeded bookings to mirror the PRD flows end-to-end.
