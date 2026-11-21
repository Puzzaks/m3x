// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'elements.dart';

/// Card displaying Pro/Supporter subscription tiers with badge, price subtitle,
/// feature checklist, and Material 3 CTA button.
class SubscriptionTierCard extends StatelessWidget {
  final String title;
  final String? price;
  final String? period;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final List<String> features;
  final String ctaText;
  final VoidCallback? onCtaPressed;
  final bool isFeatured;
  final IconData? icon;
  final Widget? customCta;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  const SubscriptionTierCard({
    super.key,
    required this.title,
    this.price,
    this.period,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    this.features = const [],
    this.ctaText = 'Upgrade Now',
    this.onCtaPressed,
    this.isFeatured = false,
    this.icon,
    this.customCta,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final radius = borderRadius ?? BorderRadius.circular(20);

    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isFeatured ? scheme.surfaceContainerHigh : scheme.surfaceContainer,
      surfaceTintColor: isFeatured ? scheme.primary : null,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: isFeatured
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Title, optional Icon, and optional Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 24, color: scheme.primary),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badgeText != null && badgeText!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor ??
                          (isFeatured
                              ? scheme.primary
                              : scheme.primaryContainer),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: badgeTextColor ??
                            (isFeatured
                                ? scheme.onPrimary
                                : scheme.onPrimaryContainer),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            if (price != null && price!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price!,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                  if (period != null && period!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      period!,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            if (features.isNotEmpty) ...[
              const SizedBox(height: 14),
              Divider(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                height: 1,
              ),
              const SizedBox(height: 14),
              ...features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 16),
            if (customCta != null)
              customCta!
            else
              SizedBox(
                width: double.infinity,
                child: isFeatured
                    ? FilledButton(
                        onPressed: onCtaPressed,
                        child: Text(ctaText),
                      )
                    : FilledButton.tonal(
                        onPressed: onCtaPressed,
                        child: Text(ctaText),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Clean Material 3 ad container matching Puzzak's 20px card radius standard
/// with a subtle "Ad" badge and dedicated slot for banner, native, or placeholder ads.
class AdPlaceholderCard extends StatelessWidget {
  final Widget? child;
  final double? height;
  final double? width;
  final String badgeLabel;
  final String placeholderText;
  final IconData placeholderIcon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  const AdPlaceholderCard({
    super.key,
    this.child,
    this.height = 90.0,
    this.width,
    this.badgeLabel = 'Ad',
    this.placeholderText = 'Advertisement',
    this.placeholderIcon = Icons.ad_units_rounded,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius,
  });

  /// Factory helper for creating an in-card ad row ready for [CardGroup] / `context.cards.cardGroup([ ... ])`.
  static Widget inCardGroup({
    Widget? child,
    bool isLoaded = true,
    double bannerWidth = 320.0,
    double bannerHeight = 50.0,
    BoxFit fit = BoxFit.contain,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    VoidCallback? onTap,
    String? badgeLabel,
    String? title,
    String? subtitle,
    IconData? icon,
    double? minHeight,
  }) {
    return CardContents.ad(
      child: child,
      isLoaded: isLoaded,
      bannerWidth: bannerWidth,
      bannerHeight: bannerHeight,
      fit: fit,
      padding: padding,
      action: onTap,
      badgeLabel: badgeLabel,
      title: title,
      subtitle: subtitle,
      icon: icon,
      minHeight: minHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(20);

    final Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Text(
        badgeLabel.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );

    final Widget content = child ??
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                placeholderIcon,
                size: 26,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 6),
              Text(
                placeholderText,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );

    final Widget body = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: radius,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Center(child: content),
          Positioned(
            top: 8,
            right: 8,
            child: badge,
          ),
        ],
      ),
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: body,
            )
          : body,
    );
  }
}
