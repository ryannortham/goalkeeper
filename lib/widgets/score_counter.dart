import 'package:flutter/material.dart';
import 'package:customizable_counter/customizable_counter.dart';

class ScoreCounter extends StatefulWidget {
  final String label;
  final int count = 0;
  final bool isGoal;
  final ValueChanged<int> onCountChange;

  const ScoreCounter({
    Key? key,
    required this.label,
    required this.isGoal,
    required this.onCountChange,
  }) : super(key: key);

  @override
  _ScoreCounterState createState() => _ScoreCounterState();
}

class _ScoreCounterState extends State<ScoreCounter> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _count = widget.count;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(
          width: 8,
        ),
        CustomizableCounter(
          backgroundColor: Theme.of(context).inputDecorationTheme.fillColor,
          borderWidth: 2,
          borderRadius: 100,
          textSize: 22,
          count: _count.toDouble(),
          step: 1,
          minCount: 0,
          maxCount: 100,
          incrementIcon: const Icon(
            Icons.add,
          ),
          decrementIcon: const Icon(
            Icons.remove,
          ),
          showButtonText: false,
          onCountChange: (count) {
            setState(() {
              _count = count.toInt();
              widget.onCountChange(_count);
            });
          },
          onIncrement: (count) {},
          onDecrement: (count) {},
        ),
      ],
    );
  }
}