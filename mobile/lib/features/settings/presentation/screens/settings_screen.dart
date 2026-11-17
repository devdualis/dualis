import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/error_message_resolver.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/locale_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../consent/presentation/ai_consent_widgets.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../widgets/avatar_selector_sheet.dart';
import '../widgets/settings_row_icon.dart';
import '../widgets/biometric_lock_tile.dart';
import '../widgets/voice_read_aloud_tile.dart';
import 'photo_crop_screen.dart';
import '../../../../core/notifications/notifications_blocked_notice.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  String? _selectedPicture;
  Uint8List? _localImageBytes; // in-memory bytes for a locally picked photo
  DateTime? _selectedDateOfBirth;
  bool _showPhotoAdjustHint = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _selectedPicture = user?.picture;
    // _localImageBytes stays null on init — only populated after a new pick.
    if (user?.dateOfBirth != null && user!.dateOfBirth!.isNotEmpty) {
      _selectedDateOfBirth = DateTime.tryParse(user.dateOfBirth!);
    }
    _checkPhotoAdjustHint();
  }

  Future<void> _checkPhotoAdjustHint() async {
    final pic = _selectedPicture;
    if (pic == null || pic.isEmpty || pic.startsWith('avatar_')) return;
    try {
      final adjusted =
          await ref.read(secureStorageServiceProvider).isPhotoFramingAdjusted();
      if (!adjusted && mounted) {
        setState(() => _showPhotoAdjustHint = true);
      }
    } catch (_) {}
  }

  Future<void> _handleAdjustHintTap() async {
    Uint8List? sourceBytes = _localImageBytes;
    if (sourceBytes == null &&
        _selectedPicture != null &&
        _selectedPicture!.startsWith('data:image')) {
      try {
        final commaIndex = _selectedPicture!.indexOf(',');
        final base64Str = commaIndex != -1
            ? _selectedPicture!.substring(commaIndex + 1)
            : _selectedPicture!;
        sourceBytes = base64Decode(base64Str);
      } catch (_) {}
    }

    if (sourceBytes != null) {
      final bytes = await PhotoCropScreen.open(context, sourceBytes);
      if (bytes != null && mounted) {
        final base64Image = 'data:image/png;base64,${base64Encode(bytes)}';
        await ref.read(secureStorageServiceProvider).setPhotoFramingAdjusted();
        setState(() {
          _localImageBytes = bytes;
          _selectedPicture = base64Image;
          _showPhotoAdjustHint = false;
        });
        return;
      }
    } else {
      _showPhotoPickerSheet();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age >= 0 ? age : null;
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // close the bottom sheet
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (image != null && mounted) {
        final picked = await image.readAsBytes();
        if (!mounted) return;
        // Circular crop with zoom and drag before saving (strategy §13).
        final bytes = await PhotoCropScreen.open(context, picked);
        if (bytes == null || !mounted) return;
        final base64Image = 'data:image/png;base64,${base64Encode(bytes)}';
        await ref.read(secureStorageServiceProvider).setPhotoFramingAdjusted();
        setState(() {
          _localImageBytes = bytes;
          _selectedPicture = base64Image;
          _showPhotoAdjustHint = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorCameraGalleryAccess),
            backgroundColor: AppColors.emergencyCrimson,
          ),
        );
      }
    }
  }

  void _showPhotoPickerSheet() {
    final l10n = AppLocalizations.of(context);
    // Background and corners come from the glass bottom-sheet theme.
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
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
              l10n.changeAvatar,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.settingsChangePhotoSubtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            // Camera option
            _PhotoOptionTile(
              icon: Icons.camera_alt_rounded,
              label: l10n.settingsPhotoCamera,
              subtitle: l10n.settingsPhotoCameraSubtitle,
              color: AppColors.dualisNavy,
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            // Gallery option
            _PhotoOptionTile(
              icon: Icons.photo_library_rounded,
              label: l10n.settingsPhotoGallery,
              subtitle: l10n.settingsPhotoGallerySubtitle,
              color: AppColors.dualisNavy,
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            // Presets option
            _PhotoOptionTile(
              icon: Icons.palette_outlined,
              label: l10n.settingsPhotoPresets,
              subtitle: l10n.settingsPhotoPresetsSubtitle,
              color: AppColors.dualisNavy,
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => AvatarSelectorSheet(
                    currentPicture: _selectedPicture,
                    onSelected: (avatarId) {
                      setState(() {
                        _selectedPicture = avatarId;
                        _localImageBytes = null;
                        _showPhotoAdjustHint = false;
                      });
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Cancel
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.cancel,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDateOfBirth ?? DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.dualisNavy,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _handleSaveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingProfile = true;
    });

    final formattedDob = _selectedDateOfBirth != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!)
        : null;

    final success = await ref.read(authControllerProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          dateOfBirth: formattedDob,
          picture: _selectedPicture,
        );

    if (!mounted) return;

    setState(() {
      _isSavingProfile = false;
    });

    final l10n = AppLocalizations.of(context);
    if (success) {
      final updatedUser = ref.read(authControllerProvider).user;
      setState(() {
        _localImageBytes = null;
        _selectedPicture = updatedUser?.picture ?? _selectedPicture;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileUpdatedSuccess),
          backgroundColor: AppColors.dualisNavy,
        ),
      );
    } else {
      final l10n = AppLocalizations.of(context);
      final rawError = ref.read(authControllerProvider).errorMessage;
      final error = rawError != null ? ErrorMessageResolver.resolve(rawError, l10n) : l10n.errorUpdateProfile;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.emergencyCrimson,
        ),
      );
    }
  }

  Future<void> _handleChangePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordsDoNotMatch),
          backgroundColor: AppColors.emergencyCrimson,
        ),
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    final success = await ref.read(authControllerProvider.notifier).changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );

    if (!mounted) return;

    setState(() {
      _isChangingPassword = false;
    });

    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordChangedSuccess),
          backgroundColor: AppColors.dualisNavy,
        ),
      );
    } else {
      final rawError = ref.read(authControllerProvider).errorMessage;
      final error = rawError != null ? ErrorMessageResolver.resolve(rawError, l10n) : l10n.errorChangePassword;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.emergencyCrimson,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.logoutButton,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.settingsLogoutConfirmBody,
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.inter(color: AppColors.textSecondaryLight),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyCrimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.settingsLogoutConfirmAction,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        context.go(RoutePaths.onboarding);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    final age = _calculateAge(_selectedDateOfBirth);
    final isPremium = ref.watch(premiumProfilesEnabledProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDepth,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDepth,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.settingsTitle,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 19,
            letterSpacing: -0.2,
            color: AppColors.dualisNavy,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.dualisNavy),
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).pop()
              : context.go(RoutePaths.home),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: double.infinity, child: GlassCard(padding: const EdgeInsets.all(20), child: Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SettingsRowIcon(Icons.person_outline_rounded),
                          const SizedBox(width: 12),
                          Text(
                            l10n.profileSection,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _showPhotoPickerSheet,
                              child: UserAvatar(
                                picture: _selectedPicture,
                                localImageBytes: _localImageBytes,
                                fallbackInitial: user?.name.isNotEmpty == true ? user!.name[0] : 'U',
                                radius: 42,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: _showPhotoPickerSheet,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.gradientNavy,
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_showPhotoAdjustHint) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: GestureDetector(
                            key: const Key('photo_adjust_hint'),
                            onTap: _handleAdjustHintTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.iconTileTint,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.dualisNavy.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.crop_rounded,
                                    size: 14,
                                    color: AppColors.dualisNavy,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.settingsPhotoAdjustHint,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dualisNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton.icon(
                          onPressed: _showPhotoPickerSheet,
                          icon: const Icon(Icons.palette_outlined, size: 16),
                          label: Text(
                            l10n.changeAvatar,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.dualisNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.nameLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const Key('settings_name_input'),
                        controller: _nameController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: l10n.settingsNameHint,
                          prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.dualisNavy),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return l10n.errorNameMinLength;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.dateOfBirthLabel,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          if (age != null)
                            Container(
                              key: const Key('settings_age_badge'),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.iconTileTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.yearsOld(age),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dualisNavy,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        key: const Key('settings_dob_picker'),
                        onTap: _pickDateOfBirth,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outlineLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cake_outlined, color: AppColors.dualisNavy),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDateOfBirth != null
                                      ? DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!)
                                      : l10n.selectDateOfBirthHint,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: _selectedDateOfBirth != null
                                        ? AppColors.textPrimaryLight
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_month_rounded, color: AppColors.textSecondaryLight, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          key: const Key('settings_save_profile_button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dualisNavy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: _isSavingProfile ? null : _handleSaveProfile,
                          child: _isSavingProfile
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  l10n.saveProfile,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ))),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: GlassCard(padding: const EdgeInsets.all(20), child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SettingsRowIcon(Icons.lock_outline_rounded),
                          const SizedBox(width: 12),
                          Text(
                            l10n.securitySection,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.currentPassword,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const Key('settings_current_password_input'),
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPassword,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: l10n.currentPasswordHint,
                          prefixIcon: const Icon(Icons.key_outlined, color: AppColors.dualisNavy),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondaryLight,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.errorCurrentPasswordRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.newPassword,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const Key('settings_new_password_input'),
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: l10n.newPasswordHint,
                          prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.dualisNavy),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondaryLight,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return l10n.errorNewPasswordMinLength;
                          }
                          final hasLetters = RegExp(r'[A-Za-z]').hasMatch(value);
                          final hasDigits = RegExp(r'\d').hasMatch(value);
                          if (!hasLetters || !hasDigits) {
                            return l10n.errorPasswordLettersAndDigits;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.confirmNewPassword,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const Key('settings_confirm_password_input'),
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: l10n.confirmPasswordHint,
                          prefixIcon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.dualisNavy),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondaryLight,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value != _newPasswordController.text) {
                            return l10n.passwordsDoNotMatch;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.passwordComplexityHint,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          key: const Key('settings_change_password_button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dualisNavy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: _isChangingPassword ? null : _handleChangePassword,
                          child: _isChangingPassword
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  l10n.changePassword,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ))),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.language_rounded,
                label: l10n.settingsLanguageSection,
                color: AppColors.dualisNavy,
              ),
              const SizedBox(height: 10),
              _SettingsGroup(child: Column(
                    children: [
                      _LanguageTile(
                        flag: '🇧🇷',
                        label: l10n.settingsLanguagePortuguese,
                        locale: const Locale('pt', 'BR'),
                      ),
                      const SettingsDivider(),
                      _LanguageTile(
                        flag: '🇪🇸',
                        label: l10n.settingsLanguageSpanish,
                        locale: const Locale('es'),
                      ),
                      const SettingsDivider(),
                      _LanguageTile(
                        flag: '🇺🇸',
                        label: l10n.settingsLanguageEnglish,
                        locale: const Locale('en'),
                      ),
                    ],
                  )),
              const SizedBox(height: 12),
              const NotificationsBlockedNotice(),
              const SizedBox(height: 8),
              _SectionLabel(
                icon: Icons.bookmark_border_rounded,
                label: l10n.settingsRecordsAndHabitsSection,
                color: AppColors.dualisNavy,
              ),
              const SizedBox(height: 10),
              _SettingsGroup(child: Column(
                    children: [
                      ListTile(
                        key: const Key('settings_history_tile'),
                        leading: const SettingsRowIcon(Icons.analytics_outlined),
                        title: Text(
                          l10n.settingsDataHistoryTile,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          l10n.settingsDataHistorySubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
                        onTap: () => context.push(RoutePaths.history),
                      ),
                      const SettingsDivider(),
                      ListTile(
                        key: const Key('settings_reminders_tile'),
                        leading: const SettingsRowIcon(Icons.notifications_none_rounded),
                        title: Text(
                          l10n.settingsRemindersTile,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          l10n.settingsRemindersSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
                        onTap: () => context.push(RoutePaths.reminders),
                      ),
                    ],
                  )),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.shield_outlined,
                label: l10n.settingsPrivacySection,
                color: AppColors.dualisNavy,
              ),
              const SizedBox(height: 10),
              _SettingsGroup(child: Column(
                    children: [
                      // Premium only; render nothing on Free builds.
                      const BiometricLockTile(),
                      const VoiceReadAloudTile(),
                      // Every signed-in person: LGPD Art. 11, I choice.
                      const AiConsentTile(),
                      ListTile(
                        key: const Key('settings_privacy_tile'),
                        leading: const SettingsRowIcon(Icons.shield_outlined),
                        title: Text(
                          l10n.settingsPrivacyCenterTile,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          l10n.settingsPrivacyCenterSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
                        onTap: () => context.push(RoutePaths.privacyCenter),
                      ),
                      const SettingsDivider(),
                      ListTile(
                        key: const Key('settings_terms_tile'),
                        leading: const SettingsRowIcon(Icons.description_outlined),
                        title: Text(
                          l10n.settingsTermsTile,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          l10n.settingsTermsSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
                        onTap: () => context.push(RoutePaths.termsOfService),
                      ),
                      const SettingsDivider(),
                      ListTile(
                        key: const Key('settings_privacy_policy_tile'),
                        leading: const SettingsRowIcon(Icons.policy_outlined),
                        title: Text(
                          l10n.settingsPrivacyPolicyTile,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          l10n.settingsPrivacyPolicySubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
                        onTap: () => context.push(RoutePaths.privacyPolicy),
                      ),
                    ],
                  )),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.notifications_active_outlined,
                label: l10n.settingsCommunicationsSection,
                color: AppColors.dualisNavy,
              ),
              const SizedBox(height: 10),
              _SettingsGroup(child: Column(
                    children: [
                      SwitchListTile(
                        key: const Key('settings_marketing_optout_switch'),
                        value: true,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.dualisNavy,
                        secondary: const SettingsRowIcon(Icons.lightbulb_outline_rounded),
                        title: Text(
                          l10n.settingsEducationalTipsTile,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          l10n.settingsEducationalTipsSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        onChanged: (val) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                val
                                    ? l10n.settingsEducationalTipsOn
                                    : l10n.settingsEducationalTipsOff,
                              ),
                              backgroundColor: AppColors.dualisNavy,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  )),
              const SizedBox(height: 20),
              // Plan row: shows the tier quietly. Free gets a link to the
              // Premium page; Premium has no call to action.
              _SettingsGroup(child: ListTile(
                    key: const Key('settings_plan_tile'),
                    leading: const SettingsRowIcon(Icons.card_membership_outlined),
                    title: Text(
                      isPremium ? l10n.settingsPlanPremium : l10n.settingsPlanFree,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isPremium
                        ? null
                        : TextButton(
                            key: const Key('settings_plan_see_premium'),
                            onPressed: () => context.push(RoutePaths.premiumPromo),
                            child: Text(
                              l10n.settingsPlanSeePremium,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dualisNavy,
                              ),
                            ),
                          ),
                  )),
              const SizedBox(height: 20),
              _SettingsGroup(destructive: true, child: ListTile(
                    key: const Key('settings_logout_tile'),
                    leading: const SettingsRowIcon(Icons.logout_rounded, color: AppColors.emergencyCrimson),
                    title: Text(
                      l10n.logoutButton,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.emergencyCrimson,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.emergencyCrimson),
                    onTap: _handleLogout,
                  )),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      'DualisCheckUp • v1.0.0 (Build 2026.1)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.settingsOperatorInfo,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondaryLight.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grouped glass card holding a list of rows. [destructive] draws the
/// outlined red variant used for the logout row.
class _SettingsGroup extends StatelessWidget {
  final Widget child;
  final bool destructive;

  const _SettingsGroup({required this.child, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final inner = Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: child,
      ),
    );
    if (destructive) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.emergencyCrimson.withValues(alpha: 0.45),
          ),
        ),
        child: inner,
      );
    }
    return GlassCard(radius: 22, padding: EdgeInsets.zero, child: inner);
  }
}

class _LanguageTile extends ConsumerWidget {
  final String flag;
  final String label;
  final Locale locale;

  const _LanguageTile({
    required this.flag,
    required this.label,
    required this.locale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isSelected = currentLocale.languageCode == locale.languageCode;

    return ListTile(
      selected: isSelected,
      selectedTileColor: AppColors.iconTileTint,
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
          color: isSelected ? AppColors.dualisNavy : AppColors.textPrimaryLight,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.dualisNavy, size: 20)
          : const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textSecondaryLight, size: 20),
      onTap: () => ref.read(localeProvider.notifier).setLocale(locale),
    );
  }
}

class _PhotoOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PhotoOptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outlineLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.iconTileTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
