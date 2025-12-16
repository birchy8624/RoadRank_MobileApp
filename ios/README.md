# RoadRank iOS App

A native iOS app for discovering and rating the best driving roads. Built with SwiftUI and MapKit.

## Features

- **Interactive Map**: Explore roads on a full-screen map with road overlays color-coded by rating
- **Draw Roads**: Draw your favorite driving routes directly on the map
- **Road Snapping**: Automatically snap drawn paths to actual road networks using OSRM
- **5-Star Rating System**: Rate roads on 5 key criteria:
  - Twistiness
  - Surface Condition
  - Fun Factor
  - Scenery
  - Visibility
- **Discover Roads**: Browse and filter community-rated roads
- **Location Search**: Find locations using Nominatim/MapKit search
- **Haptic Feedback**: Native iOS haptic feedback throughout the app

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Project Structure

```
ios/
├── RoadRank.xcodeproj/          # Xcode project file
├── RoadRank/
│   ├── RoadRankApp.swift        # App entry point
│   ├── ContentView.swift        # Main content view with tab bar
│   ├── Info.plist               # App configuration
│   ├── Models/
│   │   ├── Road.swift           # Road and Rating models
│   │   └── SearchResult.swift   # Search result models
│   ├── Views/
│   │   ├── MapContainerView.swift     # Main map screen
│   │   ├── MapViewRepresentable.swift # UIKit MapView bridge
│   │   ├── DiscoverView.swift         # Road discovery screen
│   │   ├── ProfileView.swift          # User profile/settings
│   │   ├── RatingSheetView.swift      # Rating submission sheet
│   │   └── SearchSheetView.swift      # Location search sheet
│   ├── ViewModels/
│   ├── Services/
│   │   ├── APIClient.swift            # Backend API client
│   │   ├── LocationManager.swift      # CoreLocation manager
│   │   ├── RoadSnappingService.swift  # OSRM road snapping
│   │   ├── SearchService.swift        # Location search
│   │   └── HapticManager.swift        # Haptic feedback
│   ├── Components/
│   │   ├── LoadingView.swift          # Loading/empty states
│   │   └── RatingBadge.swift          # Rating UI components
│   ├── Extensions/
│   │   ├── Color+Extensions.swift
│   │   └── CLLocationCoordinate2D+Extensions.swift
│   └── Assets.xcassets/
│       ├── AppIcon.appiconset/
│       └── AccentColor.colorset/
```

## Setup

1. Open `RoadRank.xcodeproj` in Xcode 15+
2. Select your development team in Signing & Capabilities
3. Build and run on a simulator or device

## API Configuration

The app connects to the RoadRank backend API. The base URL is configured in `Services/APIClient.swift`:

```swift
enum APIConfig {
    static let baseURL = "https://road-rank-mobile-app.vercel.app"
}
```

## Privacy & Permissions

The app requires the following permissions:

- **Location (When In Use)**: To show nearby roads and center the map
- **Location (Always)**: Optional, for background route tracking
- **Motion**: Optional, to detect driving activity

These permissions are configured in `Info.plist` with appropriate usage descriptions.

## App Store Requirements

- Bundle ID: `com.roadrank.app`
- Category: Navigation
- Age Rating: 4+
- Privacy Policy required (location data collection)

## Architecture

The app follows MVVM architecture with:

- **Models**: Data structures for roads, ratings, coordinates
- **Views**: SwiftUI views for all screens
- **ViewModels**: ObservableObject classes for state management
- **Services**: API clients, location manager, haptic feedback

### Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **MapKit**: Native iOS mapping with MKMapView
- **CoreLocation**: Location services and GPS tracking
- **Combine**: Reactive programming for state management
- **URLSession**: Async/await networking

## Building for Release

1. Update version number in project settings
2. Create App Store Connect record
3. Archive in Xcode: Product > Archive
4. Upload to App Store Connect
5. Submit for review

## License

MIT License
