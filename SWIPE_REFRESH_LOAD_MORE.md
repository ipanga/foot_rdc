# Swipe-to-Refresh and Load More Features

This document describes the implementation of swipe-to-refresh and pagination (load more) features in the MatchsList widget.

## Features Implemented

### 1. Swipe-to-Refresh ✅
- **Location**: `MatchsList` widget in `lib/features/presentation/pages/matchs_list.dart`
- **Implementation**: Uses Flutter's `RefreshIndicator` widget
- **Behavior**: 
  - Pull down from the top to refresh
  - Resets pagination to page 1
  - Clears existing matches and fetches fresh data
  - Shows visual feedback during refresh
  - Handles network errors gracefully

### 2. Load More/Pagination ✅
- **Trigger**: Automatically loads more content when user scrolls near the bottom (200px from end)
- **Implementation**: Uses `ScrollController` with listener
- **Behavior**:
  - Loads next page of matches automatically
  - Shows loading indicator at the bottom
  - Prevents duplicate requests
  - Handles end of data gracefully
  - Includes debounce mechanism to prevent excessive API calls

### 3. Enhanced Error Handling ✅
- **Network Errors**: Shows snackbar with retry button
- **Persistent Errors**: Shows error banner at the top with retry option
- **Loading States**: Different indicators for initial load, refresh, and load more
- **Empty States**: Shows appropriate message when no matches are found

### 4. Performance Optimizations ✅
- **Debounced Scrolling**: Prevents excessive API calls during rapid scrolling
- **Memory Management**: Proper disposal of controllers and timers
- **State Management**: Efficient state updates and provider invalidation
- **Visual Feedback**: Clear loading states and progress indicators

## Usage

The features are automatically available in the MatchsList widget:

1. **To refresh**: Pull down from the top of the list
2. **To load more**: Scroll to the bottom of the list (automatic)
3. **To retry on error**: Tap the retry button in error messages

## Technical Details

### Key Components:
- `RefreshIndicator`: Handles pull-to-refresh gesture
- `ScrollController`: Monitors scroll position for pagination trigger
- `Timer`: Debounces scroll events to prevent excessive API calls
- `fetchMatchesProvider`: Riverpod provider for data fetching

### State Variables:
- `_currentPage`: Tracks current page for pagination
- `_isLoadingMore`: Prevents duplicate load more requests
- `_isRefreshing`: Prevents conflicts between refresh and load more
- `_hasReachedEnd`: Stops pagination when no more data is available
- `_lastError`: Tracks persistent errors for user feedback
- `_allMatches`: Local cache of all loaded matches

### Error Recovery:
- Automatic retry options in error messages
- Graceful degradation when network is unavailable
- State restoration after errors

## Customization

You can customize the behavior by modifying these constants:
- `_perPage`: Number of items per page (currently 10)
- Scroll trigger distance: Currently 200px from bottom
- Debounce delay: Currently 200ms

## API Integration

The implementation works with the existing `fetchMatchesProvider` and expects:
- Query format: `"leagues=552&seasons=553&page=X&per_page=Y"`
- Response: List of Match objects
- Error handling: Throws exceptions for network/parsing errors