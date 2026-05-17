import 'package:flutter/material.dart';

extension BuildContextExtension on BuildContext {
  /// Builds a major heading title using context theme colors.
  Widget headTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.left,
    );
  }

  /// Builds a Divider with padding, respect the theme color scheme.
  Widget dividerSpace(double height) {
    final colorScheme = Theme.of(this).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height / 2),
      child: Divider(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5), 
        thickness: 1,
      ),
    );
  }

  /// Builds a secondary description title.
  Widget subHeadTitle(String title) {
    final colorScheme = Theme.of(this).colorScheme;
    return Text(
      title,
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
    );
  }

  /// Builds custom styled body or concept text.
  Widget contentText(String title, Color color) {
    return Text(
      title,
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 0.4,
      ),
    );
  }

  /// Builds a code syntax highlighting box matching the app theme.
  Widget contentSectionContainer(String code) {
    final colorScheme = Theme.of(this).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        ),
        child: Text(
          code,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12.5,
            color: colorScheme.primary, // dynamic primary color in light mode
            letterSpacing: 0.3,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  /// Builds a theory description container.
  Widget theoryContentText(String text) {
    final colorScheme = Theme.of(this).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSecondaryContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
