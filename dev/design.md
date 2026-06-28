# Application Architecture & Design Specifications

This document defines the user interface layout, design tokens, widget modularity, and Riverpod state management structure for FLUX.

---

## App Folder Structure

FLUX uses a feature-first architecture to ensure clean separation of concerns and scaling capacity.

```
lib/
|-- main.dart                      # App entry point, native index initialization hooks
|-- app.dart                       # Root MaterialApp and GoRouter configuration
|-- bridge/
|   `-- flux_bridge.dart           # MethodChannel and EventChannel interface bindings
|-- core/
|   |-- constants/
|   |   `-- design_tokens.dart     # Spacing, padding, and duration values
|   |-- theme/
|   |   `-- achromatic_theme.dart  # Light/Dark achromatic ThemeData definitions
|   `-- utils/
|       |-- byte_formatter.dart    # Byte count display formatting utility
|       `-- date_formatter.dart    # Relative and absolute date formatting utility
|-- features/
|   |-- navigation/
|   |   |-- presentation/
|   |   |   `-- main_navigation_shell.dart # Scaffold with bottom bar and IndexedStack
|   |   `-- providers/
|   |       `-- navigation_provider.dart   # Selected index and routing tracker
|   |-- home/
|   |   |-- presentation/
|   |   |   |-- home_screen.dart
|   |   |   `-- widgets/
|   |   |       |-- storage_bar.dart       # Donut-style linear storage utilization bar
|   |   |       |-- quick_access_grid.dart # MIME category query shortcuts
|   |   |       |-- recents_list.dart      # O(1) recent file item list
|   |   |       `-- smart_cards_list.dart  # Cleaner suggestions and duplicate cards
|   |   `-- providers/
|   |       |-- storage_status_provider.dart
|   |       |-- recents_provider.dart
|   |       `-- home_card_provider.dart
|   |-- browser/
|   |   |-- presentation/
|   |   |   |-- browser_screen.dart
|   |   |   `-- widgets/
|   |   |       |-- browser_toolbar.dart   # Sorting and layout controls toolbar
|   |   |       |-- file_list_row.dart     # Dynamic 64dp/80dp list row widget
|   |   |       |-- file_grid_cell.dart    # Compact grid item widget
|   |   |       `-- progressive_thumbnail.dart # RGB_565 cacheWidth image container
|   |   `-- providers/
|   |       |-- file_system_provider.dart  # Path tracking and directory list loader
|   |       |-- selection_provider.dart    # RoaringBitmap index selection tracker
|   |       `-- layout_provider.dart       # List/Grid toggle state tracker
|   |-- search/
|   |   |-- presentation/
|   |   |   |-- search_screen.dart
|   |   |   `-- widgets/
|   |   |       |-- query_input_bar.dart   # Debounced search text field
|   |   |       |-- search_history.dart    # Local search history list
|   |   |       `-- streaming_results.dart # EventChannel dynamic lists container
|   |   `-- providers/
|   |       |-- search_state_provider.dart # Search query and focus trackers
|   |       `-- search_stream_provider.dart# EventChannel subscription stream provider
|   |-- analytics/
|   |   |-- presentation/
|   |   |   |-- analytics_screen.dart
|   |   |   `-- widgets/
|   |   |       |-- canvas_donut_chart.dart# Custom painter storage breakdown donut
|   |   |       |-- category_detail_row.dart# Category statistics summary block
|   |   |       `-- app_storage_row.dart    # Package size item with deep link trigger
|   |   `-- providers/
|   |       |-- stats_provider.dart        # Cache aggregation sizes provider
|   |       `-- app_packages_provider.dart # Package storage details list provider
|   |-- trash/
|   |   |-- presentation/
|   |   |   `-- trash_screen.dart
|   |   `-- providers/
|   |       `-- trash_provider.dart        # Tombstoned file indices provider
|   `-- settings/
|       |-- presentation/
|       |   `-- settings_screen.dart
|       `-- providers/
|           `-- config_provider.dart       # SharedPreferences setup model provider
+---------------------------------------------------------------------------------+
```

---

## Screen Details & State Specifications

### 1. Home Screen
Provides the entry dashboard, highlighting storage utilization, categories, and direct action items.
* **Storage Bar Widget:** Reads total used and free space. Animates on load using `flutter_animate` scaling.
* **Quick Access Grid:** Standardized buttons targeting Images, Videos, Audio, Documents, and Downloads. Each button queries MIME categories in $\mathcal{O}(1)$ and routes to the Browser Screen pre-filtered.
* **Recents List:** Renders the last 20 FIDs from the native recency ring buffer. Previews thumbnail, file title, and timestamp.
* **Smart Cards List:** Dynamic carousel showcasing actionable panels:
  - "Junk Detected": Displays aggregate cache size with a "Scan" button.
  - "Duplicates Found": Displays aggregate duplicate bytes with a "View" button.
  - "Large Old Files": Lists large files untouched for 60+ days.
* **Riverpod Providers:**
  - `storageStatusProvider` (FutureProvider): Fetches storage details from native memory.
  - `recentsProvider` (StateNotifierProvider): Stream-backed index of recent FIDs.
  - `homeCardProvider` (NotifierProvider): Combines junk scanner state and duplicate stats to yield card models.

### 2. Browser Screen
Handles file browsing, layouts, multiple selections, and standard modifications (cut, copy, rename, delete).
* **Browser Toolbar:** Handles directory trace paths (breadcrumbs), list/grid layout toggle, sorting criteria (name, size, modification date), and selection actions (delete selection, share selection).
* **Lists / Grid Lists:** Uses `ListView.builder` for list mode and `SliverGrid.builder` for grid mode. Pause image loading if scroll velocity exceeds 3,000 px/s.
* **Progressive Thumbnail Container:** Renders the placeholder stored inside the `FileRecord` instantly. Resolves cached thumbnails via local path pointers, falling back to decoding on-device. Uses a strict `cacheWidth: 256` constraint.
* **Riverpod Providers:**
  - `fileSystemProvider` (FamilyNotifierProvider): Parameters are the target directory path. Manages folder stack index, sorted arrays of FIDs, and subfolder metadata.
  - `selectionProvider` (StateProvider): Tracks active FIDs selected in a map-backed list.
  - `layoutProvider` (NotifierProvider): Persists grid/list defaults.

### 3. Search Screen
Acts as the central queries hub, streaming results from three paths in parallel.
* **Query Input Bar:** Debounced input field (150 ms window). Displays a tag (Prefix, Keyword, Semantic) reflecting the active search mode.
* **Streaming Results Container:** Merges three EventChannel streams. Results update in place as the prefix Radix Trie matches (<0.5 ms), keyword index bitmaps load (<2 ms), and HNSW vector calculations finish (<15 ms).
* **Riverpod Providers:**
  - `searchStateProvider` (NotifierProvider): Tracks query text and active search modes.
  - `searchStreamProvider` (StreamProvider): Connects to the native search `EventChannel` to yield streamed matches as they arrive.

### 4. Analytics Screen
Displays storage audits and diagnostics.
* **Custom Donut Chart:** A custom painter class (`CanvasDonutChart`) displaying proportional segments for 11 storage categories. Tapping a segment highlights the category details.
* **Category Detail List:** Shows category byte sizes, file counts, and the largest file within the category.
* **App Storage List:** Queries local app storage footprint. Tapping an item triggers the native bridge to deep-link directly to Android's App Info page.
* **Riverpod Providers:**
  - `statsProvider` (FutureProvider): Gathers aggregate category information.
  - `appPackagesProvider` (FutureProvider): Queries package-level space footprints.

### 5. Trash Screen
Shows a list of logically deleted files.
* **List Interface:** Displays the filename, original directory, and days remaining until physical deletion. Swiping right restores the file instantly (O(1) logical restore). Swiping left deletes it permanently.
* **Riverpod Providers:**
  - `trashProvider` (StateNotifierProvider): Lists tombstoned FIDs and manages recovery operations.

### 6. Settings Screen
Exposes system parameters.
* **Settings Toggle List:** Sets theme, enables thermal governor throttling, toggles WiFi-only HNSW vector builds, and configures file content parsing file size caps.
* **Riverpod Providers:**
  - `configProvider` (StateNotifierProvider): Reads and writes parameters to `SharedPreferences` and synchronizes changed parameters to native config engines.

---

## Design System Tokens & Configurations

### Spacing & Grid System
FLUX uses a 4dp base grid system to align layout blocks:
* `spacing.tiny` = 4.0 dp
* `spacing.small` = 8.0 dp
* `spacing.medium` = 12.0 dp
* `spacing.large` = 16.0 dp
* `spacing.xlarge` = 24.0 dp
* `spacing.xxlarge` = 32.0 dp
* `spacing.giant` = 48.0 dp

### Color Palette (Achromatic System)
To emphasize clarity and data hierarchy, the design uses a clean achromatic color palette without drop shadows, gradients, or decorative borders.

```
Light Mode Palette:
  Background Base:     #FFFFFF (surface.base)
  Background Card:     #F5F5F5 (surface.elevated)
  Item Hover/Selected: #EBEBEB (surface.overlay)
  Text Primary:        #0D0D0D (ink.primary)
  Text Secondary:      #4A4A4A (ink.secondary)
  Text Muted:          #888888 (ink.tertiary)
  Borders/Dividers:    #E0E0E0 (border.subtle)
  Warning Accent:      #B91C1C (semantic.delete)
  Success Accent:      #166534 (semantic.success)

Dark Mode Palette:
  Background Base:     #0A0A0A (surface.base)
  Background Card:     #141414 (surface.elevated)
  Item Hover/Selected: #1E1E1E (surface.overlay)
  Text Primary:        #F0F0F0 (ink.primary)
  Text Secondary:      #A0A0A0 (ink.secondary)
  Text Muted:          #606060 (ink.tertiary)
  Borders/Dividers:    #2A2A2A (border.subtle)
  Warning Accent:      #EF4444 (semantic.delete)
  Success Accent:      #4ADE80 (semantic.success)
```

### Typography Scale
* Font Family: `Inter` for interface elements; `JetBrains Mono` for file paths and hashes.
* Font Configurations:
  - Display Large: 28 sp, Bold (700), Line Height 34
  - Display Medium: 22 sp, Semi-Bold (600), Line Height 28
  - Title Large: 18 sp, Semi-Bold (600), Line Height 24
  - Title Medium: 16 sp, Medium (500), Line Height 22
  - Body Large: 15 sp, Regular (400), Line Height 20
  - Body Medium: 14 sp, Regular (400), Line Height 18
  - Label Large: 13 sp, Medium (500), Line Height 16
  - Label Muted: 11 sp, Regular (400), Line Height 14
  - Mono Code: 13 sp, Regular (400), Line Height 16
