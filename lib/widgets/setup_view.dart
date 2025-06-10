import 'package:flutter/material.dart';

class SetupViewWidget extends StatelessWidget {
  final Widget prepBlock;
  final Widget workBlock;
  final Widget restBlock;
  final Widget cyclesBlock;
  final Widget setsBlock;

  const SetupViewWidget({
    super.key,
    required this.prepBlock,
    required this.workBlock,
    required this.restBlock,
    required this.cyclesBlock,
    required this.setsBlock,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          prepBlock,
          workBlock,
          restBlock,
          cyclesBlock,
          setsBlock,
        ],
      ),
    );
  }
} 