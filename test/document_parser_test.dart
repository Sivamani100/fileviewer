import 'package:flutter_test/flutter_test.dart';
import 'package:filevault/features/viewers/document/parsers/pptx_parser.dart';
import 'package:filevault/features/viewers/document/parsers/xlsx_parser.dart';
import 'package:filevault/features/viewers/document/models/pptx_models.dart';
import 'package:filevault/features/viewers/document/models/xlsx_models.dart';

void main() {
  group('PPTX Parser Tests', () {
    test('Parser class exists and has parse method', () {
      // Verify the parser class and methods exist
      expect(PptxParser.parse, isNotNull);
    });

    test('PptxDocument model can be created', () {
      final doc = PptxDocument(
        slides: [],
        properties: PptxPresentationProperties(
          slideWidth: 9144000,
          slideHeight: 6858000,
          title: 'Test Presentation',
        ),
      );
      expect(doc.slides, isEmpty);
      expect(doc.properties.title, 'Test Presentation');
    });

    test('PptxSlide model can be created', () {
      final slide = PptxSlide(
        shapes: [],
        backgroundColor: null,
        slideNumber: 1,
      );
      expect(slide.shapes, isEmpty);
      expect(slide.slideNumber, 1);
    });
  });

  group('XLSX Parser Tests', () {
    test('Parser class exists and has parse method', () {
      // Verify the parser class and methods exist
      expect(XlsxParser.parse, isNotNull);
    });

    test('XlsxDocument model can be created', () {
      final doc = XlsxDocument(
        sheets: [],
        properties: XlsxProperties(
          title: 'Test Workbook',
          creator: 'Test Creator',
          created: null,
          modified: null,
        ),
      );
      expect(doc.sheets, isEmpty);
      expect(doc.properties.title, 'Test Workbook');
    });

    test('XlsxSheet model can be created', () {
      final sheet = XlsxSheet(
        name: 'Sheet1',
        rows: [],
        columns: [],
        mergedCells: [],
        cellStyles: {},
      );
      expect(sheet.name, 'Sheet1');
      expect(sheet.rows, isEmpty);
      expect(sheet.columns, isEmpty);
      expect(sheet.mergedCells, isEmpty);
    });

    test('XlsxCell model can be created', () {
      final cell = XlsxCell(
        address: 'A1',
        row: 1,
        column: 1,
        value: XlsxCellValue(stringValue: 'Test Value'),
      );
      expect(cell.address, 'A1');
      expect(cell.row, 1);
      expect(cell.column, 1);
      expect(cell.value.displayValue, 'Test Value');
    });
  });
}