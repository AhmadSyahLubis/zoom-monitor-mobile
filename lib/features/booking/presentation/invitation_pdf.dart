import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/invitation_data.dart';

const _contactName = 'Sdr. Julfan Torang Pandopotan Malau, SAP';
const _contactPhone = '087768670770';
const _months = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];
const _weekdays = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

Future<Uint8List> buildInvitationPdf(InvitationData data) async {
  if (data.topic.length > 220) {
    throw const InvitationDataException(
        'Topik terlalu panjang untuk satu halaman undangan.');
  }

  final regularData =
      await rootBundle.load('assets/fonts/InterInvitation-Regular.ttf');
  final boldData =
      await rootBundle.load('assets/fonts/InterInvitation-Bold.ttf');
  final provinceData =
      await rootBundle.load('assets/images/sumatera-utara.png');
  final collaborationData =
      await rootBundle.load('assets/images/kolaborasi-sumut-berkah.png');
  final regular = pw.Font.ttf(regularData);
  final bold = pw.Font.ttf(boldData);
  final provinceLogo = pw.MemoryImage(provinceData.buffer.asUint8List());
  final collaborationLogo =
      pw.MemoryImage(collaborationData.buffer.asUint8List());
  final navy = PdfColor.fromHex('#102E59');
  final blue = PdfColor.fromHex('#173D72');
  final cyan = PdfColor.fromHex('#69D6E8');
  final ink = PdfColor.fromHex('#142E4E');
  final muted = PdfColor.fromHex('#465B73');
  final pale = PdfColor.fromHex('#EDF3FA');
  final startWib = data.startTime.toUtc().add(const Duration(hours: 7));
  final endWib = data.endTime.toUtc().add(const Duration(hours: 7));
  String two(int value) => value.toString().padLeft(2, '0');
  String date(DateTime value) =>
      '${_weekdays[value.weekday - 1]}, ${value.day} ${_months[value.month - 1]} ${value.year}';
  final time = '${two(startWib.hour)}:${two(startWib.minute)} - '
      '${two(endWib.hour)}:${two(endWib.minute)} WIB';
  final endDate =
      date(endWib) == date(startWib) ? null : 'Berakhir pada ${date(endWib)}';
  final id = data.meetingId.toString().replaceFirstMapped(
      RegExp(r'^(\d{3})(\d{3,4})(\d{4})$'),
      (match) => '${match[1]} ${match[2]} ${match[3]}');

  pw.TextStyle style(double size, {bool strong = false, PdfColor? color}) =>
      pw.TextStyle(
        font: strong ? bold : regular,
        fontSize: size,
        color: color ?? ink,
      );

  final document = pw.Document(
    title: 'Undangan rapat - ${data.topic}',
    author: 'Pemerintah Provinsi Sumatera Utara',
    subject: 'Undangan rapat daring',
    creator: 'Sistem Informasi Pengelolaan Virtual Meeting',
  );
  document.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    build: (_) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          height: 102,
          color: navy,
          padding: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 19),
          child: pw.Row(
            children: [
              pw.Image(provinceLogo, width: 48, height: 64),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PEMERINTAH PROVINSI',
                        style: style(10, color: PdfColors.white)),
                    pw.SizedBox(height: 5),
                    pw.Text('SUMATERA UTARA',
                        style: style(17, strong: true, color: PdfColors.white)),
                  ],
                ),
              ),
              pw.Image(collaborationLogo, width: 125, height: 42),
            ],
          ),
        ),
        pw.Container(
          height: 150,
          color: blue,
          padding: const pw.EdgeInsets.fromLTRB(44, 26, 44, 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('UNDANGAN RAPAT DARING',
                  style: style(11, strong: true, color: cyan)),
              pw.SizedBox(height: 13),
              pw.Text(data.topic,
                  style: style(
                      data.topic.length > 140
                          ? 16
                          : data.topic.length > 80
                              ? 20
                              : 27,
                      strong: true,
                      color: PdfColors.white)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(44, 29, 44, 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 105,
                      height: 110,
                      decoration: pw.BoxDecoration(
                        color: navy,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      padding: const pw.EdgeInsets.all(14),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(_weekdays[startWib.weekday - 1].toUpperCase(),
                              style: style(10, strong: true, color: cyan)),
                          pw.Text('${startWib.day}',
                              style: style(39,
                                  strong: true, color: PdfColors.white)),
                          pw.Text(
                              '${_months[startWib.month - 1]} ${startWib.year}',
                              style: style(10, color: PdfColors.white)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Container(
                        height: 110,
                        decoration: pw.BoxDecoration(
                          color: pale,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        padding: const pw.EdgeInsets.all(16),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text('WAKTU RAPAT',
                                style: style(10, strong: true, color: muted)),
                            pw.SizedBox(height: 7),
                            pw.Text(date(startWib),
                                style: style(12, strong: true)),
                            pw.SizedBox(height: 7),
                            pw.Text(time, style: style(18, strong: true)),
                            if (endDate != null) ...[
                              pw.SizedBox(height: 4),
                              pw.Text(endDate, style: style(9)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Container(
                  height: 245,
                  decoration: pw.BoxDecoration(
                    color: pale,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Zoom Meeting',
                                style: style(20, strong: true)),
                            pw.SizedBox(height: 16),
                            pw.Text('MEETING ID',
                                style: style(9, strong: true, color: muted)),
                            pw.SizedBox(height: 4),
                            pw.Text(id, style: style(22, strong: true)),
                            pw.SizedBox(height: 13),
                            pw.Text('PASSCODE',
                                style: style(9, strong: true, color: muted)),
                            pw.SizedBox(height: 4),
                            pw.Text(
                                data.passcode.isEmpty
                                    ? 'Tidak tersedia'
                                    : data.passcode,
                                style: style(15, strong: true)),
                            pw.Spacer(),
                            pw.UrlLink(
                              destination: data.joinUrl,
                              child: pw.Container(
                                decoration: pw.BoxDecoration(
                                  color: navy,
                                  borderRadius: pw.BorderRadius.circular(5),
                                ),
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: pw.Text('Buka Zoom Meeting',
                                    style: style(11,
                                        strong: true, color: PdfColors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 14),
                      pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Container(
                            color: PdfColors.white,
                            padding: const pw.EdgeInsets.all(7),
                            child: pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: data.joinUrl,
                              width: 135,
                              height: 135,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text('Pindai untuk bergabung',
                              style: style(9, color: muted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.Container(
          height: 105,
          color: navy,
          padding: const pw.EdgeInsets.fromLTRB(44, 14, 44, 14),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PIC ZOOM MEETING',
                  style: style(10, strong: true, color: cyan)),
              pw.SizedBox(height: 4),
              pw.UrlLink(
                destination: 'tel:$_contactPhone',
                child: pw.Text(_contactPhone,
                    style: style(21, strong: true, color: PdfColors.white)),
              ),
              pw.SizedBox(height: 4),
              pw.Text(_contactName, style: style(10, color: PdfColors.white)),
            ],
          ),
        ),
      ],
    ),
  ));
  return document.save();
}
