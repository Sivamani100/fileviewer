import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/pptx_models.dart';

/// Parser for PPTX files (PowerPoint presentations)
class PptxParser {
  static Future<PptxDocument> parse(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Extract presentation properties
    final presentationProps = await _parsePresentationProperties(archive);

    // Parse all slides
    final slides = await _parseSlides(archive);

    return PptxDocument(
      slides: slides,
      properties: presentationProps,
    );
  }

  static Future<PptxPresentationProperties> _parsePresentationProperties(Archive archive) async {
    final presentationFile = archive.findFile('ppt/presentation.xml');
    if (presentationFile == null) {
      throw Exception('Invalid PPTX: missing presentation.xml');
    }

    final xml = XmlDocument.parse(utf8.decode(presentationFile.content));
    final presentation = xml.findElements('p:presentation').first;

    // Get slide size from presentation properties
    final slideSize = presentation.findElements('p:sldSz').firstOrNull;
    final slideWidth = int.tryParse(slideSize?.getAttribute('cx') ?? '9144000') ?? 9144000; // 10 inches in EMU
    final slideHeight = int.tryParse(slideSize?.getAttribute('cy') ?? '6858000') ?? 6858000; // 7.5 inches in EMU

    // Get title from core properties
    final title = await _getTitle(archive);

    return PptxPresentationProperties(
      slideWidth: slideWidth,
      slideHeight: slideHeight,
      title: title,
    );
  }

  static Future<String> _getTitle(Archive archive) async {
    final coreFile = archive.findFile('docProps/core.xml');
    if (coreFile != null) {
      final xml = XmlDocument.parse(utf8.decode(coreFile.content));
      final titleElement = xml.findElements('dc:title').firstOrNull;
      if (titleElement != null) {
        return titleElement.text;
      }
    }
    return 'PowerPoint Presentation';
  }

  static Future<List<PptxSlide>> _parseSlides(Archive archive) async {
    final slides = <PptxSlide>[];

    // Find all slide files (slide1.xml, slide2.xml, etc.)
    final slideFiles = archive.files
        .where((file) => file.name.startsWith('ppt/slides/slide') && file.name.endsWith('.xml'))
        .toList();

    // Sort by slide number
    slideFiles.sort((a, b) {
      final aNum = _extractSlideNumber(a.name);
      final bNum = _extractSlideNumber(b.name);
      return aNum.compareTo(bNum);
    });

    for (final slideFile in slideFiles) {
      final slideNumber = _extractSlideNumber(slideFile.name);
      final slide = await _parseSlide(archive, slideFile, slideNumber);
      slides.add(slide);
    }

    return slides;
  }

  static int _extractSlideNumber(String fileName) {
    final match = RegExp(r'slide(\d+)\.xml$').firstMatch(fileName);
    return match != null ? int.parse(match.group(1)!) : 1;
  }

  static Future<PptxSlide> _parseSlide(Archive archive, ArchiveFile slideFile, int slideNumber) async {
    final xml = XmlDocument.parse(utf8.decode(slideFile.content));
    final slide = xml.findElements('p:sld').first;

    // Parse background color
    final backgroundColor = _parseBackgroundColor(slide);

    // Parse shapes
    final shapes = <PptxShape>[];
    final shapeElements = slide.findAllElements('p:sp');

    for (final shapeElement in shapeElements) {
      final shape = await _parseShape(archive, shapeElement);
      if (shape != null) {
        shapes.add(shape);
      }
    }

    // Parse pictures
    final pictureElements = slide.findAllElements('p:pic');
    for (final picElement in pictureElements) {
      final shape = await _parsePicture(archive, picElement);
      if (shape != null) {
        shapes.add(shape);
      }
    }

    // Extract title from first text shape
    String? title;
    for (final shape in shapes) {
      if (shape.type == PptxShapeType.textBox && shape.content.textContent != null) {
        final text = shape.content.textContent!.paragraphs
            .map((p) => p.runs.map((r) => r.text).join())
            .join('\n')
            .trim();
        if (text.isNotEmpty) {
          title = text;
          break;
        }
      }
    }

    return PptxSlide(
      slideNumber: slideNumber,
      shapes: shapes,
      backgroundColor: backgroundColor,
      title: title,
    );
  }

  static Color? _parseBackgroundColor(XmlElement slide) {
    final bg = slide.findElements('p:bg').firstOrNull;
    if (bg != null) {
      final solidFill = bg.findElements('a:solidFill').firstOrNull;
      if (solidFill != null) {
        return _parseColor(solidFill);
      }
    }
    return null; // Default white background
  }

  static Future<PptxShape?> _parseShape(Archive archive, XmlElement shapeElement) async {
    final spPr = shapeElement.findElements('p:spPr').firstOrNull;
    if (spPr == null) return null;

    final bounds = _parseTransform(spPr);
    if (bounds == null) return null;

    final shapeType = _determineShapeType(shapeElement);
    final content = await _parseShapeContent(archive, shapeElement, shapeType);
    final fillColor = _parseFillColor(spPr);

    return PptxShape(
      type: shapeType,
      bounds: bounds,
      content: content,
      fillColor: fillColor,
    );
  }

  static Future<PptxShape?> _parsePicture(Archive archive, XmlElement picElement) async {
    final spPr = picElement.findElements('p:spPr').firstOrNull;
    if (spPr == null) return null;

    final bounds = _parseTransform(spPr);
    if (bounds == null) return null;

    final content = await _parsePictureContent(archive, picElement);

    return PptxShape(
      type: PptxShapeType.picture,
      bounds: bounds,
      content: PptxShapeContent(imageContent: content),
    );
  }

  static Rect? _parseTransform(XmlElement spPr) {
    final xfrm = spPr.findElements('a:xfrm').firstOrNull;
    if (xfrm == null) return null;

    final off = xfrm.findElements('a:off').firstOrNull;
    final ext = xfrm.findElements('a:ext').firstOrNull;

    if (off == null || ext == null) return null;

    final x = int.tryParse(off.getAttribute('x') ?? '0') ?? 0;
    final y = int.tryParse(off.getAttribute('y') ?? '0') ?? 0;
    final width = int.tryParse(ext.getAttribute('cx') ?? '0') ?? 0;
    final height = int.tryParse(ext.getAttribute('cy') ?? '0') ?? 0;

    // Convert EMU to pixels (1 EMU = 1/914400 inch, assuming 96 DPI)
    const emuToPixel = 96.0 / 914400.0;
    return Rect.fromLTWH(
      x * emuToPixel,
      y * emuToPixel,
      width * emuToPixel,
      height * emuToPixel,
    );
  }

  static PptxShapeType _determineShapeType(XmlElement shapeElement) {
    final spPr = shapeElement.findElements('p:spPr').firstOrNull;
    if (spPr == null) return PptxShapeType.rectangle;

    final prstGeom = spPr.findElements('a:prstGeom').firstOrNull;
    if (prstGeom != null) {
      final prst = prstGeom.getAttribute('prst');
      switch (prst) {
        case 'rect':
          return PptxShapeType.rectangle;
        case 'ellipse':
          return PptxShapeType.ellipse;
        case 'line':
          return PptxShapeType.line;
      }
    }

    // Check if it has text content
    final txBody = shapeElement.findElements('p:txBody').firstOrNull;
    if (txBody != null) {
      return PptxShapeType.textBox;
    }

    return PptxShapeType.rectangle;
  }

  static Future<PptxShapeContent> _parseShapeContent(
    Archive archive,
    XmlElement shapeElement,
    PptxShapeType shapeType,
  ) async {
    switch (shapeType) {
      case PptxShapeType.textBox:
        final textContent = _parseTextContent(shapeElement);
        return PptxShapeContent(textContent: textContent);
      case PptxShapeType.picture:
        final imageContent = await _parsePictureContent(archive, shapeElement);
        return PptxShapeContent(imageContent: imageContent);
      default:
        return PptxShapeContent();
    }
  }

  static PptxTextContent _parseTextContent(XmlElement shapeElement) {
    final txBody = shapeElement.findElements('p:txBody').firstOrNull;
    if (txBody == null) return PptxTextContent(paragraphs: []);

    final paragraphs = <PptxParagraph>[];
    final pElements = txBody.findAllElements('a:p');

    for (final pElement in pElements) {
      final runs = <PptxTextRun>[];
      final rElements = pElement.findAllElements('a:r');

      for (final rElement in rElements) {
        final text = rElement.findElements('a:t').firstOrNull?.text ?? '';
        final style = _parseTextStyle(rElement);
        runs.add(PptxTextRun(text: text, style: style));
      }

      final paraStyle = _parseParagraphStyle(pElement);
      paragraphs.add(PptxParagraph(runs: runs, style: paraStyle));
    }

    return PptxTextContent(paragraphs: paragraphs);
  }

  static PptxTextStyle _parseTextStyle(XmlElement rElement) {
    final rPr = rElement.findElements('a:rPr').firstOrNull;
    if (rPr == null) return PptxTextStyle();

    final color = _parseColor(rPr);
    final fontSize = double.tryParse(rPr.getAttribute('sz') ?? '') ?? 18.0;
    final fontFamily = rPr.findElements('a:latin').firstOrNull?.getAttribute('typeface') ?? 'Arial';

    final bold = rPr.findElements('a:b').isNotEmpty;
    final italic = rPr.findElements('a:i').isNotEmpty;
    final underline = rPr.findElements('a:u').isNotEmpty;

    return PptxTextStyle(
      color: color,
      fontSize: fontSize / 100, // PPTX font size is in hundredths of points
      fontFamily: fontFamily,
      bold: bold,
      italic: italic,
      underline: underline,
    );
  }

  static PptxParagraphStyle _parseParagraphStyle(XmlElement pElement) {
    final pPr = pElement.findElements('a:pPr').firstOrNull;
    if (pPr == null) return PptxParagraphStyle();

    PptxTextAlignment? alignment;
    final algn = pPr.getAttribute('algn');
    switch (algn) {
      case 'l':
        alignment = PptxTextAlignment.left;
        break;
      case 'ctr':
        alignment = PptxTextAlignment.center;
        break;
      case 'r':
        alignment = PptxTextAlignment.right;
        break;
      case 'just':
        alignment = PptxTextAlignment.justified;
        break;
    }

    return PptxParagraphStyle(alignment: alignment);
  }

  static Future<PptxImageContent> _parsePictureContent(Archive archive, XmlElement picElement) async {
    final blip = picElement.findElements('p:blipFill').firstOrNull
        ?.findElements('a:blip').firstOrNull;

    if (blip == null) return PptxImageContent(imagePath: '');

    final embed = blip.getAttribute('embed');
    if (embed == null) return PptxImageContent(imagePath: '');

    // Find the image file in the archive
    final imageFile = archive.findFile('ppt/media/$embed');
    if (imageFile == null) return PptxImageContent(imagePath: '');

    // For now, return the embedded ID - in a real implementation,
    // you'd extract and cache the image
    return PptxImageContent(imagePath: embed);
  }

  static Color? _parseColor(XmlElement element) {
    final solidFill = element.findElements('a:solidFill').firstOrNull;
    if (solidFill == null) return null;

    final srgbClr = solidFill.findElements('a:srgbClr').firstOrNull;
    if (srgbClr != null) {
      final val = srgbClr.getAttribute('val');
      if (val != null && val.length == 6) {
        return Color(int.parse('FF$val', radix: 16));
      }
    }

    return null;
  }

  static Color? _parseFillColor(XmlElement spPr) {
    final solidFill = spPr.findElements('a:solidFill').firstOrNull;
    if (solidFill != null) {
      return _parseColor(solidFill);
    }
    return null;
  }
}