import 'package:flutter/material.dart';

/// Palette « Dossier » — identique à celle de l'espace web, adaptée au tactile.
/// Le vert, l'ambre et le rouge restent réservés aux statuts.
class AppColors {
  // Fonds
  static const paper = Color(0xFFECF1EF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF6F9F7);
  static const surfaceSunk = Color(0xFFEDF2EF);

  // Encre
  static const ink = Color(0xFF0F1D1A);
  static const ink2 = Color(0xFF33453F);
  static const inkMuted = Color(0xFF63776F);
  static const faint = Color(0xFF8A9B93);

  // Filets
  static const line = Color(0xFFE1E8E4);
  static const line2 = Color(0xFFCEDAD4);

  // Marque
  static const brand = Color(0xFF17506E);
  static const brandHi = Color(0xFF2AA8C4);
  static const brandSoft = Color(0xFFE2EEF3);
  static const brandLine = Color(0xFFB7D4E0);

  // Plan sombre (en-têtes, comme le rail du web)
  static const rail = Color(0xFF101E1B);
  static const rail2 = Color(0xFF1A2C28);
  static const rail3 = Color(0xFF243B36);
  static const railInk = Color(0xFFEDF4F1);
  static const railMuted = Color(0xFF8FA79D);
  static const railAccent = Color(0xFF5FCBE0);

  // Statuts
  static const ok = Color(0xFF1E7A4E);
  static const okSoft = Color(0xFFE0F0E7);
  static const okLine = Color(0xFFB2D9C2);
  static const warn = Color(0xFF916510);
  static const warnSoft = Color(0xFFF8ECD6);
  static const warnLine = Color(0xFFE4C994);
  static const danger = Color(0xFFAE3A34);
  static const dangerSoft = Color(0xFFF9E4E2);
  static const dangerLine = Color(0xFFECBBB6);

  // Types de demande — palette de données retenue par validation, pas à l'œil :
  // séparation daltonienne ΔE 21,1 (seuil 8) et chroma suffisant sur fond clair
  // comme sombre. Identique à celle de l'espace web.
  static const tConge = Color(0xFF0FA7BF);
  static const tPermission = Color(0xFF6B3CC1);
  static const tMateriel = Color(0xFF9A5F1A);

  // Compatibilité avec l'ancien nommage
  static const bg = paper;
  static const accent = brand;
  static const accentSoft = brandSoft;

  /// Dégradé signature : porte les actions primaires et les plans sombres.
  static const gradBrand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF17506E), Color(0xFF2AA8C4)],
  );

  /// Nappe sombre des en-têtes, avec sa lueur cyan en haut à droite.
  static const gradRail = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B3833), Color(0xFF0D1917)],
  );
}

/// Ombres : les cartes de contenu flottent au lieu d'être cernées d'un filet.
/// Deux couches — un contact net, une diffusion large — comme sur le web.
class AppShadows {
  static const carte = [
    BoxShadow(color: Color(0x0D0E1C18), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0E1C18), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const flottant = [
    BoxShadow(color: Color(0x120E1C18), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1F0E1C18), blurRadius: 40, offset: Offset(0, 18)),
  ];

  static List<BoxShadow> teinte(Color couleur) => [
    BoxShadow(
      color: couleur.withValues(alpha: 0.30),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Rayons partagés.
class AppRadius {
  static const sm = 11.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

/// Texte courant. Une seule famille des deux plateformes à l'espace web :
/// l'application se reconnaît avant même d'être lue.
const familleTexte = 'IBM Plex Sans';

/// Voix de la marque, réservée au logotype, aux titres d'écran et aux grands
/// chiffres. Fraunces n'embarque pas « → » : tout glyphe hors de son jeu
/// doit rester en Plex, sinon il se rendrait en tofu.
const familleTitre = 'Fraunces';

/// Style d'affichage — le pendant mobile de `--font-display` du web.
TextStyle titreDisplay({
  required double taille,
  Color couleur = AppColors.ink,
  FontWeight graisse = FontWeight.w600,
  double? hauteur,
  double espacement = -0.6,
}) => TextStyle(
  fontFamily: familleTitre,
  fontSize: taille,
  fontWeight: graisse,
  color: couleur,
  height: hauteur,
  letterSpacing: espacement,
);

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true, fontFamily: familleTexte);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      secondary: AppColors.brandHi,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      outline: AppColors.line2,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: familleTitre,
        color: AppColors.ink,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.faint),
      labelStyle: const TextStyle(color: AppColors.inkMuted, fontSize: 14),
      floatingLabelStyle: const TextStyle(
        color: AppColors.brand,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.line2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.line2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.line2,
        disabledForegroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink2,
        side: const BorderSide(color: AppColors.line2),
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.brand),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.brand,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.rail,
      contentTextStyle: const TextStyle(color: AppColors.railInk),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: familleTitre,
        color: AppColors.ink,
        fontSize: 18.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.inkMuted,
        fontSize: 14.5,
        height: 1.45,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: familleTexte,
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}

/// Étiquette majuscule espacée — le motif d'annotation partagé avec le web.
const eyebrowStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.1,
  color: AppColors.inkMuted,
);

Color statutColor(String statut) {
  switch (statut) {
    case 'validee':
      return AppColors.ok;
    case 'refusee':
      return AppColors.danger;
    default:
      return AppColors.warn;
  }
}

Color statutColorSoft(String statut) {
  switch (statut) {
    case 'validee':
      return AppColors.okSoft;
    case 'refusee':
      return AppColors.dangerSoft;
    default:
      return AppColors.warnSoft;
  }
}

Color statutColorLine(String statut) {
  switch (statut) {
    case 'validee':
      return AppColors.okLine;
    case 'refusee':
      return AppColors.dangerLine;
    default:
      return AppColors.warnLine;
  }
}

String statutLabel(String statut) {
  switch (statut) {
    case 'validee':
      return 'Validée';
    case 'refusee':
      return 'Refusée';
    default:
      return 'En attente';
  }
}

String typeLabel(String type) {
  switch (type) {
    case 'conge':
      return 'Congé';
    case 'permission':
      return 'Permission';
    case 'materiel':
      return 'Matériel';
    default:
      return type;
  }
}

IconData typeIcon(String type) {
  switch (type) {
    case 'conge':
      return Icons.wb_sunny_outlined;
    case 'permission':
      return Icons.schedule_outlined;
    case 'materiel':
      return Icons.inventory_2_outlined;
    default:
      return Icons.description_outlined;
  }
}

Color typeColor(String type) {
  switch (type) {
    case 'conge':
      return AppColors.tConge;
    case 'permission':
      return AppColors.tPermission;
    case 'materiel':
      return AppColors.tMateriel;
    default:
      return AppColors.inkMuted;
  }
}

/// Dégradé de la tuile d'un type de demande — la même teinte validée, en
/// deux tons : la tuile devient un objet, pas un aplat.
LinearGradient typeGradient(String type) {
  final couleur = typeColor(type);

  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(couleur, Colors.white, 0.12)!,
      Color.lerp(couleur, const Color(0xFF0B1F2A), 0.22)!,
    ],
  );
}

String roleLabel(String role) {
  switch (role) {
    case 'admin':
      return 'Administrateur';
    case 'rh':
      return 'Ressources humaines';
    default:
      return 'Employé';
  }
}

/// Formule un délai en heures de la façon la plus lisible pour un humain.
String formaterDelai(double? heures) {
  if (heures == null) return '—';
  if (heures < 1) return '${(heures * 60).round()} min';
  if (heures < 48) return '${heures.toStringAsFixed(0)} h';
  return '${(heures / 24).toStringAsFixed(0)} j';
}
