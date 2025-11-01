import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Service pour générer des rapports PDF et Excel
class ReportService {
  /// Générer un rapport PDF
  Future<File> generatePDFReport({
    required String title,
    required Map<String, dynamic> data,
    String? fileName,
  }) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // En-tête
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Généré le ${DateTime.now().toString().split('.')[0]}',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Contenu
              _buildPDFContent(data),
            ];
          },
        ),
      );

      // Sauvegarder le PDF
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${fileName ?? 'rapport_${DateTime.now().millisecondsSinceEpoch}.pdf'}');
      await file.writeAsBytes(await pdf.save());
      
      return file;
    } catch (e) {
      print('Erreur génération PDF: $e');
      rethrow;
    }
  }

  /// Générer le contenu PDF
  pw.Widget _buildPDFContent(Map<String, dynamic> data) {
    final widgets = <pw.Widget>[];

    data.forEach((key, value) {
      if (value is Map) {
        widgets.add(pw.Text(
          key,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ));
        widgets.add(pw.SizedBox(height: 10));
        value.forEach((subKey, subValue) {
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20),
            child: pw.Text('$subKey: $subValue'),
          ));
        });
        widgets.add(pw.SizedBox(height: 15));
      } else if (value is List) {
        widgets.add(pw.Text(
          key,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ));
        widgets.add(pw.SizedBox(height: 10));
        for (final item in value) {
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20),
            child: pw.Text(item.toString()),
          ));
        }
        widgets.add(pw.SizedBox(height: 15));
      } else {
        widgets.add(pw.Text(
          '$key: $value',
          style: pw.TextStyle(fontSize: 12),
        ));
        widgets.add(pw.SizedBox(height: 10));
      }
    });

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: widgets);
  }

  /// Générer un rapport Excel
  Future<File> generateExcelReport({
    required String title,
    required List<Map<String, dynamic>> data,
    String? fileName,
  }) async {
    try {
      final excel = Excel.createExcel();
      
      // Supprimer la feuille par défaut
      excel.delete('Sheet1');
      
      // Créer une nouvelle feuille
      final sheet = excel[title];
      
      // En-têtes
      if (data.isNotEmpty) {
        final headers = data.first.keys.toList();
        for (int i = 0; i < headers.length; i++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
              TextCellValue(headers[i]);
        }
        
        // Données
        for (int row = 0; row < data.length; row++) {
          for (int col = 0; col < headers.length; col++) {
            final value = data[row][headers[col]];
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1)).value =
                TextCellValue(value?.toString() ?? '');
          }
        }
      }

      // Sauvegarder le fichier Excel
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${fileName ?? 'rapport_${DateTime.now().millisecondsSinceEpoch}.xlsx'}');
      final bytes = excel.save();
      await file.writeAsBytes(bytes!);
      
      return file;
    } catch (e) {
      print('Erreur génération Excel: $e');
      rethrow;
    }
  }

  /// Générer un rapport de statistiques PDF
  Future<File> generateStatsPDF({
    required Map<String, dynamic> stats,
    String? fileName,
  }) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Rapport de Statistiques HEALTHER',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Statistiques globales
              if (stats['global'] != null)
                pw.Text(
                  'Statistiques Globales',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              pw.SizedBox(height: 10),
              if (stats['global'] != null)
                _buildStatsSection(stats['global'] as Map<String, dynamic>),
              
              pw.SizedBox(height: 20),
              
              // Statistiques par région
              if (stats['parRegion'] != null)
                pw.Text(
                  'Statistiques par Région',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              pw.SizedBox(height: 10),
              if (stats['parRegion'] != null)
                _buildStatsTable(stats['parRegion'] as Map<String, dynamic>),
            ];
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${fileName ?? 'stats_${DateTime.now().millisecondsSinceEpoch}.pdf'}');
      await file.writeAsBytes(await pdf.save());
      
      return file;
    } catch (e) {
      print('Erreur génération rapport stats PDF: $e');
      rethrow;
    }
  }

  pw.Widget _buildStatsSection(Map<String, dynamic> stats) {
    final widgets = <pw.Widget>[];
    stats.forEach((key, value) {
      widgets.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(value.toString()),
          ],
        ),
      ));
    });
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: widgets);
  }

  pw.Widget _buildStatsTable(Map<String, dynamic> stats) {
    final widgets = <pw.Widget>[];
    stats.forEach((region, data) {
      widgets.add(pw.Container(
        padding: const pw.EdgeInsets.all(10),
        margin: const pw.EdgeInsets.only(bottom: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              region,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            if (data is Map)
              ...(data as Map<String, dynamic>).entries.map((e) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 10, bottom: 3),
                    child: pw.Text('${e.key}: ${e.value}'),
                  )),
          ],
        ),
      ));
    });
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: widgets);
  }

  /// Partager un rapport
  Future<void> shareReport(File reportFile, {String? subject}) async {
    try {
      await Share.shareXFiles(
        [XFile(reportFile.path)],
        subject: subject ?? 'Rapport HEALTHER',
      );
    } catch (e) {
      print('Erreur partage rapport: $e');
      rethrow;
    }
  }
}

