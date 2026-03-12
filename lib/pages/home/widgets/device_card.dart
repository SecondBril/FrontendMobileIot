import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iot_ui_challenge/pages/control_panel/panel_kontrol_page.dart';

class DevicesCard extends StatelessWidget {
  final String name;
  final String svg;
  final Color color;
  final bool isActive;
  final Function(bool) onChanged;

  const DevicesCard({
    super.key,
    required this.name,
    required this.svg,
    required this.color,
    required this.onChanged,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 700),
      closedElevation: 0,
      openElevation: 0,
      middleColor: Color(0xFF7739ff),
      openShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      openBuilder: (BuildContext context, VoidCallback _) {
        return ControlPanelPage(tag: name);
      },
      tappable: name == "Smart AC" ? true : false,
      closedBuilder: (BuildContext _, VoidCallback openContainer) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(20.0)),
            border: Border.all(color: Colors.grey[400]!, width: 0.6),
            color: isActive ? color : Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      svg,
                      colorFilter: ColorFilter.mode(
                        isActive ? Colors.white : Colors.black87,
                        BlendMode.srcIn,
                      ),
                      height: 25,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: TextStyle(
                        height: 1.2,
                        fontSize: 15,
                        color: isActive ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Transform.scale(
                  alignment: Alignment.center,
                  scaleY: 0.8,
                  scaleX: 0.85,
                  child: CupertinoSwitch(
                    onChanged: onChanged,
                    value: isActive,
                    activeTrackColor:
                        isActive
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.black,
                    inactiveTrackColor: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
