import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/error_message_resolver.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/locale_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/avatar_selector_sheet.dart';

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
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _localImageBytes = bytes;
          _selectedPicture = base64Image;
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

  void _showAvatarSelectorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AvatarSelectorSheet(
        currentPicture: _selectedPicture,
        onSelected: (avatarId) {
          setState(() {
            _selectedPicture = avatarId;
            _localImageBytes = null;
          });
        },
      ),
    );
  }

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
              'Alterar Foto',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Escolha como deseja selecionar sua foto de perfil.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            // Camera option
            _PhotoOptionTile(
              icon: Icons.camera_alt_rounded,
              label: 'Câmera',
              subtitle: 'Tirar uma nova foto',
              color: AppColors.clinicalTeal,
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            // Gallery option
            _PhotoOptionTile(
              icon: Icons.photo_library_rounded,
              label: 'Galeria',
              subtitle: 'Escolher da biblioteca de fotos',
              color: AppColors.softIndigo,
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            // Presets option
            _PhotoOptionTile(
              icon: Icons.palette_outlined,
              label: 'Avatares Clínicos',
              subtitle: 'Escolher um ícone ilustrado de autocuidado',
              color: AppColors.clinicalTealDark,
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (ctx) => AvatarSelectorSheet(
                    currentPicture: _selectedPicture,
                    onSelected: (avatarId) {
                      setState(() {
                        _selectedPicture = avatarId;
                        _localImageBytes = null;
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
                  'Cancelar',
                  style: GoogleFonts.plusJakartaSans(
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
              primary: AppColors.clinicalTeal,
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
          backgroundColor: AppColors.clinicalTeal,
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
          backgroundColor: AppColors.clinicalTeal,
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
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Deseja realmente encerrar sua sessão? Seus dados clínicos permanecem seguros e criptografados.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondaryLight),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyCrimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sair',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
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

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          l10n.settingsTitle,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppColors.textPrimaryLight,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, color: AppColors.clinicalTeal),
                          const SizedBox(width: 8),
                          Text(
                            l10n.profileSection,
                            style: GoogleFonts.plusJakartaSans(
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
                                    color: AppColors.clinicalTeal,
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
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton.icon(
                          onPressed: _showAvatarSelectorSheet,
                          icon: const Icon(Icons.palette_outlined, size: 16),
                          label: Text(
                            l10n.changeAvatar,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.clinicalTeal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.nameLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const Key('settings_name_input'),
                        controller: _nameController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Seu nome completo',
                          prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.clinicalTeal),
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.outlineLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.outlineLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.clinicalTeal, width: 2),
                          ),
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
                            style: GoogleFonts.plusJakartaSans(
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
                                color: AppColors.clinicalTealLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.yearsOld(age),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.clinicalTealDark,
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
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.outlineLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cake_outlined, color: AppColors.clinicalTeal),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDateOfBirth != null
                                      ? DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!)
                                      : 'Selecione sua data de nascimento',
                                  style: GoogleFonts.plusJakartaSans(
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
                            backgroundColor: AppColors.clinicalTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, color: AppColors.softIndigo),
                          const SizedBox(width: 8),
                          Text(
                            l10n.securitySection,
                            style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: l10n.currentPasswordHint,
                          prefixIcon: const Icon(Icons.key_outlined, color: AppColors.softIndigo),
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
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.outlineLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.outlineLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.softIndigo, width: 2),
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
                        style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: l10n.newPasswordHint,
                          prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.softIndigo),
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
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.outlineLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.outlineLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.softIndigo, width: 2),
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
                        style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: l10n.confirmPasswordHint,
                          prefixIcon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.softIndigo),
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
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.outlineLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.outlineLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.softIndigo, width: 2),
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
                        style: GoogleFonts.plusJakartaSans(
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
                            backgroundColor: AppColors.softIndigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.language_rounded,
                label: l10n.settingsLanguageSection,
                color: AppColors.softIndigo,
              ),
              const SizedBox(height: 10),
              Material(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineLight),
                  ),
                  child: Column(
                    children: [
                      _LanguageTile(
                        flag: '🇧🇷',
                        label: l10n.settingsLanguagePortuguese,
                        locale: const Locale('pt', 'BR'),
                      ),
                      const Divider(height: 1, color: AppColors.outlineLight),
                      _LanguageTile(
                        flag: '🇪🇸',
                        label: l10n.settingsLanguageSpanish,
                        locale: const Locale('es'),
                      ),
                      const Divider(height: 1, color: AppColors.outlineLight),
                      _LanguageTile(
                        flag: '🇺🇸',
                        label: l10n.settingsLanguageEnglish,
                        locale: const Locale('en'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.shield_outlined,
                label: l10n.settingsPrivacySection,
                color: AppColors.clinicalTeal,
              ),
              const SizedBox(height: 10),
              Material(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineLight),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        key: const Key('settings_privacy_tile'),
                        leading: const Icon(Icons.shield_outlined, color: AppColors.clinicalTeal),
                        title: Text(
                          l10n.settingsPrivacyCenterTile,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          l10n.settingsPrivacyCenterSubtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
                        onTap: () => context.push(RoutePaths.privacyCenter),
                      ),
                      const Divider(height: 1, color: AppColors.outlineLight),
                      ListTile(
                        key: const Key('settings_history_tile'),
                        leading: const Icon(Icons.analytics_outlined, color: AppColors.softIndigo),
                        title: Text(
                          l10n.settingsDataHistoryTile,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          l10n.settingsDataHistorySubtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
                        onTap: () => context.push(RoutePaths.history),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineLight),
                  ),
                  child: ListTile(
                    key: const Key('settings_logout_tile'),
                    leading: const Icon(Icons.logout_rounded, color: AppColors.emergencyCrimson),
                    title: Text(
                      l10n.logoutButton,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.emergencyCrimson,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.emergencyCrimson),
                    onTap: _handleLogout,
                  ),
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
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
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
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
          color: isSelected ? AppColors.softIndigo : AppColors.textPrimaryLight,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.softIndigo, size: 20)
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
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
