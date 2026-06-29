import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Colored category icons styled like the reference design but without the background box.
enum StorageCategoryIcon {
  internalStorage,
  sdCard,
  images,
  videos,
  documents,
  audio,
  archives,
  apks,
  shared,
  more,
}

String _svgForIcon(StorageCategoryIcon icon) {
  switch (icon) {
    // ── Internal Storage: green phone chip ──────────────────────────────────
    case StorageCategoryIcon.internalStorage:
      return '''<svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <rect x="22" y="14" width="36" height="52" rx="8" fill="#00B96B"/>
  <rect x="28" y="20" width="24" height="14" rx="4" fill="white" fill-opacity="0.8"/>
  <rect x="28" y="40" width="7" height="7" rx="2" fill="white" fill-opacity="0.7"/>
  <rect x="40" y="40" width="7" height="7" rx="2" fill="white" fill-opacity="0.7"/>
  <rect x="28" y="52" width="24" height="4" rx="2" fill="white" fill-opacity="0.5"/>
  <circle cx="40" cy="61" r="3" fill="white" fill-opacity="0.8"/>
</svg>''';

    // ── SD Card: purple sd card ──────────────────────────────────────────────
    case StorageCategoryIcon.sdCard:
      return '''<svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 26L36 14H56C58.2 14 60 15.8 60 18V62C60 64.2 58.2 66 56 66H24C21.8 66 20 64.2 20 62V30C20 28.1 21.6 26.3 24 26Z" fill="#8B5CF6"/>
  <rect x="28" y="19" width="5" height="14" rx="2.5" fill="white" fill-opacity="0.8"/>
  <rect x="37" y="16" width="5" height="17" rx="2.5" fill="white" fill-opacity="0.8"/>
  <rect x="46" y="19" width="5" height="14" rx="2.5" fill="white" fill-opacity="0.8"/>
  <rect x="26" y="46" width="28" height="4" rx="2" fill="white" fill-opacity="0.5"/>
  <rect x="26" y="54" width="18" height="4" rx="2" fill="white" fill-opacity="0.4"/>
</svg>''';

    // ── Docs: yellow/orange stacked pages ──────────────────────────────────
    case StorageCategoryIcon.documents:
      return '''<svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <rect x="26" y="20" width="36" height="44" rx="6" fill="#FFA726" fill-opacity="0.3"/>
  <rect x="20" y="24" width="36" height="44" rx="6" fill="#FB8C00"/>
  <path d="M20 46H56V62C56 64.2 54.2 66 52 66H24C21.8 66 20 64.2 20 62V46Z" fill="#E65100"/>
  <rect x="28" y="32" width="20" height="3" rx="1.5" fill="white" fill-opacity="0.9"/>
  <rect x="28" y="39" width="16" height="3" rx="1.5" fill="white" fill-opacity="0.7"/>
</svg>''';

    // ── Images: pink/red mountain landscape ────────────────────────────────
    case StorageCategoryIcon.images:
      return '''<svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <rect x="14" y="16" width="52" height="48" rx="10" fill="#F44336"/>
  <circle cx="26" cy="30" r="6" fill="white" fill-opacity="0.9"/>
  <path d="M14 50L28 36L38 46L48 36L66 54V60C66 62.2 64.2 64 62 64H18C15.8 64 14 62.2 14 60V50Z" fill="white" fill-opacity="0.75"/>
</svg>''';

    // ── Videos: blue/indigo camera ─────────────────────────────────────────
    case StorageCategoryIcon.videos:
      return '''<svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="24" width="44" height="32" rx="8" fill="#5C6BC0"/>
  <path d="M54 32L70 24V56L54 48V32Z" fill="#7986CB"/>
  <path d="M30 31L44 40L30 49V31Z" fill="white" fill-opacity="0.95"/>
</svg>''';

    // ── Music: teal music note ─────────────────────────────────────────────
    case StorageCategoryIcon.audio:
      return '''<svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <circle cx="30" cy="56" r="9" fill="#00BFA5"/>
  <circle cx="54" cy="50" r="9" fill="#00BFA5"/>
  <path d="M39 56V22L63 16V50" stroke="#00BFA5" stroke-width="6" stroke-linecap="round"/>
</svg>''';

    // ── Archives: blue archive box ─────────────────────────────────────────
    case StorageCategoryIcon.archives:
      return '''<svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <rect x="12" y="16" width="56" height="14" rx="6" fill="#2196F3"/>
  <rect x="16" y="30" width="48" height="34" rx="6" fill="#42A5F5"/>
  <rect x="28" y="38" width="24" height="6" rx="3" fill="white" fill-opacity="0.9"/>
  <path d="M34 20H46" stroke="white" stroke-width="4" stroke-linecap="round"/>
</svg>''';

    // ── APKs: green Android robot ──────────────────────────────────────────
    case StorageCategoryIcon.apks:
      return '''<svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="40" cy="52" rx="22" ry="18" fill="#4CAF50"/>
  <rect x="18" y="44" width="44" height="22" rx="10" fill="#4CAF50"/>
  <circle cx="30" cy="50" r="3" fill="white" fill-opacity="0.9"/>
  <circle cx="50" cy="50" r="3" fill="white" fill-opacity="0.9"/>
  <path d="M26 36C26 28 54 28 54 36" stroke="#4CAF50" stroke-width="4" stroke-linecap="round" fill="none"/>
  <line x1="28" y1="26" x2="24" y2="20" stroke="#4CAF50" stroke-width="3" stroke-linecap="round"/>
  <line x1="52" y1="26" x2="56" y2="20" stroke="#4CAF50" stroke-width="3" stroke-linecap="round"/>
  <circle cx="24" cy="19" r="3" fill="#4CAF50"/>
  <circle cx="56" cy="19" r="3" fill="#4CAF50"/>
</svg>''';

    // ── Shared: blue up/down arrows ────────────────────────────────────────
    case StorageCategoryIcon.shared:
      return '''<svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <path d="M40 16L52 30H44V50H36V30H28L40 16Z" fill="#29B6F6"/>
  <path d="M40 64L28 50H36V30H44V50H52L40 64Z" fill="#0288D1"/>
</svg>''';

    // ── More: blue 2x2 grid ────────────────────────────────────────────────
    case StorageCategoryIcon.more:
      return '''<svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <rect x="14" y="14" width="22" height="22" rx="6" fill="#1E88E5"/>
  <rect x="44" y="14" width="22" height="22" rx="6" fill="#42A5F5"/>
  <rect x="14" y="44" width="22" height="22" rx="6" fill="#42A5F5"/>
  <rect x="44" y="44" width="22" height="22" rx="6" fill="#1E88E5"/>
</svg>''';
  }
}

/// A widget that renders a styled category/storage icon without background square.
class StorageCategoryIconWidget extends StatelessWidget {
  final StorageCategoryIcon icon;
  final double size;

  const StorageCategoryIconWidget({
    super.key,
    required this.icon,
    this.size = 56,
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
