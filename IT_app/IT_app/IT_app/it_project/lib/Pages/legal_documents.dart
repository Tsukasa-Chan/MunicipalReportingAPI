import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Legal documents for FIX MY AREA, shown in Settings and offered as downloadable text files.
/// NOTE: have these reviewed/updated by the municipality's legal team before release.
const String privacyPolicyTitle = 'Privacy Policy';

const String privacyPolicyFileName = 'Fix_My_City_Privacy_Policy';

const String privacyPolicyText = '''
FIX MY AREA - PRIVACY POLICY

1. Introduction
FIX MY AREA helps you report local issues and follow their progress. This policy explains what information the app collects, how it is used and your choices.

2. Information we collect
- Account information: your full name, email address, password (stored securely), home area and optional profile picture.
- Report information: the description, category, location and photos you submit with an issue report, and the status updates on that report.
- Device permissions: with your permission, the app uses your location (to attach a place to a report) and your camera (to take photos for a report).

3. How we use your information
- To create and manage your account and sign you in.
- To submit, route and track your reports with municipal staff.
- To send account emails such as email verification and password resets.
- To support and improve the app.

4. Sharing
Reports, including their location and photos, are visible to municipal staff responsible for resolving them and may be visible to other residents in the app. We do not sell your personal information.

5. Storage and security
Your information is kept on the municipal reporting service. Login tokens are stored securely on your device. Keep your login details private.

6. Your choices
- You can turn location and camera permissions on or off in the Settings page or in your device settings.
- You can edit your profile details in the app.
- You can request deletion of your account and associated data through the Contact Us page.

7. Changes to this policy
We may update this policy from time to time. The latest version is always available in Settings > Privacy Policy.

8. Contact
For questions about this policy, use the Contact Us page in the app.
''';

const String termsTitle = 'Terms & Conditions';

const String termsFileName = 'Fix_My_City_Terms_and_Conditions';

const String termsText = '''
FIX MY AREA - TERMS AND CONDITIONS

1. Acceptance
By creating an account or using FIX MY AREA you agree to these terms. If you do not agree, please do not use the app.

2. Purpose of the app
FIX MY AREA lets residents report local issues (such as potholes, water leaks or street lights) to the municipality and follow their progress. Submitting a report does not guarantee a particular response time or outcome.

3. Your account
- You must provide accurate information when registering.
- You are responsible for keeping your login details private and for activity on your account.
- Tell us promptly if you believe your account has been accessed without permission.

4. Acceptable use
When using the app you agree not to:
- submit false, misleading, abusive or offensive reports or photos;
- submit reports on behalf of others without their consent;
- upload images or content that you do not have the right to share, or that show identifiable people without need;
- attempt to disrupt, overload or gain unauthorised access to the app or its systems;
- use the app for anything unlawful.

5. Emergencies
FIX MY AREA is not an emergency service. For emergencies or anything that puts life at risk, contact the relevant emergency services directly.

6. Your content
You keep ownership of the reports and photos you submit. You give the municipality permission to use, store and share them as needed to investigate, resolve and report on the issue, as described in the Privacy Policy.

7. Suspension
We may suspend or remove accounts or reports that break these terms.

8. Availability and liability
The app is provided "as is". We try to keep it available and accurate but do not guarantee uninterrupted service. To the extent permitted by law, the municipality is not liable for losses arising from use of, or inability to use, the app.

9. Changes to these terms
We may update these terms from time to time. Continued use of the app after a change means you accept the updated terms.

10. Contact
For questions about these terms, use the Contact Us page in the app.
''';

// Brand colours (same as the app theme).
final PdfColor _brand = PdfColor.fromInt(0xFFC94F1B);
final PdfColor _ink = PdfColor.fromInt(0xFF292929);
final PdfColor _muted = PdfColor.fromInt(0xFF6B6B6B);

// Location-pin icon used in the PDF header.
const String _pinSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path fill="#FFFFFF" fill-rule="evenodd" d="M12 2C8.1 2 5 5.1 5 9c0 5.2 7 13 7 13s7-7.8 7-13c0-3.9-3.1-7-7-7zm0 9.5c-1.4 0-2.5-1.1-2.5-2.5S10.6 6.5 12 6.5s2.5 1.1 2.5 2.5-1.1 2.5-2.5 2.5z"/>'
    '</svg>';

String _today() {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];
  final d = DateTime.now();
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// Builds a branded PDF from the plain-text legal documents above:
/// the first line of [text] is skipped (the PDF header shows [title] instead),
/// "1. Heading" lines = section headings, "- item" lines = bullets,
/// everything else = body text.
Future<Uint8List> buildLegalPdf(String title, String text) async {
  final doc = pw.Document(title: 'FIX MY AREA - $title', author: 'FIX MY AREA');
  final headingPattern = RegExp(r'^\d+\.\s');
  final bodyStyle = pw.TextStyle(fontSize: 10.5, color: _ink, lineSpacing: 3);
  final widgets = <pw.Widget>[];

  // Branded banner.
  widgets.add(
    pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: pw.BoxDecoration(
        color: _brand,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SvgImage(svg: _pinSvg, width: 32, height: 32),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FIX MY AREA',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Report local issues. Follow their progress.',
                style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.white),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // Document title and date.
  widgets.add(pw.SizedBox(height: 22));
  widgets.add(
    pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 26,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    ),
  );
  widgets.add(pw.SizedBox(height: 4));
  widgets.add(
    pw.Text(
      'Generated on ${_today()}',
      style: pw.TextStyle(fontSize: 9.5, color: _muted),
    ),
  );
  widgets.add(pw.SizedBox(height: 6));
  widgets.add(pw.Container(width: 48, height: 3, color: _brand));
  widgets.add(pw.SizedBox(height: 10));

  // Each section (heading + its content) is kept together so a heading is
  // never left alone at the bottom of a page.
  var section = <pw.Widget>[];
  void flushSection() {
    if (section.isEmpty) return;
    widgets.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: section,
      ),
    );
    section = <pw.Widget>[];
  }

  final lines = text.trim().split('\n').skip(1);
  for (final raw in lines) {
    final line = raw.trimRight();
    if (line.isEmpty) continue;

    if (headingPattern.hasMatch(line)) {
      flushSection();
      section.add(pw.SizedBox(height: 14));
      section.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.only(bottom: 3),
          margin: const pw.EdgeInsets.only(bottom: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _brand, width: 0.8),
            ),
          ),
          child: pw.Text(
            line,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _brand,
            ),
          ),
        ),
      );
    } else if (line.startsWith('- ')) {
      section.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 6, bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4.5),
                child: pw.Container(
                  width: 4,
                  height: 4,
                  decoration: pw.BoxDecoration(
                    color: _brand,
                    shape: pw.BoxShape.circle,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(child: pw.Text(line.substring(2), style: bodyStyle)),
            ],
          ),
        ),
      );
    } else {
      section.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(line, style: bodyStyle),
        ),
      );
    }
  }
  flushSection();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 44),
      build: (_) => widgets,
      footer: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'FIX MY AREA  |  $title',
              style: pw.TextStyle(fontSize: 8.5, color: _muted),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 8.5, color: _muted),
            ),
          ],
        ),
      ),
    ),
  );
  return doc.save();
}

Future<String?> downloadPdfFile(
    String fileName,
    String title,
    String text,
    ) async {
  final Uint8List bytes = await buildLegalPdf(title, text);
  return FileSaver.instance.saveAs(
    name: fileName,
    bytes: bytes,
    ext: 'pdf',
    mimeType: MimeType.pdf,
  );
}
