import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Colored SVG icons for storage types and file categories.
/// These are inline SVGs — no separate asset files needed.
enum StorageCategoryIcon {
  internalStorage,
  sdCard,
  images,
  videos,
  documents,
  audio,
  apps,
  downloads,
}

/// Returns an inline SVG string for the given [StorageCategoryIcon].
String _svgForIcon(StorageCategoryIcon icon) {
  switch (icon) {
    case StorageCategoryIcon.internalStorage:
      return '''<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#00C896" fill-opacity="0.15"/>
  <rect x="14" y="8" width="20" height="32" rx="4" fill="#00C896"/>
  <rect x="18" y="12" width="12" height="6" rx="2" fill="white" fill-opacity="0.6"/>
  <rect x="18" y="22" width="4" height="4" rx="1" fill="white" fill-opacity="0.5"/>
  <rect x="26" y="22" width="4" height="4" rx="1" fill="white" fill-opacity="0.5"/>
  <rect x="18" y="30" width="12" height="3" rx="1.5" fill="white" fill-opacity="0.4"/>
  <circle cx="24" cy="36" r="2" fill="white" fill-opacity="0.7"/>
</svg>''';

    case StorageCategoryIcon.sdCard:
      return '''<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#A020F0" fill-opacity="0.15"/>
  <path d="M14 16L20 8H34C35.1 8 36 8.9 36 10V38C36 39.1 35.1 40 34 40H14C12.9 40 12 39.1 12 38V18C12 17.1 12.5 16.3 14 16Z" fill="#A020F0"/>
  <rect x="17" y="12" width="3" height="8" rx="1.5" fill="white" fill-opacity="0.7"/>
  <rect x="22" y="10" width="3" height="10" rx="1.5" fill="white" fill-opacity="0.7"/>
  <rect x="27" y="12" width="3" height="8" rx="1.5" fill="white" fill-opacity="0.7"/>
  <rect x="16" y="28" width="16" height="2.5" rx="1.25" fill="white" fill-opacity="0.5"/>
  <rect x="16" y="33" width="10" height="2.5" rx="1.25" fill="white" fill-opacity="0.4"/>
</svg>''';

    case StorageCategoryIcon.images:
      return '''<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#FF6B6B" fill-opacity="0.15"/>
  <rect x="8" y="10" width="32" height="28" rx="6" fill="#FF6B6B"/>
  <circle cx="16" cy="18" r="3" fill="white" fill-opacity="0.9"/>
  <path d="M8 30L16 22L22 28L28 22L40 32V34C40 36.2 38.2 38 36 38H12C9.8 38 8 36.2 8 34V30Z" fill="white" fill-opacity="0.7"/>
</svg>''';

    case StorageCategoryIcon.videos:
      return '''<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#4ECDC4" fill-opacity="0.15"/>
  <rect x="6" y="12" width="28" height="24" rx="6" fill="#4ECDC4"/>
  <path d="M34 18L42 14V34L34 30V18Z" fill="#4ECDC4"/>
  <path d="M19 18.5L27 24L19 29.5V18.5Z" fill="white" fill-opacity="0.9"/>
</svg>''';

    case StorageCategoryIcon.documents:
      return '''<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#4A90D9" fill-opacity="0.15"/>
  <path d="M12 8H28L38 18V40C38 41.1 37.1 42 36 42H12C10.9 42 10 41.1 10 40V10C10 8.9 10.9 8 12 8Z" fill="#4A90D9"/>
  <path d="M28 8L38 18H30C28.9 18 28 17.1 28 16V8Z" fill="white" fill-opacity="0.5"/>
  <rect x="15" y="24" width="18" height="2.5" rx="1.25" fill="white" fill-opacity="0.8"/>
  <rect x="15" y="29" width="14" height="2.5" rx="1.25" fill="white" fill-opacity="0.6"/>
  <rect x="15" y="34" width="10" height="2.5" rx="1.25" fill="white" fill-opacity="0.5"/>
</svg>''';

    case StorageCategoryIcon.audio:
      return '''<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#FF9F43" fill-opacity="0.15"/>
  <circle cx="24" cy="24" r="14" fill="#FF9F43"/>
  <circle cx="24" cy="24" r="5" fill="white" fill-opacity="0.9"/>
  <path d="M20 14V34" stroke="white" stroke-width="2" stroke-linecap="round" stroke-opacity="0.5"/>
  <path d="M28 16V32" stroke="white" stroke-width="2" stroke-linecap="round" stroke-opacity="0.5"/>
  <path d="M16 18V30" stroke="white" stroke-width="2" stroke-linecap="round" stroke-opacity="0.4"/>
  <path d="M32 18V30" stroke="white" stroke-width="2" stroke-linecap="round" stroke-opacity="0.4"/>
</svg>''';

    case StorageCategoryIcon.apps:
      return '''<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#6C5CE7" fill-opacity="0.15"/>
  <rect x="8" y="8" width="14" height="14" rx="4" fill="#6C5CE7"/>
  <rect x="26" y="8" width="14" height="14" rx="4" fill="#A29BFE"/>
  <rect x="8" y="26" width="14" height="14" rx="4" fill="#A29BFE"/>
  <rect x="26" y="26" width="14" height="14" rx="4" fill="#6C5CE7"/>
</svg>''';

    case StorageCategoryIcon.downloads:
      return '''<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#00B894" fill-opacity="0.15"/>
  <path d="M24 8V30" stroke="#00B894" stroke-width="3" stroke-linecap="round"/>
  <path d="M14 22L24 32L34 22" stroke="#00B894" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="10" y="36" width="28" height="4" rx="2" fill="#00B894"/>
</svg>''';
  }
}

/// A widget that renders a beautiful colored icon for storage/category sections.
///
/// Usage:
/// ```dart
/// StorageCategoryIconWidget(icon: StorageCategoryIcon.images, size: 36)
/// ```
class StorageCategoryIconWidget extends StatelessWidget {
  final StorageCategoryIcon icon;
  final double size;

  const StorageCategoryIconWidget({
    super.key,
    required this.icon,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svgForIcon(icon),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
