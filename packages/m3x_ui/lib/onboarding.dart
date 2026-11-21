// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'elements.dart';

/// Data model for a single slide in [OnboardingWizard].
class OnboardingSlideData {
  final IconData icon;
  final List<IconData>? icons;
  final String title;
  final String description;
  final Widget? customBody;

  const OnboardingSlideData({
    required this.icon,
    this.icons,
    required this.title,
    required this.description,
    this.customBody,
  });
}

/// Multi-step Material 3 onboarding wizard with a [PageView], animated pill dot
/// indicators (`24px` active vs `8px` inactive), Skip button, and Next /
/// Get Started [FilledButton].
///
/// Extracted from `PTK/lib/pages/intro.dart`.
class OnboardingWizard extends StatefulWidget {
  final List<OnboardingSlideData> slides;
  final VoidCallback onFinish;
  final String skipLabel;
  final String nextLabel;
  final String finishLabel;
  final ValueChanged<int>? onPageChanged;

  const OnboardingWizard({
    super.key,
    required this.slides,
    required this.onFinish,
    this.skipLabel = 'Skip',
    this.nextLabel = 'Next',
    this.finishLabel = 'Get Started',
    this.onPageChanged,
  });

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < widget.slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinish();
    }
  }

  void _skipToLast() {
    if (widget.slides.length > 1) {
      _pageController.animateToPage(
        widget.slides.length - 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final int totalPages = widget.slides.length;
    final bool isLastPage = _currentPage >= totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                itemCount: totalPages,
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  widget.onPageChanged?.call(i);
                },
                itemBuilder: (context, index) {
                  final slide = widget.slides[index];
                  return _OnboardingSlideView(slide: slide);
                },
              ),
            ),

            // Animated pill page indicator dots
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (i) {
                  final bool active = _currentPage == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                  );
                }),
              ),
            ),

            // Bottom navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  !isLastPage
                      ? TextButton(
                          onPressed: _skipToLast,
                          child: Text(widget.skipLabel),
                        )
                      : const SizedBox(width: 72),
                  !isLastPage
                      ? FilledButton(
                          onPressed: _nextPage,
                          child: Text(widget.nextLabel),
                        )
                      : FilledButton.icon(
                          onPressed: widget.onFinish,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(widget.finishLabel),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlideView extends StatelessWidget {
  final OnboardingSlideData slide;

  const _OnboardingSlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final icons = slide.icons;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icons != null && icons.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: icons
                      .map((ic) => Icon(ic, size: 72, color: scheme.primary))
                      .toList(),
                )
              else
                Icon(slide.icon, size: 72, color: scheme.primary),
              const SizedBox(height: 32),
              Text(
                slide.title,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                slide.description,
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (slide.customBody != null) ...[
                const SizedBox(height: 24),
                slide.customBody!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable Material 3 card with primary border highlight, `primaryContainer`
/// background tint when selected, leading icon, title/subtitle, and trailing
/// check circle.
///
/// Extracted from `PTK/lib/pages/intro.dart`.
class ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const ChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: selected ? 4 : 1,
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: selected ? scheme.onPrimaryContainer : null,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: selected
                              ? scheme.onPrimaryContainer.withValues(alpha: 0.8)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.check_circle_rounded,
                color: selected ? scheme.primary : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item model for [ChecklistGroupCard].
class ChecklistProposalItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const ChecklistProposalItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.icon = Icons.dns_rounded,
  });
}

/// Grouped checklist card with a section header and segmented Material 3
/// [CheckboxListTile] items for onboarding demo/proposal selection.
///
/// Extracted from `PTK/lib/pages/intro.dart`.
class ChecklistGroupCard extends StatelessWidget {
  final String header;
  final List<ChecklistProposalItem> items;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const ChecklistGroupCard({
    super.key,
    required this.header,
    required this.items,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cards = Cards(context: context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            header.toUpperCase(),
            style: textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        cards.cardGroup(
          items.map((item) {
            final bool checked = selectedIds.contains(item.id);
            return CheckboxListTile(
              value: checked,
              onChanged: (_) => onToggle(item.id),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: item.subtitle.isNotEmpty
                  ? Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              secondary: Icon(item.icon, color: scheme.primary),
            );
          }).toList(),
        ),
      ],
    );
  }
}
