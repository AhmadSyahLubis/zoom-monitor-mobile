import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/ui_feedback.dart';
import '../../data/booking_repository.dart';
import '../../data/models/invitation_data.dart';
import '../controllers/booking_controller.dart';
import '../invitation_pdf.dart';

class InvitationPdfButton extends ConsumerStatefulWidget {
  const InvitationPdfButton({
    super.key,
    required this.accountId,
    required this.meetingId,
    this.occurrenceId,
    this.requestedStart,
  });

  final int accountId;
  final int meetingId;
  final String? occurrenceId;
  final DateTime? requestedStart;

  @override
  ConsumerState<InvitationPdfButton> createState() =>
      _InvitationPdfButtonState();
}

class _InvitationPdfButtonState extends ConsumerState<InvitationPdfButton> {
  bool _busy = false;

  Future<void> _prepare() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final detail = await ref.read(bookingRepositoryProvider).getMeetingDetail(
            widget.accountId,
            widget.meetingId,
          );
      final invitation = InvitationData.fromDetail(
        detail,
        meetingId: widget.meetingId,
        occurrenceId: widget.occurrenceId,
        requestedStart: widget.requestedStart,
      );
      final bytes = await buildInvitationPdf(invitation);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${invitation.filename}');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Undangan rapat: ${invitation.topic}',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (error) {
      if (!mounted) return;
      final message = switch (error) {
        InvitationDataException(:final message) => message,
        BookingFailure(:final message) => message,
        _ => 'PDF undangan belum dapat dibuat. Coba lagi.',
      };
      UiFeedback.showError(context, message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _busy ? null : _prepare,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: Text(_busy ? 'Menyiapkan PDF...' : 'Simpan PDF undangan'),
        ),
      );
}
