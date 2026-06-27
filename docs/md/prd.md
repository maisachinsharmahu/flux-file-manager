# Product Requirements Document (PRD) - FLUX

## Executive Summary

Every Android smartphone today ships with a file management application — Google Files, Samsung My Files, or a vendor equivalent. Yet despite billions of users and decades of development, these applications share one fundamental architectural flaw: they are built on top of Android's MediaStore, a SQLite database designed in the early 2000s that performs full table scans for every search operation.

The consequence is measurable. A device with 50,000 files waits up to 500 milliseconds for a single search result. Deleting 1,000 files simultaneously freezes the interface for 30 to 60 seconds. Files deleted in one application continue to appear as ghosts in another for minutes or hours. Semantic queries — "find my tax documents from last year" — return nothing.

**FLUX** (*File Lookup & Unified eXperience Index*) is a ground-up redesign. It replaces the SQLite dependency with a **9-layer composite index** in which every user-visible operation executes in $\mathcal{O}(1)$ or $\mathcal{O}(\log n)$ time. It introduces the first on-device AI semantic search for Android file management, powered by HNSW vector indexing and a 22 MB on-device embedding model. It permanently eliminates stale index entries through a 4-layer synchronisation system anchored to the Linux kernel's `inotify` subsystem.

This document details the product-level vision, requirements, competitive landscape, success criteria, and feature specifications that drive the engineering phase of the project.

---

## Vision and Mission

### Vision
FLUX will be the world's fastest and most intelligent file management application for Android — better than any solution existing or foreseeable, achieved through architectural innovation rather than incremental feature addition. We aim to establish a new standard for local search, retrieval, and device resource footprint on mobile operating systems.

### Mission
Eliminate every measurable inefficiency in Android file management by replacing legacy data structures with a purpose-built composite index, and by integrating on-device AI to transform how users discover and organise their files, while maintaining absolute client privacy and low hardware stress.

---

## Problem Statement

The file explorer category on Android is broken at the architectural level, resulting in five critical problems for the user:

### Problem 1 — Search is a Full Scan: $\mathcal{O}(n)$
All current Android file explorers search filenames by issuing a SQL `LIKE '%query%'` statement against MediaStore. A `LIKE` query with a leading wildcard cannot use B-tree indexes. It degrades to a full table scan. On 50,000 files: 50,000 row comparisons per query. On 1,000,000 files (not unusual for a 512 GB device): 200–600 ms per search.

### Problem 2 — Zero Semantic Understanding
If a file is named `Q3_Final_Report_v2.pdf` and the user searches for "quarterly report", the file will not appear. Current apps perform exact substring matching only. There is no concept of meaning, context, or synonymy.

### Problem 3 — Stale Index (Ghost Files)
Android's MediaStore is updated asynchronously. When another application deletes a file, the MediaStore entry may persist for minutes until the Media Scanner re-runs. Users see files that do not exist (ghost files). This is a fundamental architectural flaw caused by delegating index ownership to the operating system.

### Problem 4 — Batch Operations Freeze the UI
Deleting or moving 1,000 files triggers 1,000 individual MediaStore notifications, causing the UI to redraw 1,000 times. The interface freezes for 30–60 seconds. On some devices the application crashes.

### Problem 5 — No Relationship Awareness
Files are presented as isolated objects. The application has no awareness that `Project_Budget.xlsx`, `Project_Kickoff.pptx`, and `Project_Notes.docx` are related. Users reconstruct context manually that the system could derive automatically.

---

## Target Users

FLUX addresses the needs of multiple segments of Android users in India and globally:

| Segment | Device Profile | Key Pain Points |
| :--- | :--- | :--- |
| **Power Users** | Flagship, 256–512 GB | Batch operations, deduplication, semantic search |
| **Students** | Mid-range, 64–128 GB | Cannot find assignment files, slow search |
| **Business Users** | Corporate Android | Document retrieval, privacy, compliance |
| **Digital Creators** | High-end, 512 GB+ | Asset management, project grouping |
| **Government Employees** | Standard-issue devices | Secure file handling, audit trails |

---

## Competitive Analysis

A review of the standard file management systems on the market demonstrates that they rely on legacy scanning approaches:

| Feature | Google Files | Samsung My Files | OnePlus Files | FLUX |
| :--- | :--- | :--- | :--- | :--- |
| **Search complexity** | $\mathcal{O}(n)$ | $\mathcal{O}(n)$ | $\mathcal{O}(n)$ | $\mathcal{O}(k)$ / $\mathcal{O}(1)$ |
| **Semantic search** | Cloud only | None | None | On-device AI |
| **Stale files** | Yes | Yes | Yes | Never |
| **Delete 1k files** | 30–60 s | 20–40 s | 20–40 s | < 3 s |
| **Duplicate detect** | Hash-based | None | None | $\mathcal{O}(1)$ checksum |
| **Thermal management** | None | None | None | Full governor |
| **Content search** | Partial ML | None | None | On-device indexed |
| **Cross-app sync** | Async | Async | Async | < 1 ms `inotify` |

---

## Success Metrics (KPIs)

The success of FLUX will be measured against strict technical and product benchmarks:

1. Search latency P50 < 1 ms for filename prefix search on 1 M files.
2. Search latency P50 < 15 ms for semantic AI search on 1 M files.
3. Batch delete 1,000 files < 3 seconds, UI responsive throughout.
4. Stale index rate = 0% within 5 seconds of any cross-app change.
5. App cold start to interactive < 800 ms.
6. Phone temperature increase < 2°C during background indexing.
7. RAM footprint: HOT tier < 80 MB; total < 250 MB foreground.
8. App Store rating $\ge$ 4.6 within 6 months of launch.
9. 30-day retention $\ge$ 55%.
10. 5% market share of Indian Android file explorer users within 18 months.

---

## Feature Specifications

Features are structured across three implementation tiers based on launch criticality:

### P0 — Core (Must Launch)
* **File Browser:** Instant folder listing with sorting options (name, date, size).
* **Sub-Millisecond Search:** Instant filename prefix search based on Radix Trie.
* **Batch Operations:** Batch select, move, copy, and delete with live non-blocking progress bars.
* **Storage Analytics Dashboard:** Local breakdown of storage status.
* **Progressive Thumbnails:** Thumbnail grid using `cacheWidth` limits and progressive loading.
* **Trash Folder:** Recoverable deletions with a default 30-day retention.
* **Theme Customization:** Complete light and dark mode support.
* **Cross-App Sync:** Zero-latency updates of external deletions/creations via `inotify` and observers.

### P1 — High Priority (Launch + 30 days)
* **Semantic AI Search:** Local natural-language semantic query system (no internet required).
* **Junk Cleaner:** Scan and remove temp files, duplicates, caches, and orphaned data.
* **Interactive Categories:** Storage breakdown by category with an animated donut chart.
* **Inside-File Content Search:** Search words inside PDF, DOCX, and TXT files.
* **Duplicate Resolution UI:** Interactive view of file duplicates grouping by size/hash, letting the user selectively prune.

### P2 — Growth & Expansion (Q2)
* **Smart Project Clusters:** Automated AI grouping of related project files.
* **Secure Locker:** Biometric-locked, encrypted folder.
* **Network Shares:** SMB/FTP access configuration.
* **Archive Manager:** Extract and pack ZIP, RAR, and 7Z archives.
* **Scheduled Cleaning:** Auto-scans and schedules for cache management.
