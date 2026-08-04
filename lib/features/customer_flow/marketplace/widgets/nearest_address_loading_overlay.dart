import 'package:flutter/material.dart';

class NearestAddressLoadingOverlay extends StatelessWidget {
  const NearestAddressLoadingOverlay({super.key});

  static const Color _primaryColor = Color(0xFF163B52);
  static const Color _accentColor = Color(0xFF0F8B78);
  static const Color _mutedColor = Color(0xFF6B7D87);

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: ColoredBox(
        color: const Color(0x52163B52),
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Memuat alamat tersimpan',
            child: Container(
              key: const ValueKey('nearest-address-loading'),
              constraints: const BoxConstraints(maxWidth: 360),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26163B52),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: _accentColor,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Memuat alamat tersimpan…',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Menyiapkan pilihan lokasi Anda',
                          style: TextStyle(color: _mutedColor, fontSize: 12),
                        ),
                      ],
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
