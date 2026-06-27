# Application Flow & Visual Design System - FLUX

## Application Flow

### Navigation Architecture
FLUX uses a bottom navigation bar with five primary destinations managed by GoRouter with typed routes. All navigation is declarative — state drives navigation, not imperative push/pop calls.

### Screen Specifications

#### Home Screen
Features four main zones:
1. **Storage Bar:** Live animated breakdown of used/free space.
2. **Quick Access:** Category buttons for Images, Videos, Audio, Documents, and Downloads. Uses MIME type bucket queries ($\mathcal{O}(1)$).
3. **Recent Files:** Shows the last 20 accessed files from the recency ring buffer ($\mathcal{O}(1)$).
4. **Smart Cards:** Contextual cards representing AI-suggested cleaning actions, large files, and duplicates.

#### Browser Screen
Renders directory contents at 60 fps for folders containing up to 10,000 items.
* **Algorithm:** `dirIndex.get(dirFid)` returns a sorted `IntArray` in $\mathcal{O}(1)$.
* **UI List:** Visible items are rendered via `ListView.builder`.
* **Physics Check:** When scroll velocity exceeds 3,000 px/s, thumbnail loading pauses to prevent frame drops.
* **Selection:** Multi-selected items are held in a `RoaringBitmap` for $\mathcal{O}(1)$ membership checks.

#### Search Screen
Streams results from three parallel search paths:

| Mode | Trigger | Index Used | Latency |
| :--- | :--- | :--- | :--- |
| **Prefix Autocomplete** | Keystroke (150 ms debounce) | Name Trie | < 0.5 ms |
| **Keyword Search** | On submit | Token Index + Roaring AND | < 2 ms |
| **Semantic AI Search** | Long query / no keyword match | HNSW Vector Graph | < 10 ms |

Results stream to the UI via an `EventChannel`, displaying prefix matches immediately while slower semantic streams catch up.

#### Analytics Screen
Computes storage breakdowns in < 50 ms since all file sizes are already available in native RAM:
* Rendered using a custom animated donut chart.
* Displays total category count, largest file, and per-app storage statistics via `StorageStatsManager` (no root required).
* Tapping an app packages opens Android's system App Info page for quick cache clearing.

#### Trash Screen
Displays logically tombstoned files. Files are automatically cleared after 30 days. Restoring files simply clears the FID from the `deletionSet` in less than 2 ms.

---

### Gesture Map

| Gesture | Surface | Action |
| :--- | :--- | :--- |
| **Tap** | File Item | Open / preview file |
| **Long Press** | File Item | Enter multi-select mode |
| **Tap (select mode)** | File Item | Toggle file selection |
| **Swipe Right** | File Item | Quick action: share |
| **Swipe Left** | File Item | Quick action: delete (shows Undo snackbar) |
| **Two-Finger Pinch** | Grid View | Toggle grid layouts/columns |
| **Pull Down** | File List | Force manual observer delta reconciliation |
| **Swipe Up** | Bottom Bar | Quick search popup |
| **Long Press + Drag** | File Item | Initiate drag-to-folder movement |

---

## Visual Design System

### Design Philosophy
1. **Typography First:** Spacing, sizes, and type weights communicate structure. Legibility is the primary driver.
2. **Zero Decoration:** No linear gradients, drop shadows, or borders. Flat layout blocks prioritize performance and simplicity.
3. **Information Density:** Designed to show maximum content (filenaming details, dates, paths) cleanly for power users.

### Achromatic Color System

| Token | Light Mode | Dark Mode | Usage |
| :--- | :--- | :--- | :--- |
| `surface.base` | `#FFFFFF` | `#0A0A0A` | Standard screen background |
| `surface.elevated` | `#F5F5F5` | `#141414` | Cards, sheets, dialog backgrounds |
| `surface.overlay` | `#EBEBEB` | `#1E1E1E` | Hover states, selected item backgrounds |
| `ink.primary` | `#0D0D0D` | `#F0F0F0` | Filenames, core header text, icons |
| `ink.secondary` | `#4A4A4A` | `#A0A0A0` | Secondary metadata labels |
| `ink.tertiary` | `#888888` | `#606060` | Timestamps, muted paths |
| `border.subtle` | `#E0E0E0` | `#2A2A2A` | Separator lines, list dividers |
| `semantic.delete` | `#B91C1C` | `#EF4444` | Warning states, delete button highlight |
| `semantic.success` | `#166534` | `#4ADE80` | Complete checks, progress success |

### Typography Scale

| Token | Font Family | Size | Weight | Usage |
| :--- | :--- | :--- | :--- | :--- |
| `display.large` | Inter | 28 sp | Bold (700) | Screen titles |
| `display.medium` | Inter | 22 sp | Semi-Bold (600) | Section headings |
| `title.large` | Inter | 18 sp | Semi-Bold (600) | Card headers |
| `title.medium` | Inter | 16 sp | Medium (500) | Filenames in list |
| `body.large` | Inter | 15 sp | Regular (400) | General reading paragraphs |
| `body.medium` | Inter | 14 sp | Regular (400) | Descriptions, path previews |
| `label.large` | Inter | 13 sp | Medium (500) | Button labels, tabs |
| `label.small` | Inter | 11 sp | Regular (400) | Muted timestamps, sizes |
| `mono.code` | JetBrains Mono | 13 sp | Regular (400) | Paths, file checksum hashes |

* **Spacing Grid:** All values are derivatives of a 4 dp base: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64 dp.

---

### Core Widgets
* `FluxFileListItem`: Displays files in list layout at standard (64 dp) or comfortable (80 dp with path) heights.
* `FluxThumbnail`: Renders file thumbnails dynamically using memory constraints.
* `FluxSearchBar`: Debounced text input displaying active search stream statuses.
* `FluxStorageDonut`: Low-overhead rendering widget utilizing Flutter canvas drawing routines.

---

## Storage Analytics & Junk Cleaner

### Storage Analytics
* **Why FLUX Analytics is $300\times$ Faster:** Google Files scans files on-demand (takes 10–15 seconds). FLUX computes category sizes instantly (<50 ms) because category counts exist in native memory (`typeBuckets` contain file IDs by type; `masterIndex` tracks sizes).

### Junk Cleaner Engine

| Junk Type | Detection Method | Scan Time | Expected Recovery |
| :--- | :--- | :--- | :--- |
| **Empty folders** | `dirIndex` lists empty array check | < 100 ms | Negligible |
| **Temp files** | `.tmp`/`.bak`/`.log` type query | $\mathcal{O}(1)$ query | 50–500 MB |
| **System files** | `.DS_Store`/`Thumbs.db` trie match | $\mathcal{O}(k)$ | Negligible |
| **Duplicate files** | `checksumMap` containing size groups > 1 | < 1 s | 1–20 GB |
| **Orphaned folders** | `/Android/data` package verification | < 200 ms | 100 MB–5 GB |
| **WhatsApp Sent** | Checksum duplicates + path matches | < 1 s | 500 MB–10 GB |
| **Old downloads** | Size and date filter ranges (VEB trees) | < 1 ms | User-dependent |

#### Hard Safety Rules
1. Never scan or clean the `/DCIM` directory under any conditions.
2. Exclude files created or modified within the last 24 hours.
3. Skip files currently locked/opened by other OS handles.
4. User must manually verify findings and confirm deletions.
5. All deletions are logically tombstoned first for 30-day safety.

---

## Progressive Thumbnail Rendering Pipeline

* **Core Principle:** Never decode the original image directly. The maximum decoded thumbnail resolution is 256x256 using RGB_565 (2 bytes/pixel) instead of ARGB_8888 (4 bytes/pixel), saving 50% memory.

### 4-Stage Rendering
1. **Micro Placeholder:** 16x16 blurred JPEG stored in the `FileRecord` (40 bytes) — renders instantly.
2. **Memory Cache:** 50 MB `LruCache<Int, Bitmap>` check ($\mathcal{O}(1)$).
3. **Disk Cache:** Reads optimized thumbnail from `/cache/thumbs/<fidHash>.jpg` ($\approx$15 ms).
4. **Generate:** Decodes image at 256x256 RGB_565 ($\approx$40–100 ms) and updates memory/disk caches.

```dart
// Flutter Image widget utilizing cache limits
Image.memory(
  thumbnailBytes,
  cacheWidth: 256,     // Stores image in cache at 256x256
  cacheHeight: 256,    // Avoids high-density display scaling (up to 3MB/thumb)
  fit: BoxFit.cover,
  filterQuality: FilterQuality.low,
)
```
* With `cacheWidth` limit: 256x256 RGB_565 = **128 KB** per thumbnail.
* Without limit: 768x768 ARGB_8888 = **1.76 MB** per thumbnail ($13.7\times$ memory bloat).
