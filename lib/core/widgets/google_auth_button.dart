import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Tombol autentikasi Google yang konsisten untuk semua flow login/registrasi.
///
/// Client ID dan token tidak ditangani widget ini; widget hanya bertanggung
/// jawab terhadap presentasi dan state interaksi.
class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  static const Color _foregroundColor = Color(0xFF1E232C);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _foregroundColor,
            disabledBackgroundColor: const Color(0xFFF8F9FA),
            disabledForegroundColor: const Color(0xFF98A2B3),
            side: const BorderSide(color: Color(0xFFD0D5DD)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isLoading
                  ? const Center(
                      key: ValueKey('google-loading'),
                      child: SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: _foregroundColor,
                        ),
                      ),
                    )
                  : Stack(
                      key: const ValueKey('google-label'),
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SvgPicture.asset(
                            'assets/google_g_logo.svg',
                            width: 22,
                            height: 22,
                            semanticsLabel: 'Google',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
