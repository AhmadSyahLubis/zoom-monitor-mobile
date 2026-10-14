import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/zoom_account.dart';

class TestConnectionDialog extends StatelessWidget {
  final CheckConnectionResponse result;

  const TestConnectionDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: result.isConnected ? AppColors.statusAvailableBg : AppColors.statusMeetingBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result.isConnected ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: result.isConnected ? AppColors.statusAvailable : AppColors.statusMeeting,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              result.isConnected ? 'Koneksi Berhasil!' : 'Koneksi Gagal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: result.isConnected ? AppColors.statusAvailable : AppColors.statusMeeting,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),

            if (result.isConnected) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    _buildRow('Nama Akun', result.accountName),
                    const Divider(height: 14),
                    _buildRow('Tipe Lisensi', result.planType),
                    const Divider(height: 14),
                    _buildRow('Jumlah Pengguna', '${result.userCount} User'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: result.isConnected ? AppColors.primary : AppColors.textMain,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
      ],
    );
  }
}
