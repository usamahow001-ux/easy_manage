import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/party.dart';
import '../models/transaction.dart';
import '../models/business_profile.dart';
import '../models/cash_entry.dart';

class PdfService {
  static Future<Uint8List> generatePartyStatement({
    required Party party,
    required List<KhataTransaction> transactions,
    required BusinessProfile business,
    required double runningBalance,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    // Sort transactions chronologically for statement
    final sortedTx = List<KhataTransaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    double currentBal = party.openingBalance;
    final rows = <List<String>>[];

    for (var tx in sortedTx) {
      if (party.type == PartyType.customer) {
        if (tx.type == TransactionType.youGave) {
          currentBal += tx.amount;
        } else {
          currentBal -= tx.amount;
        }
      } else {
        if (tx.type == TransactionType.youGot) {
          currentBal += tx.amount;
        } else {
          currentBal -= tx.amount;
        }
      }

      final gaveText = (tx.type == TransactionType.youGave)
          ? '${business.currencySymbol} ${tx.amount.toStringAsFixed(0)}'
          : '-';
      final gotText = (tx.type == TransactionType.youGot)
          ? '${business.currencySymbol} ${tx.amount.toStringAsFixed(0)}'
          : '-';

      rows.add([
        dateFormat.format(tx.date),
        tx.note.isNotEmpty ? tx.note : (tx.billNumber.isNotEmpty ? 'Bill #${tx.billNumber}' : 'Transaction'),
        gaveText,
        gotText,
        '${business.currencySymbol} ${currentBal.toStringAsFixed(0)}',
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(business, 'ACCOUNT STATEMENT / KHATA REPORT'),
        footer: (context) => _buildPdfFooter(context, business),
        build: (context) => [
          pw.SizedBox(height: 12),
          // Party Info Box
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      party.name,
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    if (party.phone.isNotEmpty)
                      pw.Text('Phone: ${party.phone}', style: const pw.TextStyle(fontSize: 10)),
                    if (party.address.isNotEmpty)
                      pw.Text('Address: ${party.address}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      'Account Type: ${party.type == PartyType.customer ? "Customer" : "Supplier"}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Net Outstanding Balance', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${business.currencySymbol} ${runningBalance.abs().toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: runningBalance > 0 ? PdfColors.red700 : PdfColors.green700,
                      ),
                    ),
                    pw.Text(
                      runningBalance > 0
                          ? (party.type == PartyType.customer ? "(You'll Get)" : "(You'll Give)")
                          : "(Settled/Advance)",
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // Table
          pw.TableHelper.fromTextArray(
            headers: [
              'Date & Time',
              'Details / Note',
              'You Gave (Debit)',
              'You Got (Credit)',
              'Balance'
            ],
            data: rows.isEmpty
                ? [
                    ['-', 'No transactions recorded', '-', '-', '${business.currencySymbol} 0']
                  ]
                : rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0D9488)),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          ),
          pw.SizedBox(height: 20),
          // Summary Footer
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 200,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Entries:', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('${transactions.length}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Divider(color: PdfColors.grey300, height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Closing Balance:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          '${business.currencySymbol} ${runningBalance.abs().toStringAsFixed(0)}',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0D9488)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateBusinessSummaryReport({
    required List<Party> parties,
    required Map<String, double> partyBalances,
    required BusinessProfile business,
    required double totalReceivable,
    required double totalPayable,
  }) async {
    final pdf = pw.Document();

    final customerRows = <List<String>>[];
    final supplierRows = <List<String>>[];

    for (var party in parties) {
      final bal = partyBalances[party.id] ?? 0.0;
      final row = [
        party.name,
        party.phone.isNotEmpty ? party.phone : '-',
        '${business.currencySymbol} ${bal.abs().toStringAsFixed(0)}',
        bal > 0 ? "Pending" : "Cleared",
      ];
      if (party.type == PartyType.customer) {
        customerRows.add(row);
      } else {
        supplierRows.add(row);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(business, 'OVERALL BUSINESS KHATA SUMMARY'),
        footer: (context) => _buildPdfFooter(context, business),
        build: (context) => [
          pw.SizedBox(height: 12),
          // Total Cards
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.green300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TOTAL RECEIVABLE (Lene Hain)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.green900)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${business.currencySymbol} ${totalReceivable.toStringAsFixed(0)}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.red300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TOTAL PAYABLE (Dene Hain)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.red900)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${business.currencySymbol} ${totalPayable.toStringAsFixed(0)}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Customers Ledger List (${customerRows.length})', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Customer Name', 'Phone', 'Balance', 'Status'],
            data: customerRows.isEmpty ? [['No customers found', '-', '-', '-']] : customerRows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0D9488)),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Suppliers Ledger List (${supplierRows.length})', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Supplier Name', 'Phone', 'Balance', 'Status'],
            data: supplierRows.isEmpty ? [['No suppliers found', '-', '-', '-']] : supplierRows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0F766E)),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateCashbookReport({
    required List<CashEntry> entries,
    required BusinessProfile business,
    required double totalCashIn,
    required double totalCashOut,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    final rows = entries.map((e) {
      return [
        dateFormat.format(e.date),
        e.category,
        e.note.isNotEmpty ? e.note : '-',
        (e.type == CashType.cashIn) ? '${business.currencySymbol} ${e.amount.toStringAsFixed(0)}' : '-',
        (e.type == CashType.cashOut) ? '${business.currencySymbol} ${e.amount.toStringAsFixed(0)}' : '-',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(business, 'CASHBOOK & EXPENSE STATEMENT'),
        footer: (context) => _buildPdfFooter(context, business),
        build: (context) => [
          pw.SizedBox(height: 12),
          // Cash Summary Cards
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.green300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TOTAL CASH IN (+)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.green900)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${business.currencySymbol} ${totalCashIn.toStringAsFixed(0)}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.red300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TOTAL CASH OUT (-)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.red900)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${business.currencySymbol} ${totalCashOut.toStringAsFixed(0)}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.blue300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('NET CASH BALANCE', style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue900)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${business.currencySymbol} ${(totalCashIn - totalCashOut).toStringAsFixed(0)}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Date & Time', 'Category', 'Remarks / Note', 'Cash In (+)', 'Cash Out (-)'],
            data: rows.isEmpty ? [['No cash entries found', '-', '-', '-', '-']] : rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0D9488)),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfHeader(BusinessProfile business, String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  business.businessName,
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0D9488)),
                ),
                if (business.ownerName.isNotEmpty)
                  pw.Text('Proprietor: ${business.ownerName}', style: const pw.TextStyle(fontSize: 10)),
                if (business.address.isNotEmpty)
                  pw.Text(business.address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                if (business.phone.isNotEmpty)
                  pw.Text('Tel: ${business.phone}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF0D9488),
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    'EasyManage Khata',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColor.fromInt(0xFF0D9488), thickness: 1.5),
        pw.Center(
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
          ),
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context, BusinessProfile business) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated via EasyManage App • 100% Secure Digital Ledger',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static Future<void> printOrSharePdf({
    required Uint8List pdfData,
    required String fileName,
  }) async {
    await Printing.sharePdf(bytes: pdfData, filename: '$fileName.pdf');
  }
}
