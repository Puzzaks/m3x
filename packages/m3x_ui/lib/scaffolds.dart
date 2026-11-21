import 'dart:math' as math;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'elements.dart';
import 'motion_blur.dart';

/// Material 3 adaptive window size classes for phones (`< 680dp`),
/// foldables/tablets (`680dp..960dp`), and large tablets/desktops (`>= 960dp`).
enum M3xWindowSizeClass {
  compact,
  medium,
  expanded;

  /// Resolves the [M3xWindowSizeClass] for a given logical [width].
  static M3xWindowSizeClass fromWidth(
    double width, {
    double mediumBreakpoint = 680.0,
    double expandedBreakpoint = 960.0,
  }) {
    if (width >= expandedBreakpoint) {
      return M3xWindowSizeClass.expanded;
    }
    if (width >= mediumBreakpoint) {
      return M3xWindowSizeClass.medium;
    }
    return M3xWindowSizeClass.compact;
  }

  /// Whether the layout is in single-pane compact mode.
  bool get isCompact => this == M3xWindowSizeClass.compact;

  /// Whether the layout has enough horizontal room for split / rail layouts.
  bool get isSplit => this != M3xWindowSizeClass.compact;

  /// Whether the layout is in wide tablet / desktop mode.
  bool get isExpanded => this == M3xWindowSizeClass.expanded;
}

/// Reusable animated content frame that constrains [child] to [maxWidth] and
/// smoothly interpolates horizontal margins across `compact`, `medium`, and
/// `expanded` [M3xWindowSizeClass] breakpoints.
///
/// Ideal for non-sliver pages (such as chat columns, composer bars, forms, or
/// custom scroll views) so every screen shares consistent responsive ergonomics
/// without physical screen dimension math.
class M3xAdaptiveContentFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? compactPadding;
  final EdgeInsets? mediumPadding;
  final EdgeInsets? expandedPadding;
  final double mediumBreakpoint;
  final double expandedBreakpoint;
  final Duration duration;
  final Curve curve;
  final AlignmentGeometry alignment;

  const M3xAdaptiveContentFrame({
    super.key,
    required this.child,
    this.maxWidth = 880.0,
    this.compactPadding,
    this.mediumPadding,
    this.expandedPadding,
    this.mediumBreakpoint = 680.0,
    this.expandedBreakpoint = 960.0,
    this.duration = const Duration(milliseconds: 260),
    this.curve = Curves.easeOutCubic,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final M3xWindowSizeClass sizeClass = M3xWindowSizeClass.fromWidth(
          width,
          mediumBreakpoint: mediumBreakpoint,
          expandedBreakpoint: expandedBreakpoint,
        );

        final EdgeInsets resolvedPadding = switch (sizeClass) {
          M3xWindowSizeClass.compact => compactPadding ?? EdgeInsets.zero,
          M3xWindowSizeClass.medium =>
            mediumPadding ?? const EdgeInsets.symmetric(horizontal: 16.0),
          M3xWindowSizeClass.expanded =>
            expandedPadding ?? const EdgeInsets.symmetric(horizontal: 28.0),
        };

        final bool hasBoundedHeight = constraints.hasBoundedHeight;
        final Widget constrainedChild = maxWidth.isFinite
            ? ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              )
            : child;

        return AnimatedPadding(
          duration: duration,
          curve: curve,
          padding: resolvedPadding,
          child: Align(
            alignment: alignment,
            heightFactor: hasBoundedHeight ? null : 1.0,
            child: constrainedChild,
          ),
        );
      },
    );
  }
}

/// Standard collapsible Material 3 page layout with a pinned [SliverAppBar.large].
///
/// Automatically adapts across Phone, Foldable, and Tablet/Desktop widths via
/// [maxContentWidth] (default `880.0`, pass `double.infinity` or `null` to opt
/// out), [adaptivePadding], [embedded] split-pane styling, and an optional
/// animated left [adaptiveSidebar].
class SliverPageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? slivers;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool? showBackButton;
  final VoidCallback? onBack;
  final double? maxContentWidth;
  final double bottomSpacing;
  final CrossAxisAlignment crossAxisAlignment;
  final bool adaptivePadding;
  final bool embedded;
  final Widget? adaptiveSidebar;
  final double sidebarBreakpoint;
  final double sidebarWidth;
  final Duration transitionDuration;
  final Curve transitionCurve;

  const SliverPageScaffold({
    super.key,
    required this.title,
    this.children = const [],
    this.slivers,
    this.actions,
    this.floatingActionButton,
    this.showBackButton,
    this.onBack,
    this.maxContentWidth = 880.0,
    this.bottomSpacing = 80,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.adaptivePadding = true,
    this.embedded = false,
    this.adaptiveSidebar,
    this.sidebarBreakpoint = 840.0,
    this.sidebarWidth = 272.0,
    this.transitionDuration = const Duration(milliseconds: 280),
    this.transitionCurve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.canPop(context);
    final bool displayBack = showBackButton ?? (embedded ? false : canPop);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    Widget bodyColumn = SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          ...children,
          if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
        ],
      ),
    );

    final double effectiveMaxWidth = maxContentWidth ?? double.infinity;
    if (adaptivePadding) {
      bodyColumn = M3xAdaptiveContentFrame(
        maxWidth: effectiveMaxWidth,
        duration: transitionDuration,
        curve: transitionCurve,
        child: bodyColumn,
      );
    } else if (effectiveMaxWidth.isFinite) {
      bodyColumn = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: bodyColumn,
        ),
      );
    }

    final Widget? leadingWidget = displayBack
        ? Padding(
            padding: const EdgeInsetsDirectional.only(start: 5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack ?? () => Navigator.maybePop(context),
            ),
          )
        : null;

    final Widget appBarSliver = embedded
        ? SliverAppBar(
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            pinned: true,
            toolbarHeight: 56,
            automaticallyImplyLeading: false,
            leading: leadingWidget,
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: actions,
          )
        : SliverAppBar.large(
            surfaceTintColor: Colors.transparent,
            backgroundColor: scheme.surface,
            scrolledUnderElevation: 0,
            pinned: true,
            automaticallyImplyLeading: false,
            leading: leadingWidget,
            title: Text(title),
            actions: actions,
          );

    final Widget scrollView = CustomScrollView(
      slivers: [
        appBarSliver,
        if (children.isNotEmpty || slivers == null)
          SliverToBoxAdapter(
            child: MotionBlurContainer(child: bodyColumn),
          ),
        if (slivers != null) ...slivers!,
      ],
    );

    final Widget scaffoldBody = adaptiveSidebar == null
        ? scrollView
        : LayoutBuilder(
            builder: (context, constraints) {
              final bool showSidebar =
                  constraints.maxWidth >= sidebarBreakpoint;
              final double clampedSidebarWidth = math.min(
                sidebarWidth,
                math.max(0.0, constraints.maxWidth * 0.42),
              );
              final double targetWidth =
                  showSidebar ? clampedSidebarWidth : 0.0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedContainer(
                    duration: transitionDuration,
                    curve: transitionCurve,
                    width: targetWidth,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(),
                    child: clampedSidebarWidth > 0
                        ? OverflowBox(
                            alignment: AlignmentDirectional.centerStart,
                            minWidth: clampedSidebarWidth,
                            maxWidth: clampedSidebarWidth,
                            child: SizedBox(
                              width: clampedSidebarWidth,
                              child: IgnorePointer(
                                ignoring: !showSidebar,
                                child: ExcludeSemantics(
                                  excluding: !showSidebar,
                                  child: ExcludeFocus(
                                    excluding: !showSidebar,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(child: adaptiveSidebar!),
                                        VerticalDivider(
                                          width: 1,
                                          thickness: 1,
                                          color: scheme.outlineVariant
                                              .withValues(alpha: 0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(child: scrollView),
                ],
              );
            },
          );

    return Scaffold(
      backgroundColor: embedded ? Colors.transparent : null,
      floatingActionButton: floatingActionButton,
      body: scaffoldBody,
    );
  }
}

/// Destination metadata for [AdaptiveNavScaffold].
class AdaptiveNavDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? badgeLabel;

  const AdaptiveNavDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.badgeLabel,
  });
}

/// Responsive navigation shell that smoothly animates between:
/// - **Compact** (`< breakpoint`, default `680dp`): mobile bottom [NavigationBar]
/// - **Medium** (`breakpoint..expandedBreakpoint`, default `680..960dp`):
///   compact floating pill [NavigationRail]
/// - **Expanded** (`>= expandedBreakpoint`, default `>= 960dp`):
///   extended floating pill [NavigationRail] (when [extendRailOnExpanded] is true)
///
/// Preserves a single unified [Scaffold] subtree across resizes so [body] state
/// and scroll positions remain intact, with an optional animated right-hand
/// [sidePanel].
class AdaptiveNavScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdaptiveNavDestination> destinations;
  final Widget body;
  final Widget? sidePanel;
  final double sidePanelWidth;
  final double breakpoint;
  final double expandedBreakpoint;
  final bool extendRailOnExpanded;
  final Duration transitionDuration;
  final Curve transitionCurve;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const AdaptiveNavScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.sidePanel,
    this.sidePanelWidth = 340,
    this.breakpoint = 680.0,
    this.expandedBreakpoint = 960.0,
    this.extendRailOnExpanded = true,
    this.transitionDuration = const Duration(milliseconds: 280),
    this.transitionCurve = Curves.easeOutCubic,
    this.appBar,
    this.floatingActionButton,
  });

  Widget _wrapBadge(
      BuildContext context, Widget iconWidget, String? badgeLabel) {
    if (badgeLabel == null || badgeLabel.isEmpty) {
      return iconWidget;
    }
    return Badge(
      backgroundColor: Theme.of(context).colorScheme.primary,
      label: Text(badgeLabel),
      child: iconWidget,
    );
  }

  Widget _buildFloatingRail(
    BuildContext context, {
    required bool extended,
    required double containerWidth,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double minExtendedWidth = math.max(140.0, containerWidth - 20.0);

    return Align(
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 8.0,
        ),
        child: IntrinsicHeight(
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: NavigationRail(
              backgroundColor: Colors.transparent,
              indicatorColor: scheme.primaryContainer,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              extended: extended,
              minWidth: 72,
              minExtendedWidth: minExtendedWidth,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: destinations.map((dest) {
                return NavigationRailDestination(
                  icon: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _wrapBadge(
                      context,
                      Icon(dest.icon),
                      dest.badgeLabel,
                    ),
                  ),
                  selectedIcon: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _wrapBadge(
                      context,
                      Icon(dest.selectedIcon ?? dest.icon),
                      dest.badgeLabel,
                    ),
                  ),
                  label: Text(
                    dest.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final M3xWindowSizeClass sizeClass = M3xWindowSizeClass.fromWidth(
          width,
          mediumBreakpoint: breakpoint,
          expandedBreakpoint: expandedBreakpoint,
        );
        final bool isCompact = sizeClass.isCompact;
        final bool isRailExtended =
            sizeClass.isExpanded && extendRailOnExpanded;
        final double openRailWidth = isRailExtended ? 212.0 : 104.0;
        final bool showSidePanel = !isCompact && sidePanel != null;
        final double maxSafeSidePanel =
            math.max(0.0, width - openRailWidth - 260.0);
        final double effectiveSidePanelWidth =
            math.min(sidePanelWidth, maxSafeSidePanel);

        return Scaffold(
          appBar: appBar,
          floatingActionButton: floatingActionButton,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Animated left NavigationRail (0 on compact, 104 on medium, 212 on expanded)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: isCompact ? 0.0 : 1.0),
                  duration: transitionDuration,
                  curve: transitionCurve,
                  builder: (context, visibilityFactor, _) {
                    if (visibilityFactor <= 0.001) {
                      return const SizedBox.shrink();
                    }
                    return AnimatedContainer(
                      duration: transitionDuration,
                      curve: transitionCurve,
                      width: (openRailWidth + 8.0) * visibilityFactor,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(),
                      child: OverflowBox(
                        alignment: AlignmentDirectional.centerStart,
                        minWidth: openRailWidth + 8.0,
                        maxWidth: openRailWidth + 8.0,
                        child: Opacity(
                          opacity: visibilityFactor.clamp(0.0, 1.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: openRailWidth,
                                child: _buildFloatingRail(
                                  context,
                                  extended: isRailExtended,
                                  containerWidth: openRailWidth,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Main content body (preserved across all breakpoints)
                Expanded(child: body),

                // Optional animated right sidePanel
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    end: (showSidePanel && effectiveSidePanelWidth > 0)
                        ? 1.0
                        : 0.0,
                  ),
                  duration: transitionDuration,
                  curve: transitionCurve,
                  builder: (context, panelFactor, _) {
                    if (panelFactor <= 0.001 ||
                        sidePanel == null ||
                        effectiveSidePanelWidth <= 0) {
                      return const SizedBox.shrink();
                    }
                    final double totalPanelWidth =
                        effectiveSidePanelWidth + 1.0;
                    return SizedBox(
                      width: totalPanelWidth * panelFactor,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: AlignmentDirectional.centerStart,
                          minWidth: totalPanelWidth,
                          maxWidth: totalPanelWidth,
                          child: Opacity(
                            opacity: panelFactor.clamp(0.0, 1.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const VerticalDivider(width: 1),
                                SizedBox(
                                  width: effectiveSidePanelWidth,
                                  child: sidePanel,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: isCompact ? 1.0 : 0.0),
            duration: transitionDuration,
            curve: transitionCurve,
            builder: (context, barFactor, child) {
              if (barFactor <= 0.001) {
                return const SizedBox.shrink();
              }
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: barFactor,
                  child: Opacity(
                    opacity: barFactor.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              );
            },
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              indicatorColor: scheme.primaryContainer,
              destinations: destinations.map((dest) {
                return NavigationDestination(
                  icon: _wrapBadge(context, Icon(dest.icon), dest.badgeLabel),
                  selectedIcon: _wrapBadge(
                    context,
                    Icon(dest.selectedIcon ?? dest.icon),
                    dest.badgeLabel,
                  ),
                  label: dest.label,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Reusable, smoothly animated Material 3 Adaptive Master-Detail workspace
/// supporting Phone (`< splitBreakpoint`), Foldable (`splitBreakpoint..expandedBreakpoint`),
/// and Tablet/Desktop (`>= expandedBreakpoint`) with zero Navigator route
/// duplication during live window resizing.
class M3xAdaptiveMasterDetail extends StatefulWidget {
  final Widget Function(
    BuildContext context,
    bool isSplit,
    VoidCallback openDetail,
  ) masterBuilder;
  final Widget Function(
    BuildContext context,
    bool isSplit,
    VoidCallback closeDetail,
  ) detailBuilder;
  final Widget Function(BuildContext context)? emptyDetailBuilder;
  final bool hasSelection;
  final Object? detailKey;
  final double splitBreakpoint;
  final double expandedBreakpoint;
  final double mediumMasterFraction;
  final double expandedMasterFraction;
  final double? mediumMasterWidth;
  final double? expandedMasterWidth;
  final double minMasterWidth;
  final double maxMasterWidth;
  final bool allowResize;
  final bool masterCollapsed;
  final Duration transitionDuration;
  final Curve transitionCurve;
  final Color? detailBackgroundColor;
  final double detailBorderRadius;
  final VoidCallback? onDetailClosed;

  const M3xAdaptiveMasterDetail({
    super.key,
    required this.masterBuilder,
    required this.detailBuilder,
    this.emptyDetailBuilder,
    this.hasSelection = false,
    this.detailKey,
    this.splitBreakpoint = 680.0,
    this.expandedBreakpoint = 960.0,
    this.mediumMasterFraction = 0.5,
    this.expandedMasterFraction = 1 / 3,
    this.mediumMasterWidth,
    this.expandedMasterWidth,
    this.minMasterWidth = 260.0,
    this.maxMasterWidth = 560.0,
    this.allowResize = true,
    this.masterCollapsed = false,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionCurve = Curves.easeOutCubic,
    this.detailBackgroundColor,
    this.detailBorderRadius = 24.0,
    this.onDetailClosed,
  });

  @override
  State<M3xAdaptiveMasterDetail> createState() =>
      _M3xAdaptiveMasterDetailState();
}

class _M3xAdaptiveMasterDetailState extends State<M3xAdaptiveMasterDetail> {
  late bool _showingDetailInCompact;
  double? _customMasterWidth;
  bool _isDragging = false;
  bool _isHoveringDivider = false;

  @override
  void initState() {
    super.initState();
    _showingDetailInCompact = widget.hasSelection;
  }

  @override
  void didUpdateWidget(covariant M3xAdaptiveMasterDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.hasSelection && widget.hasSelection) {
      _showingDetailInCompact = true;
    } else if (oldWidget.hasSelection && !widget.hasSelection) {
      _showingDetailInCompact = false;
    } else if (widget.hasSelection && widget.detailKey != oldWidget.detailKey) {
      _showingDetailInCompact = true;
    }
  }

  void _openDetail() {
    if (!_showingDetailInCompact) {
      setState(() {
        _showingDetailInCompact = true;
      });
    }
  }

  void _closeDetail() {
    if (_showingDetailInCompact) {
      setState(() {
        _showingDetailInCompact = false;
      });
    }
    widget.onDetailClosed?.call();
  }

  Widget _buildSplitterDivider(
    BuildContext context, {
    required double currentWidth,
    required double minWidth,
    required double maxWidth,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    const double dividerHitWidth = 12.0;

    final Color pillColor = _isDragging
        ? scheme.primary
        : (_isHoveringDivider
            ? scheme.onSurfaceVariant.withValues(alpha: 0.72)
            : scheme.outlineVariant.withValues(alpha: 0.85));

    final Widget handle = Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        width: _isDragging || _isHoveringDivider ? 4.0 : 3.0,
        height: _isDragging ? 52.0 : (_isHoveringDivider ? 40.0 : 28.0),
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );

    final Widget dividerBody = widget.allowResize
        ? MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            onEnter: (_) => setState(() => _isHoveringDivider = true),
            onExit: (_) => setState(() => _isHoveringDivider = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) {
                setState(() {
                  _isDragging = true;
                  _customMasterWidth = currentWidth;
                });
              },
              onHorizontalDragUpdate: (details) {
                final double delta =
                    isRtl ? -details.delta.dx : details.delta.dx;
                final double next =
                    ((_customMasterWidth ?? currentWidth) + delta)
                        .clamp(minWidth, maxWidth);
                setState(() {
                  _customMasterWidth = next;
                });
              },
              onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
              onHorizontalDragCancel: () => setState(() => _isDragging = false),
              onDoubleTap: () {
                setState(() {
                  _customMasterWidth = null;
                });
              },
              child: SizedBox(
                width: dividerHitWidth,
                height: double.infinity,
                child: handle,
              ),
            ),
          )
        : SizedBox(
            width: 8.0,
            height: double.infinity,
            child: Center(
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          );

    final double targetDividerWidth = widget.masterCollapsed
        ? 0.0
        : (widget.allowResize ? dividerHitWidth : 8.0);

    return AnimatedContainer(
      duration: _isDragging ? Duration.zero : widget.transitionDuration,
      curve: widget.transitionCurve,
      width: targetDividerWidth,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: IgnorePointer(
        ignoring: widget.masterCollapsed,
        child: dividerBody,
      ),
    );
  }

  Widget _buildSplitLayout(
    BuildContext context,
    BoxConstraints constraints,
    M3xWindowSizeClass sizeClass,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double availableWidth = constraints.maxWidth;
    final bool isExpanded = sizeClass.isExpanded;
    final double reservedDivider = widget.allowResize ? 12.0 : 8.0;

    // Guarantee the detail pane always retains usable width even at narrow split sizes
    final double safeMaxFromParent =
        math.max(0.0, availableWidth - 280.0 - reservedDivider);
    final double modeMaxWidth =
        isExpanded ? widget.maxMasterWidth : availableWidth * 0.55;
    final double effectiveMax = math.min(modeMaxWidth, safeMaxFromParent);
    final double effectiveMin = math.min(widget.minMasterWidth, effectiveMax);
    final double? explicitMasterWidth =
        isExpanded ? widget.expandedMasterWidth : widget.mediumMasterWidth;
    final double baseMasterWidth = explicitMasterWidth ??
        (availableWidth *
                (isExpanded
                    ? widget.expandedMasterFraction
                    : widget.mediumMasterFraction))
            .clamp(effectiveMin, effectiveMax);
    final double resolvedOpenWidth = (_customMasterWidth ?? baseMasterWidth)
        .clamp(effectiveMin, effectiveMax);
    final double targetMasterWidth =
        widget.masterCollapsed ? 0.0 : resolvedOpenWidth;

    final bool hasActiveDetail = widget.hasSelection || _showingDetailInCompact;
    final bool showEmpty =
        !hasActiveDetail && widget.emptyDetailBuilder != null;
    final Object effectiveDetailKey = showEmpty
        ? '__m3x_adaptive_empty_detail__'
        : (widget.detailKey ?? hasActiveDetail);

    final Widget detailContent = showEmpty
        ? KeyedSubtree(
            key: const ValueKey<String>('__m3x_adaptive_empty_detail__'),
            child: widget.emptyDetailBuilder!(context),
          )
        : KeyedSubtree(
            key: ValueKey<Object>(effectiveDetailKey),
            child: widget.detailBuilder(context, true, _closeDetail),
          );

    final Color effectiveDetailBg =
        widget.detailBackgroundColor ?? scheme.surfaceContainerLowest;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Smoothly animated (and 60fps-draggable) Master pane
        AnimatedContainer(
          key: const ValueKey<String>('m3x_adaptive_master_pane'),
          duration: _isDragging ? Duration.zero : widget.transitionDuration,
          curve: widget.transitionCurve,
          width: targetMasterWidth,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: resolvedOpenWidth > 0
              ? OverflowBox(
                  alignment: AlignmentDirectional.centerStart,
                  minWidth: resolvedOpenWidth,
                  maxWidth: resolvedOpenWidth,
                  child: SizedBox(
                    width: resolvedOpenWidth,
                    child: IgnorePointer(
                      ignoring: widget.masterCollapsed,
                      child: ExcludeSemantics(
                        excluding: widget.masterCollapsed,
                        child: ExcludeFocus(
                          excluding: widget.masterCollapsed,
                          child:
                              widget.masterBuilder(context, true, _openDetail),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Interactive M3 resize handle divider
        _buildSplitterDivider(
          context,
          currentWidth: resolvedOpenWidth,
          minWidth: effectiveMin,
          maxWidth: effectiveMax,
        ),

        // Rounded Material 3 Detail pane
        Expanded(
          child: AnimatedPadding(
            duration: _isDragging ? Duration.zero : widget.transitionDuration,
            curve: widget.transitionCurve,
            padding: EdgeInsetsDirectional.only(
              start: widget.masterCollapsed ? 12.0 : 0.0,
              end: 12.0,
              top: 8.0,
              bottom: 8.0,
            ),
            child: Material(
              color: effectiveDetailBg,
              borderRadius: BorderRadius.circular(widget.detailBorderRadius),
              clipBehavior: Clip.antiAlias,
              child: AnimatedSwitcher(
                duration: widget.transitionDuration,
                switchInCurve: widget.transitionCurve,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final Offset slideBegin = Offset(isRtl ? -0.025 : 0.025, 0.0);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: slideBegin,
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: detailContent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    final Widget activeChild = _showingDetailInCompact
        ? KeyedSubtree(
            key: ValueKey<Object>(
              '__m3x_compact_detail_${widget.detailKey ?? 'active'}',
            ),
            child: widget.detailBuilder(context, false, _closeDetail),
          )
        : KeyedSubtree(
            key: const ValueKey<String>('__m3x_compact_master__'),
            child: widget.masterBuilder(context, false, _openDetail),
          );

    return AnimatedSwitcher(
      duration: widget.transitionDuration,
      switchInCurve: widget.transitionCurve,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final bool isIncomingDetail =
            child.key != const ValueKey<String>('__m3x_compact_master__');
        final double directionSign = isIncomingDetail ? 1.0 : -1.0;
        final double rtlMultiplier = isRtl ? -1.0 : 1.0;
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.06 * directionSign * rtlMultiplier, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: activeChild,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final M3xWindowSizeClass sizeClass = M3xWindowSizeClass.fromWidth(
          width,
          mediumBreakpoint: widget.splitBreakpoint,
          expandedBreakpoint: widget.expandedBreakpoint,
        );
        final bool isSplit = sizeClass.isSplit;

        return PopScope(
          canPop: isSplit || !_showingDetailInCompact,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop && !isSplit && _showingDetailInCompact) {
              _closeDetail();
            }
          },
          child: isSplit
              ? _buildSplitLayout(context, constraints, sizeClass)
              : _buildCompactLayout(context),
        );
      },
    );
  }
}

/// Smoothly adapts onboarding, welcome, and sign-in screens between a single
/// centered scrollable column (`maxWidth: 580`) below [splitBreakpoint] (default
/// `760.0`) and a 2-column side-by-side layout (left [heroPane] 42% flex, right
/// [contentPane] 58% flex, `maxWidth: 1080`) at/above [splitBreakpoint].
class M3xAdaptiveSplitHero extends StatelessWidget {
  final Widget heroPane;
  final Widget contentPane;
  final double splitBreakpoint;
  final double compactMaxWidth;
  final double expandedMaxWidth;
  final int heroFlex;
  final int contentFlex;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final Duration transitionDuration;
  final Curve transitionCurve;

  const M3xAdaptiveSplitHero({
    super.key,
    required this.heroPane,
    required this.contentPane,
    this.splitBreakpoint = 760.0,
    this.compactMaxWidth = 580.0,
    this.expandedMaxWidth = 1080.0,
    this.heroFlex = 42,
    this.contentFlex = 58,
    this.spacing = 32.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionCurve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final bool isSplit = width >= splitBreakpoint;
        final bool hasBoundedHeight = constraints.hasBoundedHeight;

        final Widget child = isSplit
            ? KeyedSubtree(
                key: const ValueKey<String>('m3x_split_hero_wide'),
                child: Align(
                  alignment: Alignment.center,
                  heightFactor: hasBoundedHeight ? null : 1.0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: expandedMaxWidth),
                    child: Padding(
                      padding: padding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: heroFlex,
                            child: hasBoundedHeight
                                ? SingleChildScrollView(child: heroPane)
                                : heroPane,
                          ),
                          SizedBox(width: spacing),
                          Expanded(
                            flex: contentFlex,
                            child: hasBoundedHeight
                                ? SingleChildScrollView(child: contentPane)
                                : contentPane,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : KeyedSubtree(
                key: const ValueKey<String>('m3x_split_hero_compact'),
                child: Align(
                  alignment: Alignment.center,
                  heightFactor: hasBoundedHeight ? null : 1.0,
                  child: hasBoundedHeight
                      ? SingleChildScrollView(
                          padding: padding,
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: compactMaxWidth),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                heroPane,
                                SizedBox(height: spacing),
                                contentPane,
                              ],
                            ),
                          ),
                        )
                      : Padding(
                          padding: padding,
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: compactMaxWidth),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                heroPane,
                                SizedBox(height: spacing),
                                contentPane,
                              ],
                            ),
                          ),
                        ),
                ),
              );

        return AnimatedSwitcher(
          duration: transitionDuration,
          switchInCurve: transitionCurve,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: child,
        );
      },
    );
  }
}

/// Centered empty-state placeholder view with a 72px muted icon, bold title,
/// description, optional primary CTA button, and optional [TextPart.infoShort]
/// footer.
///
/// Extracted from `PTK`'s server and status page tabs.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;
  final String? footerTitle;
  final String? footerSubtitle;
  final VoidCallback? onFooterAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.actionIcon = Icons.add_rounded,
    this.onAction,
    this.footerTitle,
    this.footerSubtitle,
    this.onFooterAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 30),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon),
                label: Text(actionLabel!),
              ),
            ],
            if (footerTitle != null && footerTitle!.isNotEmpty) ...[
              const SizedBox(height: 30),
              TextPart.infoShort(
                title: footerTitle!,
                subtitle: footerSubtitle ?? '',
                action: onFooterAction ?? () {},
                context: context,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standardized Material 3 theme builder used across Puzzak's Flutter apps.
class PuzzakTheme {
  static const Color defaultSeedColor = Color(0xFF009688);

  /// Builds a Material 3 [ThemeData] with Puzzak's card theme (`20px` outer
  /// radius, `surfaceContainer` background, `primary` surface tint, `elevation: 3`)
  /// and Android predictive back page transitions.
  static ThemeData buildTheme({
    required Brightness brightness,
    Color seedColor = defaultSeedColor,
    ColorScheme? dynamicScheme,
  }) {
    final ColorScheme scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
        );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: scheme.primary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.hardEdge,
      ),
    );
  }
}

/// Modern alias for [PuzzakTheme] under the M3x brand.
typedef M3xTheme = PuzzakTheme;

/// Signature startup cross-fade shell from `PTK`, `geminilocal`, and `the2k48`.
///
/// Smoothly cross-fades from a centered rounded [CircularProgressIndicator] to
/// [onboardingChild] (when [showOnboarding] is true) or [child] once
/// [appStarted] becomes true.
class StartupCrossFadeShell extends StatelessWidget {
  final bool appStarted;
  final Widget child;
  final Widget? onboardingChild;
  final bool showOnboarding;
  final Duration duration;

  const StartupCrossFadeShell({
    super.key,
    required this.appStarted,
    required this.child,
    this.onboardingChild,
    this.showOnboarding = false,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    if (appStarted && showOnboarding && onboardingChild != null) {
      return onboardingChild!;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedCrossFade(
          alignment: Alignment.center,
          duration: duration,
          firstChild: SizedBox(
            height:
                constraints.maxHeight.isFinite ? constraints.maxHeight : null,
            width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
            child: child,
          ),
          secondChild: SizedBox(
            height:
                constraints.maxHeight.isFinite ? constraints.maxHeight : 300,
            width: constraints.maxWidth.isFinite ? constraints.maxWidth : 300,
            child: const Center(
              child: CircularProgressIndicator(strokeCap: StrokeCap.round),
            ),
          ),
          crossFadeState:
              appStarted ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        );
      },
    );
  }
}

/// Floating island navigation capsule (inspired by Sameera's Essentials).
///
/// Features a stadium-shaped frosted container with backdrop blur, a circular
/// contrasting action button (defaulting to back navigation), bold title, and
/// an optional trailing action button. Can be pinned over the bottom of a page,
/// used as a floating header, or integrated into custom navigation flows.
class FloatingNavPill extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final bool showBackButton;
  final IconData backIcon;
  final Widget? leading;
  final Widget? trailing;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? backButtonColor;
  final Color? backButtonIconColor;
  final double height;
  final EdgeInsetsGeometry? margin;
  final double elevation;

  const FloatingNavPill({
    super.key,
    required this.title,
    this.titleWidget,
    this.onBack,
    this.showBackButton = true,
    this.backIcon = Icons.arrow_back_rounded,
    this.leading,
    this.trailing,
    this.backgroundColor,
    this.foregroundColor,
    this.backButtonColor,
    this.backButtonIconColor,
    this.height = 48.0,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.elevation = 4.0,
  });

  /// Factory helper for creating the matching rounded-squircle action button
  /// (as seen in Sameera Essentials, Image 1), ideal for [trailing].
  static Widget actionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? backgroundColor,
    Color? foregroundColor,
    double? size,
    BorderRadius? borderRadius,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final double btnSize = size ?? 48.0;
    final Color effectiveBg = backgroundColor ?? scheme.primaryContainer;
    final Color effectiveFg = foregroundColor ?? scheme.onPrimaryContainer;
    final BorderRadius effectiveRadius =
        borderRadius ?? BorderRadius.circular(16.0);

    return Container(
      width: btnSize,
      height: btnSize,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Tooltip(
            message: tooltip ?? '',
            child: Center(
              child: Icon(icon, size: 22, color: effectiveFg),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Use light mint / primaryContainer as in Sameera Essentials (Image 1)
    final Color effectiveBg = backgroundColor ?? scheme.primaryContainer;
    final Color effectiveFg = foregroundColor ?? scheme.onPrimaryContainer;
    final Color effectiveBackBg = backButtonColor ?? scheme.onPrimaryContainer;
    final Color effectiveBackFg =
        backButtonIconColor ?? scheme.primaryContainer;

    final Widget mainPill = Container(
      height: height,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: elevation * 2.5,
                  offset: Offset(0, elevation / 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(height / 2),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 18, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null)
                leading!
              else if (showBackButton)
                Material(
                  color: effectiveBackBg,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onBack ?? () => Navigator.maybePop(context),
                    child: SizedBox(
                      width: height - 8,
                      height: height - 8,
                      child: Center(
                        child: Icon(
                          backIcon,
                          size: 20,
                          color: effectiveBackFg,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              titleWidget ??
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: effectiveFg,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            ],
          ),
        ),
      ),
    );

    return Container(
      margin: margin,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          mainPill,
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
