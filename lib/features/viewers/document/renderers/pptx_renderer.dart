import 'package:flutter/material.dart';
import '../models/pptx_models.dart';

/// Renderer for PPTX (PowerPoint) presentations
class PptxRenderer extends StatefulWidget {
  final PptxDocument document;
  final double textScaleFactor;

  const PptxRenderer({
    Key? key,
    required this.document,
    this.textScaleFactor = 1.0,
  }) : super(key: key);

  @override
  State<PptxRenderer> createState() => _PptxRendererState();
}

class _PptxRendererState extends State<PptxRenderer> {
  late PageController _pageController;
  int _currentSlide = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final slideAspectRatio = widget.document.properties.slideWidth /
        widget.document.properties.slideHeight;

    // Calculate slide display size to fit screen while maintaining aspect ratio
    final displayWidth = screenSize.width - 32; // Account for padding
    final displayHeight = displayWidth / slideAspectRatio;

    return Column(
      children: [
        // Slide navigation header
        _buildNavigationHeader(),

        // Slide viewer
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: AspectRatio(
              aspectRatio: slideAspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentSlide = page;
                    });
                  },
                  itemCount: widget.document.slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlide(widget.document.slides[index], displayWidth, displayHeight);
                  },
                ),
              ),
            ),
          ),
        ),

        // Slide thumbnails (optional)
        _buildThumbnailStrip(displayWidth / 6), // Small thumbnails
      ],
    );
  }

  Widget _buildNavigationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Text(
            widget.document.properties.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${_currentSlide + 1} / ${widget.document.slides.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _currentSlide > 0
                ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: _currentSlide < widget.document.slides.length - 1
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(PptxSlide slide, double displayWidth, double displayHeight) {
    // Calculate scale factor from EMU coordinates to display pixels
    final scaleX = displayWidth / widget.document.properties.slideWidth;
    final scaleY = displayHeight / widget.document.properties.slideHeight;

    return Container(
      width: displayWidth,
      height: displayHeight,
      color: slide.backgroundColor ?? Colors.white,
      child: Stack(
        children: slide.shapes.map((shape) {
          return Positioned(
            left: shape.bounds.left * scaleX,
            top: shape.bounds.top * scaleY,
            width: shape.bounds.width * scaleX,
            height: shape.bounds.height * scaleY,
            child: _buildShape(shape),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShape(PptxShape shape) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: switch (shape.type) {
        PptxShapeType.textBox => _buildTextBox(shape),
        PptxShapeType.picture => _buildPicture(shape),
        PptxShapeType.rectangle => _buildRectangle(shape),
        PptxShapeType.ellipse => _buildEllipse(shape),
        PptxShapeType.line => _buildLine(shape),
        PptxShapeType.table => _buildTable(shape),
      },
    );
  }

  Widget _buildTable(PptxShape shape) {
    final tableContent = shape.content.tableContent;
    if (tableContent == null || tableContent.rows.isEmpty) return Container();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
          children: tableContent.rows.map((row) {
            return TableRow(
              children: row.cells.map((cell) {
                return Container(
                  padding: const EdgeInsets.all(4),
                  color: cell.backgroundColor,
                  child: Text(
                    cell.content.paragraphs.isEmpty
                        ? ''
                        : cell.content.paragraphs.first.runs
                            .map((r) => r.text)
                            .join(),
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTextBox(PptxShape shape) {
    final textContent = shape.content.textContent;
    if (textContent == null || textContent.paragraphs.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: shape.fillColor?.withValues(alpha: 0.1),
          border: shape.style?.lineColor != null
              ? Border.all(color: shape.style!.lineColor!, width: 1)
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: shape.fillColor?.withValues(alpha: 0.1),
          border: shape.style?.lineColor != null
              ? Border.all(color: shape.style!.lineColor!, width: 1)
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: _getTextAlign(textContent),
          children: textContent.paragraphs.map((para) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: RichText(
                text: TextSpan(
                  children: para.runs.map((run) {
                    return TextSpan(
                      text: run.text,
                      style: TextStyle(
                        color: run.style.color ?? Colors.black,
                        fontSize: (run.style.fontSize ?? 14),
                        fontFamily: run.style.fontFamily ?? 'Arial',
                        fontWeight: run.style.bold == true ? FontWeight.bold : FontWeight.normal,
                        fontStyle: run.style.italic == true ? FontStyle.italic : FontStyle.normal,
                        decoration: run.style.underline == true ? TextDecoration.underline : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPicture(PptxShape shape) {
    final imageContent = shape.content.imageContent;
    if (imageContent == null) return Container();

    // For now, show a placeholder - in a real implementation,
    // you'd load the actual image from the extracted PPTX media
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey),
      ),
    );
  }

  Widget _buildRectangle(PptxShape shape) {
    return Container(
      decoration: BoxDecoration(
        color: shape.fillColor ?? Colors.transparent,
        border: shape.style?.lineColor != null
            ? Border.all(
                color: shape.style!.lineColor!,
                width: shape.style!.lineWidth ?? 1,
              )
            : null,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildEllipse(PptxShape shape) {
    return Container(
      decoration: BoxDecoration(
        color: shape.fillColor ?? Colors.transparent,
        border: shape.style?.lineColor != null
            ? Border.all(
                color: shape.style!.lineColor!,
                width: shape.style!.lineWidth ?? 1,
              )
            : null,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLine(PptxShape shape) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: shape.style?.lineColor ?? Colors.black,
            width: shape.style?.lineWidth ?? 1,
          ),
        ),
      ),
    );
  }

  CrossAxisAlignment _getTextAlign(PptxTextContent textContent) {
    // Use alignment from first paragraph
    final firstPara = textContent.paragraphs.firstOrNull;
    if (firstPara != null) {
      switch (firstPara.style.alignment) {
        case PptxTextAlignment.center:
          return CrossAxisAlignment.center;
        case PptxTextAlignment.right:
          return CrossAxisAlignment.end;
        case PptxTextAlignment.justified:
          return CrossAxisAlignment.start; // Flutter doesn't have justified
        default:
          return CrossAxisAlignment.start;
      }
    }
    return CrossAxisAlignment.start;
  }

  Widget _buildThumbnailStrip(double thumbnailHeight) {
    final aspectRatio = widget.document.properties.slideWidth /
        widget.document.properties.slideHeight;
    final thumbnailWidth = thumbnailHeight * aspectRatio;

    return Container(
      height: thumbnailHeight + 16,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.document.slides.length,
        itemBuilder: (context, index) {
          final slide = widget.document.slides[index];
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: thumbnailWidth,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: index == _currentSlide ? Colors.blue : Colors.grey.shade300,
                  width: index == _currentSlide ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Container(
                color: slide.backgroundColor ?? Colors.white,
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: index == _currentSlide ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}