import 'dart:ui';

import 'package:flutter/material.dart';

class TextTabBar extends StatefulWidget {
  /// Creates a Material Design primary tab bar.
  ///
  /// The length of the [tabs] argument must match the [controller]'s
  /// [TabController.length].
  ///
  /// If a [TabController] is not provided, then there must be a
  /// [DefaultTabController] ancestor.
  const TextTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.onTap,
    this.selectedTextStyle,
    this.unselectedTextStyle,
    this.isFloatingAnimation = _defaultIsFloatingAnimation,
    this.spacing = _defaultHorizontalPadding,
  }) : assert(spacing >= .0);

  static const _defaultHorizontalPadding = 8.0;
  static const _defaultIsFloatingAnimation = false;

  /// The list of tab labels to display.
  ///
  /// The length of this list must match the [controller]'s [TabController.length]
  /// and the length of the [TabBarView.children] list.
  final List<String> tabs;

  /// This widget's selection and animation state.
  ///
  /// If [TabController] is not provided, then the value of [DefaultTabController.of]
  /// will be used.
  final TabController? controller;

  /// An optional callback that's called when the [TabBar] is tapped.
  ///
  /// The callback is applied to the index of the tab where the tap occurred.
  ///
  /// This callback has no effect on the default handling of taps. It's for
  /// applications that want to do a little extra work when a tab is tapped,
  /// even if the tap doesn't change the TabController's index. TabBar [onTap]
  /// callbacks should not make changes to the TabController since that would
  /// interfere with the default tap handler.
  final ValueChanged<int>? onTap;

  /// If non-null, the [TextStyle] for the selected tab.
  /// If not provided, a default style will be used.
  final TextStyle? selectedTextStyle;

  /// If non-null, the [TextStyle] for the unselected tabs.
  /// If not provided, a default style will be used.
  final TextStyle? unselectedTextStyle;

  /// The base padding for the tabs. The selected tab's padding will be twice this value.
  ///
  /// The default value of this property is 8.0.
  final double spacing;

  /// Whether the animation should affect the elements between the current
  /// and previous element.
  ///
  /// The default value of this property is false.
  ///
  /// If [isFloatingAnimation] is true,
  /// then when switching between tabs more than one, the animation will
  /// engage the elements between tabs. The animation will resemble a wave.
  final bool isFloatingAnimation;

  @override
  State<TextTabBar> createState() => _TextTabBarState();
}

class _TextTabBarState extends State<TextTabBar>
    with SingleTickerProviderStateMixin {
  static const TextStyle _defaultSelectedTextStyle = TextStyle(
    fontSize: 24.0,
    color: Colors.black,
  );
  static const TextStyle _defaultUnselectedTextStyle = TextStyle(
    fontSize: 18.0,
    color: Colors.grey,
  );

  late final ScrollController _scrollController;
  late final AnimationController _animationController;
  late final List<GlobalKey> _tabKeys;

  TabController? _tabController;

  // Calculate them once and store for reuse
  late TextStyle _selectedTextStyle;
  late TextStyle _unselectedTextStyle;

  // To avoid text "jumping" during animation, we must manually
  // define the height of the TabBar based on the font size
  late double _tabBarHeight;

  int _previousIndex = -1;
  int _currentIndex = 0;

  // If the TabBar is rebuilt with a new tab controller, the caller should
  // dispose the old one. In that case the old controller's animation will be
  // null and should not be accessed.
  bool get _controllerIsValid => _tabController?.animation != null;

  @override
  void initState() {
    super.initState();

    _tabKeys = widget.tabs.map((tab) => GlobalKey()).toList();

    _scrollController = ScrollController();

    _animationController = AnimationController(
      duration: _tabController?.animationDuration,
      vsync: this,
    )..addListener(() {
        setState(() {});
      });

    _animationController.value = 1.0;

    _calculateTextStyles();
    _calculateTabBarHeight();
  }

  @override
  void dispose() {
    if (_controllerIsValid) {
      _tabController!.removeListener(_handleController);
      _tabController!.animation?.removeListener(_handleTabAnimation);
    }

    _tabController = null;
    _animationController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasMaterial(context));
    _updateTabController();
    _syncAnimationDurations();
  }

  @override
  void didUpdateWidget(TextTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check for controller field changes
    if (widget.controller != oldWidget.controller) {
      _updateTabController();
      _syncAnimationDurations();
    }

    // Check for tabs field changes
    if (widget.tabs.length > oldWidget.tabs.length) {
      final delta = widget.tabs.length - oldWidget.tabs.length;
      _tabKeys.addAll(List<GlobalKey>.generate(delta, (n) => GlobalKey()));
    } else if (widget.tabs.length < oldWidget.tabs.length) {
      _tabKeys.removeRange(widget.tabs.length, oldWidget.tabs.length);
    }

    // Check for text styles fields changes
    if (widget.selectedTextStyle != oldWidget.selectedTextStyle ||
        widget.unselectedTextStyle != oldWidget.unselectedTextStyle) {
      _calculateTextStyles();
      _calculateTabBarHeight();
    }
  }

  void _calculateTextStyles() {
    _selectedTextStyle = _defaultSelectedTextStyle.merge(
      widget.selectedTextStyle,
    );
    _unselectedTextStyle = _defaultUnselectedTextStyle.merge(
      widget.unselectedTextStyle,
    );
  }

  void _calculateTabBarHeight() {
    // There may be a situation where custom styles will have
    // an inverse font size ratio
    final highestStyle =
        _selectedTextStyle.fontSize! > _unselectedTextStyle.fontSize!
            ? _selectedTextStyle
            : _unselectedTextStyle;

    final textPainter = TextPainter(
      text: TextSpan(style: highestStyle),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    _tabBarHeight = textPainter.size.height;
  }

  void _updateTabController() {
    final newController = widget.controller ?? DefaultTabController.of(context);
    assert(() {
      // ignore: unnecessary_null_comparison
      if (newController == null) {
        throw FlutterError('No TabController for ${widget.runtimeType}.\n'
            'When creating a ${widget.runtimeType}, you must either provide an explicit '
            'TabController using the "controller" property, or you must ensure that there '
            'is a DefaultTabController above the ${widget.runtimeType}.\n'
            'In this case, there was neither an explicit controller nor a default controller.');
      }
      return true;
    }());

    if (newController == _tabController) {
      return;
    }

    if (_controllerIsValid) {
      _tabController!.animation!.removeListener(_handleTabAnimation);
      _tabController!.removeListener(_handleController);
    }

    _tabController = newController;
    _currentIndex = _tabController!.index;
    _tabController!.animation!.addListener(_handleTabAnimation);
    _tabController!.addListener(_handleController);

    Future.delayed(Duration.zero, () {
      _scrollToSelectedItem();
    });
  }

  void _syncAnimationDurations() {
    _animationController.duration = _tabController?.animationDuration;
  }

  void _handleTabAnimation() {
    setState(() {});
  }

  void _handleController() {
    if (!_tabController!.indexIsChanging) {
      _setCurrentIndex(_tabController!.index);
    }
  }

  _setCurrentIndex(int index) {
    if (index == _currentIndex) {
      return;
    }

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });

    _scrollToSelectedItem();
  }

  void _onTabTap(int index) {
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;

      _tabController!.animateTo(index);
      _tabController!.index = index;

      _animationController.reset();
      _animationController.forward();
    });

    widget.onTap?.call(index);
    _scrollToSelectedItem();
  }

  double _getSelectedItemOffset() {
    final keyContext = _tabKeys[_tabController!.index].currentContext;

    if (keyContext == null) {
      return .0;
    }

    final box = keyContext.findRenderObject() as RenderBox;
    final itemPosition = box.localToGlobal(Offset.zero).dx;
    final itemWidth = box.size.width;
    final screenWidth = MediaQuery.of(context).size.width;

    if (itemPosition + itemWidth > screenWidth) {
      // If the item is partially off-screen to the right
      return itemPosition + itemWidth - screenWidth;
    } else if (itemPosition < .0) {
      // If the item is partially off-screen to the left
      return itemPosition;
    }

    return .0;
  }

  double _getPreviousSelectedItemOffset(double itemOffset) {
    if (_previousIndex == -1) {
      return .0;
    }

    final keyContext = _tabKeys[_previousIndex].currentContext;

    if (keyContext == null) {
      return .0;
    }

    // Whether the item on the screen is detected or not
    final box = keyContext.findRenderObject() as RenderBox;
    final itemPosition = box.localToGlobal(Offset.zero).dx;
    final itemWidth = box.size.width;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = widget.spacing;
    final itemPadding = padding * 4;

    if (itemPosition == .0) {
      return itemPosition;
    }

    if ((itemPosition > .0 && itemPosition + itemWidth < screenWidth) ||
        itemPosition < .0 && itemPosition + itemWidth > .0) {
      // Item is found on the screen
      if (itemPosition + itemWidth > screenWidth) {
        // If the previous item is partially off-screen to the right
        return padding;
      }
    } else {
      // Item is not on the screen
      if (itemPosition - itemPadding < .0 && itemOffset < .0) {
        // If the previous item is partially off-screen to the left
        return padding * 2;
      } else if (itemPosition - itemPadding > .0 && itemOffset > .0) {
        return -padding * 2;
      }
    }

    return .0;
  }

  void _scrollToSelectedItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemOffset = _getSelectedItemOffset();

      // We need to take into account the previously selected element
      // and its position, because its padding may change, which will
      // affect the correctness of scrolling
      final previousItemOffset = _getPreviousSelectedItemOffset(itemOffset);

      _scrollController.animateTo(
        _scrollController.offset + itemOffset - previousItemOffset,
        duration: _tabController!.animationDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  double _getAnimationValue(int index) {
    if (_tabController!.indexIsChanging && !widget.isFloatingAnimation) {
      if (index == _previousIndex) {
        return 1.0 - _animationController.value;
      }
      if (index == _currentIndex) {
        return _animationController.value;
      }
      return 0.0;
    }

    final tabValue =
        _tabController!.animation?.value ?? _tabController!.index.toDouble();

    final distance = (index - tabValue).abs();

    return (1.0 - distance.clamp(0.0, 1.0));
  }

  Widget _constructTabBarItem(int index) {
    final animationValue = _getAnimationValue(index);

    // Interpolate styles
    final interpolatedStyle = TextStyle.lerp(
          _unselectedTextStyle,
          _selectedTextStyle,
          animationValue,
        ) ??
        _unselectedTextStyle;

    // Interpolate padding
    final padding = widget.spacing;
    final interpolatedPadding = lerpDouble(
          padding,
          padding * 2,
          animationValue,
        ) ??
        padding;

    return _TextTabBarItem(
      key: _tabKeys[index],
      padding: EdgeInsets.symmetric(horizontal: interpolatedPadding),
      onTap: () => _onTabTap(index),
      style: interpolatedStyle,
      text: widget.tabs[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      if (_tabController!.length != widget.tabs.length) {
        throw FlutterError(
            "Controller's length property (${_tabController!.length}) does not match the "
            "number of tabs (${widget.tabs.length}) present in TabBar's tabs property.");
      }
      return true;
    }());
    if (_tabController!.length == 0) return Container(height: _tabBarHeight);

    return SizedBox(
      height: _tabBarHeight,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(
            widget.tabs.length,
            _constructTabBarItem,
          ),
        ),
      ),
    );
  }
}

class _TextTabBarItem extends StatelessWidget {
  const _TextTabBarItem({
    super.key,
    required this.padding,
    required this.onTap,
    required this.style,
    required this.text,
  });

  final EdgeInsetsGeometry padding;
  final VoidCallback onTap;
  final TextStyle style;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: GestureDetector(
        onTap: onTap,
        child: DefaultTextStyle(
          style: style,
          child: Text(text),
        ),
      ),
    );
  }
}
