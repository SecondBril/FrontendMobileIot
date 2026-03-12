import 'package:flutter/material.dart';
import 'package:iot_ui_challenge/model/device_model.dart';
import 'package:iot_ui_challenge/pages/home/widgets/device_card.dart';

class DeviceGridView extends StatefulWidget {
  const DeviceGridView({super.key});

  @override
  State<DeviceGridView> createState() => _DeviceGridViewState();
}

class _DeviceGridViewState extends State<DeviceGridView> {
  List<DeviceModel> devices = [
    DeviceModel(
      name: 'Smart Spotlight',
      isActive: true,
      color: Color(0xFFff5f5f),

      icon: 'assets/svg/light.svg',
    ),
    DeviceModel(
      name: 'Smart AC',
      isActive: true,
      color: Color(0xFF7739ff),
      icon: 'assets/svg/ac.svg',
    ),
    DeviceModel(
      name: 'Smart TV',
      isActive: false,
      color: Color(0xFFc9c306),
      icon: 'assets/svg/tv.svg',
    ),
    DeviceModel(
      name: 'Smart Sound',
      isActive: false,
      color: Color(0xFFc207db),
      icon: 'assets/svg/speaker.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 20),

        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 3 / 4,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: devices.length,
        itemBuilder: (BuildContext ctx, index) {
          return DevicesCard(
            name: devices[index].name!,
            svg: devices[index].icon!,
            color: devices[index].color!,
            isActive: devices[index].isActive,
            onChanged: (val) {
              setState(() {
                devices[index].isActive = !devices[index].isActive;
              });
            },
          );
        },
      ),
    );
  }
}
