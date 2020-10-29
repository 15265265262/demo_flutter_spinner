import 'package:flutter/material.dart';

class SizeLayoutDelegate extends SingleChildLayoutDelegate {
  final Size size;
  SizeLayoutDelegate(this.size);

  @override
  Size getSize(BoxConstraints constraints) => size;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.tight(size);
  }

  @override
  bool shouldRelayout(SizeLayoutDelegate oldDelegate) {
    return size != oldDelegate.size;
  }
}
