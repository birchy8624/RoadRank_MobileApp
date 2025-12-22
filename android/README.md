# RoadRank Android App

A native Android app for discovering and rating the best driving roads. Built with Jetpack Compose and Google Maps.

## Features

- **Interactive Map**: Explore roads on a full-screen map with overlays color-coded by rating
- **Road Ratings**: Rate roads on 5 key criteria (twistiness, surface, fun, scenery, visibility)
- **Discover Roads**: Browse and filter community-rated roads
- **Profile & Settings**: View device ID and manage preferences

## Requirements

- Android Studio Hedgehog or newer
- Android SDK 34
- Kotlin 1.9+
- Google Maps API key

## Setup

1. Open the `android/` folder in Android Studio.
2. Add your Google Maps API key to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

3. Sync Gradle and run the app on an emulator or device.

## API Configuration

The app connects to the RoadRank backend API. The base URL is configured in:

`android/app/src/main/java/com/roadrank/app/data/ApiClient.kt`

```kotlin
private val baseUrl: String = "https://road-rank-mobile-app.vercel.app"
```

## Project Structure

```
android/
├── app/
│   ├── src/main/java/com/roadrank/app/
│   │   ├── data/        # Models and API client
│   │   ├── ui/          # Compose UI (screens + components)
│   │   └── MainActivity.kt
│   └── src/main/res/    # Resources and themes
├── build.gradle.kts
├── settings.gradle.kts
└── gradle/              # Version catalog
```
