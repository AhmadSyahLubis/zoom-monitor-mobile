import 'package:flutter/material.dart';
import '../models/meeting_monitoring.dart';

class MonitoringLabels extends StatelessWidget {
  final MeetingMonitoring? monitoring;
  final bool stale;
  const MonitoringLabels({super.key, this.monitoring, this.stale = false});

  @override
  Widget build(BuildContext context) {
    if (stale) {
      return const Text('Status belum terverifikasi; menunggu pembaruan',
          style: TextStyle(fontSize: 12, color: Color(0xFF854D0E)));
    }
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final label in monitoring?.labels ?? <MonitoringLabel>[])
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFCD34D))),
          child: Text(label.text,
              style: const TextStyle(
                  fontSize: 12, height: 1.4, color: Color(0xFF78350F))),
        ),
    ]);
  }
}
