import 'package:flutter/material.dart';
import 'package:iot_ui_challenge/pages/control_panel/widgets/transparent_card.dart';

class SpeedWidget extends StatelessWidget {
  final int speed;
  final Function(int) changeSpeed;

  const SpeedWidget({
    super.key,
    required this.speed,
    required this.changeSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return TransparentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Speed",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_button(1), _button(2), _button(3)],
          ),
        ],
      ),
    );
  }

  ElevatedButton _button(int value) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: value == speed ? Colors.black : Colors.white,
        backgroundColor: value == speed ? Colors.white : Colors.transparent,
        minimumSize: const Size(38, 38),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
        elevation: 0,
      ),
      onPressed: () => changeSpeed(value),
      child: Text(value.toString()),
    );
  }
}
