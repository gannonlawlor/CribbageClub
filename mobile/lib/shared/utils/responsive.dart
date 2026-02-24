import 'package:flutter/widgets.dart';

enum DeviceLayout { phone, tabletPortrait, tabletLandscape }

class Responsive {
  static const double _tabletBreakpoint = 600.0;

  static DeviceLayout of(BuildContext context) {
    final data = MediaQuery.of(context);
    final shortestSide = data.size.shortestSide;
    if (shortestSide < _tabletBreakpoint) return DeviceLayout.phone;
    return data.orientation == Orientation.landscape
        ? DeviceLayout.tabletLandscape
        : DeviceLayout.tabletPortrait;
  }

  static bool isTabletLandscape(BuildContext context) =>
      of(context) == DeviceLayout.tabletLandscape;

  static bool isTabletDevice(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= _tabletBreakpoint;
}
