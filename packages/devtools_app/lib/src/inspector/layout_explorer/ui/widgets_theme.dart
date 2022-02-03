// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart=2.9

import 'package:flutter/material.dart';

class WidgetTheme {
  const WidgetTheme({
    this.iconAsset,
    this.color = otherWidgetColor,
  });

  final String iconAsset;
  final Color color;

  static WidgetTheme fromName(String widgetType) {
    if (widgetType == null) {
      return const WidgetTheme();
    }

    return themeMap[_stripBrackets(widgetType)] ?? const WidgetTheme();
  }

  /// Strips the brackets off the widget name.
  ///
  /// For example: `AnimatedBuilder<String>` -> `AnimatedBuilder`.
  static String _stripBrackets(String widgetType) {
    final bracketIndex = widgetType.indexOf('<');
    if (bracketIndex == -1) {
      return widgetType;
    }

    return widgetType.substring(0, bracketIndex);
  }

  static const contentWidgetColor = Color(0xff06AC3B);
  static const highLevelWidgetColor = Color(0xffAEAEB1);
  static const animationWidgetColor = Color(0xffE09D0E);
  static const otherWidgetColor = Color(0xff0EA7E0);

  static const animatedTheme = WidgetTheme(
    iconAsset: WidgetIcons.animated,
    color: animationWidgetColor,
  );

  static const transitionTheme = WidgetTheme(
    iconAsset: WidgetIcons.transition,
    color: animationWidgetColor,
  );

  static const textTheme = WidgetTheme(
    iconAsset: WidgetIcons.text,
    color: contentWidgetColor,
  );

  static const imageTheme = WidgetTheme(
    iconAsset: WidgetIcons.image,
    color: contentWidgetColor,
  );

  static const tabTheme = WidgetTheme(iconAsset: WidgetIcons.tab);
  static const scrollTheme = WidgetTheme(iconAsset: WidgetIcons.scroll);
  static const highLevelTheme = WidgetTheme(color: highLevelWidgetColor);
  static const listTheme = WidgetTheme(iconAsset: WidgetIcons.listView);
  static const expandTheme = WidgetTheme(iconAsset: WidgetIcons.expand);
  static const alignTheme = WidgetTheme(iconAsset: WidgetIcons.align);
  static const gestureTheme = WidgetTheme(iconAsset: WidgetIcons.gesture);
  static const textButtonTheme = WidgetTheme(iconAsset: WidgetIcons.textButton);
  static const toggleTheme = WidgetTheme(
    iconAsset: WidgetIcons.toggle,
    color: contentWidgetColor,
  );

  static const Map<String, WidgetTheme> themeMap = {
    // High-level
    'RenderObjectToWidgetAdapter': WidgetTheme(
      iconAsset: WidgetIcons.root,
      color: highLevelWidgetColor,
    ),
    'CupertinoApp': highLevelTheme,
    'MaterialApp': WidgetTheme(iconAsset: WidgetIcons.materialApp),
    'WidgetsApp': highLevelTheme,

    // Text
    'DefaultTextStyle': textTheme,
    'RichText': textTheme,
    'SelectableText': textTheme,
    'Text': textTheme,

    // Images
    'Icon': imageTheme,
    'Image': imageTheme,
    'RawImage': imageTheme,

    // Animations
    'AnimatedAlign': animatedTheme,
    'AnimatedBuilder': animatedTheme,
    'AnimatedContainer': animatedTheme,
    'AnimatedCrossFade': animatedTheme,
    'AnimatedDefaultTextStyle': animatedTheme,
    'AnimatedListState': animatedTheme,
    'AnimatedModalBarrier': animatedTheme,
    'AnimatedOpacity': animatedTheme,
    'AnimatedPhysicalModel': animatedTheme,
    'AnimatedPositioned': animatedTheme,
    'AnimatedSize': animatedTheme,
    'AnimatedWidget': animatedTheme,

    // Transitions
    'DecoratedBoxTransition': transitionTheme,
    'FadeTransition': transitionTheme,
    'PositionedTransition': transitionTheme,
    'RotationTransition': transitionTheme,
    'ScaleTransition': transitionTheme,
    'SizeTransition': transitionTheme,
    'SlideTransition': transitionTheme,
    'Hero': WidgetTheme(
      iconAsset: WidgetIcons.hero,
      color: animationWidgetColor,
    ),

    // Scroll
    'CustomScrollView': scrollTheme,
    'DraggableScrollableSheet': scrollTheme,
    'SingleChildScrollView': scrollTheme,
    'Scrollable': scrollTheme,
    'Scrollbar': scrollTheme,
    'ScrollConfiguration': scrollTheme,
    'GridView': WidgetTheme(iconAsset: WidgetIcons.gridView),
    'ListView': listTheme,
    'ReorderableListView': listTheme,
    'NestedScrollView': listTheme,

    // Input
    'Checkbox': WidgetTheme(
      iconAsset: WidgetIcons.checkbox,
      color: contentWidgetColor,
    ),
    'Radio': WidgetTheme(
      iconAsset: WidgetIcons.radio,
      color: contentWidgetColor,
    ),
    'Switch': toggleTheme,
    'CupertinoSwitch': toggleTheme,

    // Layout
    'Container': WidgetTheme(iconAsset: WidgetIcons.container),
    'Center': WidgetTheme(iconAsset: WidgetIcons.center),
    'Row': WidgetTheme(iconAsset: WidgetIcons.row),
    'Column': WidgetTheme(iconAsset: WidgetIcons.column),
    'Padding': WidgetTheme(iconAsset: WidgetIcons.padding),
    'SizedBox': WidgetTheme(iconAsset: WidgetIcons.sizedBox),
    'ConstrainedBox': WidgetTheme(iconAsset: WidgetIcons.constrainedBox),
    'Align': alignTheme,
    'Positioned': alignTheme,
    'Expanded': expandTheme,
    'Flexible': expandTheme,
    'Stack': WidgetTheme(iconAsset: WidgetIcons.stack),
    'Wrap': WidgetTheme(iconAsset: WidgetIcons.wrap),

    // Buttons
    'FloatingActionButton': WidgetTheme(
      iconAsset: WidgetIcons.floatingActionButton,
      color: contentWidgetColor,
    ),
    'InkWell': WidgetTheme(iconAsset: WidgetIcons.inkWell),
    'GestureDetector': gestureTheme,
    'RawGestureDetector': gestureTheme,
    'TextButton': textButtonTheme,
    'CupertinoButton': textButtonTheme,
    'ElevatedButton': textButtonTheme,
    'OutlinedButton': WidgetTheme(iconAsset: WidgetIcons.outlinedButton),

    // Tabs
    'Tab': tabTheme,
    'TabBar': tabTheme,
    'TabBarView': tabTheme,
    'BottomNavigationBar':
        WidgetTheme(iconAsset: WidgetIcons.bottomNavigationBar),
    'CupertinoTabScaffold': tabTheme,
    'CupertinoTabView': tabTheme,

    // Other
    'Scaffold': WidgetTheme(iconAsset: WidgetIcons.scaffold),
    'CircularProgressIndicator':
        WidgetTheme(iconAsset: WidgetIcons.circularProgress),
    'Card': WidgetTheme(iconAsset: WidgetIcons.card),
    'Divider': WidgetTheme(iconAsset: WidgetIcons.divider),
    'AlertDialog': WidgetTheme(iconAsset: WidgetIcons.alertDialog),
    'CircleAvatar': WidgetTheme(iconAsset: WidgetIcons.circleAvatar),
    'Opacity': WidgetTheme(iconAsset: WidgetIcons.opacity),
    'Drawer': WidgetTheme(iconAsset: WidgetIcons.drawer),
    'PageView': WidgetTheme(iconAsset: WidgetIcons.pageView),
    'Material': WidgetTheme(iconAsset: WidgetIcons.material),
    'AppBar': WidgetTheme(iconAsset: WidgetIcons.appBar),
  };
}

class WidgetIcons {
  static const String root = 'icons/inspector/widget_icons/root.png';
  static const String text = 'icons/inspector/widget_icons/text.png';
  static const String icon = 'icons/inspector/widget_icons/icon.png';
  static const String image = 'icons/inspector/widget_icons/image.png';
  static const String floatingActionButton =
      'icons/inspector/widget_icons/floatingab.png';
  static const String checkbox = 'icons/inspector/widget_icons/checkbox.png';
  static const String radio = 'icons/inspector/widget_icons/radio.png';
  static const String toggle = 'icons/inspector/widget_icons/toggle.png';
  static const String animated = 'icons/inspector/widget_icons/animated.png';
  static const String transition =
      'icons/inspector/widget_icons/transition.png';
  static const String hero = 'icons/inspector/widget_icons/hero.png';
  static const String container = 'icons/inspector/widget_icons/container.png';
  static const String center = 'icons/inspector/widget_icons/center.png';
  static const String row = 'icons/inspector/widget_icons/row.png';
  static const String column = 'icons/inspector/widget_icons/column.png';
  static const String padding = 'icons/inspector/widget_icons/padding.png';
  static const String scaffold = 'icons/inspector/widget_icons/scaffold.png';
  static const String sizedBox = 'icons/inspector/widget_icons/sizedbox.png';
  static const String align = 'icons/inspector/widget_icons/align.png';
  static const String scroll = 'icons/inspector/widget_icons/scroll.png';
  static const String stack = 'icons/inspector/widget_icons/stack.png';
  static const String inkWell = 'icons/inspector/widget_icons/inkwell.png';
  static const String gesture = 'icons/inspector/widget_icons/gesture.png';
  static const String textButton =
      'icons/inspector/widget_icons/textbutton.png';
  static const String outlinedButton =
      'icons/inspector/widget_icons/outlinedbutton.png';
  static const String gridView = 'icons/inspector/widget_icons/gridview.png';
  static const String listView = 'icons/inspector/widget_icons/listView.png';

  static const String alertDialog =
      'icons/inspector/widget_icons/alertdialog.png';
  static const String card = 'icons/inspector/widget_icons/card.png';
  static const String circleAvatar =
      'icons/inspector/widget_icons/circleavatar.png';
  static const String circularProgress =
      'icons/inspector/widget_icons/circularprogress.png';
  static const String constrainedBox =
      'icons/inspector/widget_icons/constrainedbox.png';
  static const String divider = 'icons/inspector/widget_icons/divider.png';
  static const String drawer = 'icons/inspector/widget_icons/drawer.png';
  static const String expand = 'icons/inspector/widget_icons/expand.png';
  static const String material = 'icons/inspector/widget_icons/material.png';
  static const String opacity = 'icons/inspector/widget_icons/opacity.png';
  static const String tab = 'icons/inspector/widget_icons/tab.png';
  static const String wrap = 'icons/inspector/widget_icons/wrap.png';
  static const String pageView = 'icons/inspector/widget_icons/pageView.png';
  static const String appBar = 'icons/inspector/widget_icons/appbar.png';
  static const String materialApp =
      'icons/inspector/widget_icons/materialapp.png';
  static const String bottomNavigationBar =
      'icons/inspector/widget_icons/bottomnavigationbar.png';
}
