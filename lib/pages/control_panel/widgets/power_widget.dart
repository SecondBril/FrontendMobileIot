import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iot_ui_challenge/pages/control_panel/widgets/transparent_card.dart';

class PowerWidget extends StatelessWidget {
  final bool isActive;
  final Function(bool) onChanged;

  const PowerWidget({super.key, required this.isActive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TransparentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Power",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  text: 'OFF',
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 14,
                    color: !isActive ? Colors.white : Colors.grey,
                    fontWeight: !isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                  children: <TextSpan>[
                    TextSpan(text: ' / ', style: TextStyle(color: Colors.grey)),
                    TextSpan(
                      text: 'ON',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                alignment: Alignment.center,
                scaleY: 0.8,
                scaleX: 0.85,
                child: CupertinoSwitch(
                  onChanged: onChanged,
                  value: isActive,
                  activeTrackColor: Colors.white.withValues(alpha: 0.5),
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
