import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class AvatarPreset {
  final String id;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const AvatarPreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });
}

final List<AvatarPreset> kAvatarPresets = [
  const AvatarPreset(
    id: 'avatar_doctor',
    label: 'Clínico',
    icon: Icons.medical_services_rounded,
    backgroundColor: Color(0xFF00796B),
    iconColor: Colors.white,
  ),
  const AvatarPreset(
    id: 'avatar_calm',
    label: 'Equilíbrio',
    icon: Icons.self_improvement_rounded,
    backgroundColor: Color(0xFF3F51B5),
    iconColor: Colors.white,
  ),
  const AvatarPreset(
    id: 'avatar_shield',
    label: 'Proteção',
    icon: Icons.shield_rounded,
    backgroundColor: Color(0xFF0288D1),
    iconColor: Colors.white,
  ),
  const AvatarPreset(
    id: 'avatar_heart',
    label: 'Vitalidade',
    icon: Icons.favorite_rounded,
    backgroundColor: Color(0xFFE91E63),
    iconColor: Colors.white,
  ),
  const AvatarPreset(
    id: 'avatar_leaf',
    label: 'Bem-estar',
    icon: Icons.eco_rounded,
    backgroundColor: Color(0xFF2E7D32),
    iconColor: Colors.white,
  ),
  const AvatarPreset(
    id: 'avatar_fitness',
    label: 'Energia',
    icon: Icons.directions_run_rounded,
    backgroundColor: Color(0xFFF57C00),
    iconColor: Colors.white,
  ),
  const AvatarPreset(
    id: 'avatar_mind',
    label: 'Foco Mental',
    icon: Icons.psychology_rounded,
    backgroundColor: Color(0xFF673AB7),
    iconColor: Colors.white,
  ),
  const AvatarPreset(
    id: 'avatar_sun',
    label: 'Radiante',
    icon: Icons.wb_sunny_rounded,
    backgroundColor: Color(0xFFFBC02D),
    iconColor: Color(0xFF3E2723),
  ),
];

class UserAvatar extends StatelessWidget {
  final String? picture;
  /// In-memory bytes for a locally picked image. Takes priority over [picture]
  /// for local photos, avoiding stale iOS /tmp paths that get cleaned up.
  final Uint8List? localImageBytes;
  final String fallbackInitial;
  final double radius;

  const UserAvatar({
    super.key,
    this.picture,
    this.localImageBytes,
    this.fallbackInitial = 'U',
    this.radius = 26,
  });

  Widget _fallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.clinicalTealLight,
      child: Text(
        fallbackInitial.isNotEmpty ? fallbackInitial[0].toUpperCase() : 'U',
        style: GoogleFonts.plusJakartaSans(
          fontSize: radius * 0.9,
          fontWeight: FontWeight.bold,
          color: AppColors.clinicalTealDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. In-memory bytes for locally picked images during active session
    if (localImageBytes != null && localImageBytes!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(localImageBytes!),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    if (picture != null && picture!.isNotEmpty) {
      // 2. Base64 data URI (stored directly in DB)
      if (picture!.startsWith('data:image')) {
        try {
          final commaIndex = picture!.indexOf(',');
          final base64Str =
              commaIndex != -1 ? picture!.substring(commaIndex + 1) : picture!;
          final bytes = base64Decode(base64Str);
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(bytes),
            onBackgroundImageError: (_, __) {},
            child: null,
          );
        } catch (_) {}
      }

      // 3. Network URL (from Cloud / Supabase Storage CDN)
      if (picture!.startsWith('http://') || picture!.startsWith('https://')) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(picture!),
          onBackgroundImageError: (_, __) {},
          child: null,
        );
      }

      // 4. Preset avatar from design system
      final preset = kAvatarPresets.where((p) => p.id == picture).firstOrNull;
      if (preset != null) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: preset.backgroundColor,
          child: Icon(
            preset.icon,
            color: preset.iconColor,
            size: radius * 1.1,
          ),
        );
      }
    }

    // 5. Fallback initial
    return _fallback();
  }
}

class AvatarSelectorSheet extends StatefulWidget {
  final String? currentPicture;
  final ValueChanged<String> onSelected;

  const AvatarSelectorSheet({
    super.key,
    this.currentPicture,
    required this.onSelected,
  });

  @override
  State<AvatarSelectorSheet> createState() => _AvatarSelectorSheetState();
}

class _AvatarSelectorSheetState extends State<AvatarSelectorSheet> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentPicture ?? kAvatarPresets.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Escolha seu Avatar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selecione um ícone de autocuidado para personalizar seu perfil.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kAvatarPresets.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final preset = kAvatarPresets[index];
              final isSelected = preset.id == _selectedId;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedId = preset.id;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: preset.backgroundColor,
                        border: Border.all(
                          color: isSelected ? AppColors.softIndigo : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.softIndigo.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            preset.icon,
                            color: preset.iconColor,
                            size: 28,
                          ),
                          if (isSelected)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.softIndigo,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preset.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.softIndigo : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.clinicalTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                widget.onSelected(_selectedId);
                Navigator.of(context).pop();
              },
              child: Text(
                'Confirmar Avatar',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
