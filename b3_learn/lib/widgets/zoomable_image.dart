import 'package:flutter/material.dart';

class ZoomableImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final double width;

  const ZoomableImage({
    super.key,
    required this.imageUrl,
    this.height = 150,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(10),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
      child: Image.network(
        imageUrl,
        height: height,
        width: width,
        fit: BoxFit.contain, // Fit in the space without cropping
        errorBuilder: (context, error, stackTrace) => const Text('Erreur d\'image'),
      ),
    );
  }
}
