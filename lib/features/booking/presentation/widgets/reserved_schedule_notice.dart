import 'package:flutter/material.dart';

class ReservedScheduleNotice extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool>? onChanged;
  const ReservedScheduleNotice(
      {super.key, this.checked = false, this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFCD34D))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Jadwal tetap dicadangkan',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF78350F))),
          const SizedBox(height: 6),
          const Text(
              'Rapat yang pernah live dapat dimulai lagi sampai akhir jadwal. Pastikan dengan penanggung jawab sebelum melakukan force booking.',
              style: TextStyle(
                  fontSize: 12, height: 1.4, color: Color(0xFF78350F))),
          if (onChanged != null)
            Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: checked,
                    onChanged: (value) => onChanged!(value ?? false),
                    title: const Text(
                        'Saya sudah memastikan rapat sebelumnya tidak akan dilanjutkan dan menyetujui booking baru pada jadwal tersebut.',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF78350F))))),
        ]),
      );
}
