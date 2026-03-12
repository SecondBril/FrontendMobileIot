import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iot_ui_challenge/model/device_options_model.dart';
import 'package:iot_ui_challenge/utils/options_enum.dart';

class DeviceOptionsWidget extends StatelessWidget {
  final void Function(OptionsEnum option) onTap;
  final OptionsEnum selectedOption;

  const DeviceOptionsWidget({
    super.key,
    required this.onTap,
    required this.selectedOption,
  });

  @override
  Widget build(BuildContext context) {
    final deviceOptionsWidget = [
      DeviceOptionsModel(
        icon: 'assets/svg/clock.svg',
        size: 32,
        option: OptionsEnum.timer,
      ),
      DeviceOptionsModel(
        icon: 'assets/svg/snow.svg',
        size: 25,
        option: OptionsEnum.cooling,
      ),
      DeviceOptionsModel(
        icon: 'assets/svg/bright.svg',
        size: 35,
        option: OptionsEnum.heat,
      ),
      DeviceOptionsModel(
        icon: 'assets/svg/drop.svg',
        size: 28,
        option: OptionsEnum.dry,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (var i = 0; i < deviceOptionsWidget.length; i++)
          InkWell(
            onTap: () {
              onTap(deviceOptionsWidget[i].option);
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                color:
                    selectedOption == deviceOptionsWidget[i].option
                        ? Colors.white
                        : Colors.black.withValues(alpha: 0.1),
              ),
              child: Center(
                child: SvgPicture.asset(
                  deviceOptionsWidget[i].icon,
                  colorFilter: ColorFilter.mode(
                    selectedOption == deviceOptionsWidget[i].option
                        ? Colors.black
                        : Colors.white,
                    BlendMode.srcIn,
                  ),
                  width: deviceOptionsWidget[i].size,
                  height: deviceOptionsWidget[i].size,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
