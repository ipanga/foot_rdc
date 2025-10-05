# Match Feature Implementation

This document describes the complete implementation of the Match feature following clean architecture principles.

## Overview

The Match feature allows users to view football matches fetched from the FootRDC API. The implementation follows the existing project architecture with proper separation of concerns.

## API Endpoint

- **URL**: `https://footrdc.com/wp-json/sportspress/v2/events`
- **Default Parameters**: `leagues=552&seasons=553&page=1&per_page=10`

## Architecture

### Domain Layer (`lib/features/domain/`)

#### Entity
- **File**: `entities/match.dart`
- **Purpose**: Core business model representing a football match
- **Properties**:
  - `id`: Unique match identifier
  - `dateGmt`: Match date and time
  - `status`: Match status (publish, future, draft)
  - `homeTeam`: Home team name (extracted from title)
  - `awayTeam`: Away team name (extracted from title)
  - `homeScore`: Home team score (nullable, from main_results[0])
  - `awayScore`: Away team score (nullable, from main_results[1])

#### Repository
- **File**: `repositories/match_repository.dart`
- **Purpose**: Data access contract for matches
- **Methods**:
  - `fetchMatchesData(String pagination)`: Fetches matches with pagination

#### Use Case
- **File**: `usecases/get_matches.dart`
- **Purpose**: Business logic for retrieving matches
- **Usage**: `GetMatches(repository).call(pagination)`

### Presentation Layer (`lib/features/presentation/`)

#### Pages
- **File**: `pages/matchs_list.dart`
- **Purpose**: Main matches list page with pagination and pull-to-refresh
- **Features**:
  - Infinite scroll pagination
  - Pull-to-refresh functionality
  - Loading states
  - Error handling

#### Widgets
- **File**: `widgets/match_list_item.dart`
- **Purpose**: Individual match display component
- **Features**:
  - Team names display
  - Score display (when available)
  - Match status with color coding
  - Formatted date display

#### Providers
- **File**: `main.dart` (fetchMatchesProvider)
- **Purpose**: Riverpod provider for state management
- **Usage**: `ref.watch(fetchMatchesProvider(pagination))`

## Usage Examples

### Basic Usage in a Widget

```dart
class MyMatchesWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const pagination = "leagues=552&seasons=553&page=1&per_page=10";
    final matchesAsync = ref.watch(fetchMatchesProvider(pagination));
    
    return matchesAsync.when(
      data: (matches) => ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) => MatchListItem(
          match: matches[index],
          onTap: () => _navigateToDetails(matches[index]),
        ),
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### Direct Repository Usage

```dart
final matchRepository = ref.read(matchRepositoryProvider);
final matches = await matchRepository.fetchMatchesData(
  "leagues=552&seasons=553&page=1&per_page=10"
);
```

### Using the Use Case

```dart
final getMatches = GetMatches(matchRepository);
final matches = await getMatches("leagues=552&seasons=553&page=1&per_page=10");
```

## Navigation

The matches feature is integrated into the existing bottom navigation:
- **Tab Index**: 2 (MATCHS tab)
- **Icon**: Soccer field icon (filled/outlined states)
- **Page**: `MatchsList` widget

## JSON Response Format

```json
[
  {
    "id": 65424,
    "date_gmt": "2025-06-27T11:00:22",
    "status": "publish",
    "title": {
      "rendered": "Anges Verts vs AC Rangers"
    },
    "main_results": ["3", "3"]
  }
]
```

## Features

✅ **Clean Architecture**: Proper separation of domain, data, and presentation layers  
✅ **Type Safety**: Full Dart type safety with nullable scores  
✅ **Error Handling**: Comprehensive error handling for API failures  
✅ **Pagination**: Infinite scroll with proper loading states  
✅ **Pull-to-Refresh**: User can refresh match data  
✅ **Responsive UI**: Adaptive layout for different screen sizes  
✅ **State Management**: Riverpod for reactive state management  
✅ **Testing**: Unit tests for the Match entity  
✅ **Navigation**: Integrated into existing app navigation  

## Team Name Extraction

Team names are extracted from the `title.rendered` field by splitting on " vs ":
- **Input**: "Anges Verts vs AC Rangers"
- **Output**: homeTeam = "Anges Verts", awayTeam = "AC Rangers"

## Score Handling

Scores are extracted from the `main_results` array:
- If `main_results` is null or empty → scores are null (match not played)
- If `main_results` has >= 2 elements → homeScore = first element, awayScore = second element
- Scores are stored as strings to preserve original format

## Status Display

Match status is localized for French users:
- `publish` → "Terminé" (green)
- `draft` → "En cours" (orange)  
- `future` → "À venir" (blue)
- Other → original status (grey)