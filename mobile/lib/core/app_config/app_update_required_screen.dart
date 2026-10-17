import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

class AppUpdateRequiredScreen extends StatelessWidget {
  final String? minSupportedVersion;

  const AppUpdateRequiredScreen({
    super.key,
    this.minSupportedVersion,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update_alt_rounded, size: 64),
              const SizedBox(height: 20),
              Text(
                l10n.appUpdateTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.appUpdateMessage(minSupportedVersion ?? ''),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  height: 1.45,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () {},
                child: Text(l10n.appUpdateButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
