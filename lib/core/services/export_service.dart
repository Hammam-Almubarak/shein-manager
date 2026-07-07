import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/order.dart';

/// خدمة تصدير البيانات إلى Excel و PDF
class ExportService {
  // ---- تصدير Excel ----

  /// يُنشئ ملف Excel يحتوي كل الطلبات (ورقة) + تفاصيل كل طلب (ورقة منفصلة)
  static Future<void> exportToExcel(List<Order> orders) async {
    final excel = xl.Excel.createExcel();

    // ---- ورقة ملخص الطلبات ----
    final summarySheet = excel['ملخص الطلبات'];
    excel.delete('Sheet1'); // حذف الورقة الافتراضية

    // رؤوس الأعمدة
    final headers = [
      'رقم الطلب', 'العميل', 'الهاتف', 'الحالة',
      'تاريخ الطلب', 'تاريخ وصول متوقع', 'عدد المنتجات',
      'إجمالي الشراء (\$)', 'إجمالي البيع (\$)', 'إجمالي الربح (\$)',
      'ملاحظات',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = summarySheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = xl.TextCellValue(headers[i]);
      cell.cellStyle = xl.CellStyle(
        bold: true,
        backgroundColorHex: xl.ExcelColor.fromHexString('#E8438A'),
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    // بيانات الطلبات
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');
    for (int i = 0; i < orders.length; i++) {
      final o = orders[i];
      final row = i + 1;
      final values = [
        o.orderNumber,
        o.customer.fullName,
        o.customer.phoneNumber,
        o.status.labelAr,
        dateFormat.format(o.orderDate),
        o.expectedArrivalDate != null
            ? dateFormat.format(o.expectedArrivalDate!)
            : '',
        '${o.items.length}',
        o.purchaseTotal.toStringAsFixed(2),
        o.sellingTotal.toStringAsFixed(2),
        o.profitTotal.toStringAsFixed(2),
        o.notes ?? '',
      ];

      for (int j = 0; j < values.length; j++) {
        summarySheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: row))
            .value = xl.TextCellValue(values[j]);
      }
    }

    // ---- ورقة تفاصيل المنتجات ----
    final itemsSheet = excel['تفاصيل المنتجات'];
    final itemHeaders = [
      'رقم الطلب', 'العميل', 'معرّف SHEIN', 'اسم المنتج',
      'اللون', 'المقاس', 'الكمية',
      'سعر الشراء (\$)', 'سعر البيع (\$)',
      'مجموع الشراء (\$)', 'مجموع البيع (\$)', 'الربح (\$)',
    ];

    for (int i = 0; i < itemHeaders.length; i++) {
      final cell = itemsSheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = xl.TextCellValue(itemHeaders[i]);
      cell.cellStyle = xl.CellStyle(
        bold: true,
        backgroundColorHex: xl.ExcelColor.fromHexString('#2D3142'),
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    int itemRow = 1;
    for (final o in orders) {
      for (final item in o.items) {
        final values = [
          o.orderNumber,
          o.customer.fullName,
          item.product.sheinProductId,
          item.product.title,
          item.product.color ?? '',
          item.product.size ?? '',
          '${item.quantity}',
          item.purchasePrice.toStringAsFixed(2),
          item.sellingPrice.toStringAsFixed(2),
          item.purchaseSubtotal.toStringAsFixed(2),
          item.sellingSubtotal.toStringAsFixed(2),
          item.profitSubtotal.toStringAsFixed(2),
        ];
        for (int j = 0; j < values.length; j++) {
          itemsSheet
              .cell(xl.CellIndex.indexByColumnRow(
                  columnIndex: j, rowIndex: itemRow))
              .value = xl.TextCellValue(values[j]);
        }
        itemRow++;
      }
    }

    // حفظ الملف
    final bytes = excel.save();
    if (bytes == null) throw StateError('فشل إنشاء ملف Excel');

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final fileName = 'shein_orders_$timestamp.xlsx';
    final filePath = p.join(tempDir.path, fileName);
    await File(filePath).writeAsBytes(bytes);

    await Share.shareXFiles(
      [
        XFile(
          filePath,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      subject: 'تصدير طلبات SHEIN - $timestamp',
    );
  }

  // ---- تصدير PDF ----

  /// يُنشئ تقرير PDF احترافي لكل الطلبات
  static Future<void> exportToPdf(List<Order> orders) async {
    final doc = pw.Document(rtl: true);
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');
    final font = await PdfGoogleFonts.tajawalRegular();
    final fontBold = await PdfGoogleFonts.tajawalBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'تقرير الطلبات - إدارة طلبات SHEIN',
                style:
                    pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.pink700),
              ),
              pw.Text(
                dateFormat.format(DateTime.now()),
                style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey),
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
          ),
        ),
        build: (ctx) => [
          pw.SizedBox(height: 8),
          // ملخص إجمالي
          _buildPdfSummary(orders, font, fontBold),
          pw.SizedBox(height: 16),
          // جدول الطلبات
          _buildOrdersTable(orders, dateFormat, font, fontBold),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'shein_orders_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildPdfSummary(
      List<Order> orders, pw.Font font, pw.Font fontBold) {
    final totalProfit =
        orders.fold(0.0, (s, o) => s + o.profitTotal);
    final totalSales =
        orders.fold(0.0, (s, o) => s + o.sellingTotal);
    final totalPurchase =
        orders.fold(0.0, (s, o) => s + o.purchaseTotal);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.pink50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _pdfStat('إجمالي الطلبات', '${orders.length}', font, fontBold, PdfColors.indigo),
          _pdfStat('إجمالي المشتريات', '\$${totalPurchase.toStringAsFixed(2)}', font, fontBold, PdfColors.orange700),
          _pdfStat('إجمالي المبيعات', '\$${totalSales.toStringAsFixed(2)}', font, fontBold, PdfColors.blue700),
          _pdfStat('إجمالي الأرباح', '\$${totalProfit.toStringAsFixed(2)}', font, fontBold, PdfColors.teal700),
        ],
      ),
    );
  }

  static pw.Widget _pdfStat(
      String label, String value, pw.Font font, pw.Font fontBold, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(
                font: fontBold, fontSize: 14, color: color)),
        pw.SizedBox(height: 2),
        pw.Text(label,
            style:
                pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _buildOrdersTable(
      List<Order> orders,
      DateFormat dateFormat,
      pw.Font font,
      pw.Font fontBold) {
    return pw.TableHelper.fromTextArray(
      headers: [
        'رقم الطلب', 'العميل', 'الحالة', 'التاريخ',
        'الشراء \$', 'البيع \$', 'الربح \$',
      ],
      data: orders.map((o) => [
            o.orderNumber,
            o.customer.fullName,
            o.status.labelAr,
            dateFormat.format(o.orderDate),
            o.purchaseTotal.toStringAsFixed(2),
            o.sellingTotal.toStringAsFixed(2),
            o.profitTotal.toStringAsFixed(2),
          ]).toList(),
      headerStyle:
          pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.pink700),
      cellStyle: pw.TextStyle(font: font, fontSize: 9),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(70),
        1: const pw.FixedColumnWidth(80),
        2: const pw.FixedColumnWidth(55),
        3: const pw.FixedColumnWidth(60),
        4: const pw.FixedColumnWidth(55),
        5: const pw.FixedColumnWidth(55),
        6: const pw.FixedColumnWidth(55),
      },
    );
  }
}
