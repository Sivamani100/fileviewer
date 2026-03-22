import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? animationPath;
  final double? width;
  final double? height;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.animationPath,
    this.width,
    this.height,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (animationPath != null)
          Expanded(
            child: Lottie.asset(
              animationPath!,
              width: width ?? 200,
              height: height ?? 200,
              fit: BoxFit.contain,
            ),
          ),
        const SizedBox(height: 32),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
        if (onAction != null) ...[
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onAction!,
            child: const Text('Action'),
          ),
        ],
      ],
    );

    return width != null && height != null
        ? SizedBox(width: width!, height: height!, child: child)
        : Expanded(child: child);
  }
}
