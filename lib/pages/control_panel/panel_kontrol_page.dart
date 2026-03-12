import 'package:flutter/material.dart';
import 'package:iot_ui_challenge/pages/control_panel/widgets/device_options_widget.dart';
import 'package:iot_ui_challenge/utils/options_enum.dart';
import 'package:iot_ui_challenge/pages/control_panel/widgets/power_widget.dart';
import 'package:iot_ui_challenge/pages/control_panel/widgets/slider/slider_widget.dart';
import 'package:iot_ui_challenge/pages/control_panel/widgets/speed_widget.dart';
import 'package:iot_ui_challenge/pages/control_panel/widgets/temp_widget.dart';
import 'package:iot_ui_challenge/utils/slider_utils.dart';
import 'package:iot_ui_challenge/pages/control_panel/widgets/custom_appbar.dart';
import 'package:rainbow_color/rainbow_color.dart';
import 'package:snow_fall_animation/snow_fall_animation.dart';

class ControlPanelPage extends StatefulWidget {
  final String tag;

  const ControlPanelPage({super.key, required this.tag});
  @override
  _ControlPanelPageState createState() => _ControlPanelPageState();
}

class _ControlPanelPageState extends State<ControlPanelPage>
    with TickerProviderStateMixin {
  OptionsEnum option = OptionsEnum.cooling;
  bool isDeviceActive = false;
  int speed = 1;
  double temp = 22.85;
  double progressVal = 0.49;

  var activeColor = Rainbow(
    spectrum: [
      const Color(0xFF33C0BA),
      const Color(0xFF1086D4),
      const Color(0xFF6D04E2),
      const Color(0xFFC421A0),
      const Color(0xFFE4262F),
    ],
    rangeStart: 0.0,
    rangeEnd: 1.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.white,
                  activeColor[progressVal].withValues(alpha: 0.5),
                  activeColor[progressVal],
                ],
              ),
            ),
          ),

          isDeviceActive
              ? SnowFallAnimation(
                config: SnowfallConfig(
                  numberOfSnowflakes: 100,
                  speed: speed.toDouble(),
                  useEmoji: true,
                  holdSnowAtBottom: false,
                  windForce: 2,
                  swingRange: 1,
                  snowColor: Colors.white54,
                  maxOpacity: 0.8,
                  minOpacity: 0.2,
                  minSnowflakeSize: 5,
                  maxSnowflakeSize: 10,
                  cleanupDuration: Duration(milliseconds: 500),
                  customEmojis: ["❆"],
                ),
              )
              : const SizedBox(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
              child: Column(
                children: [
                  const CustomAppBar(title: "Smart AC"),
                  const SizedBox(height: 25),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DeviceOptionsWidget(
                          onTap:
                              (d) => setState(() {
                                option = d;
                              }),
                          selectedOption: option,
                        ),
                        SliderWidget(
                          progressVal: progressVal,
                          color: activeColor[progressVal],
                          onChange: (value) {
                            setState(() {
                              temp = value;
                              progressVal = normalize(
                                value,
                                kMinDegree,
                                kMaxDegree,
                              );
                            });
                          },
                        ),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: SpeedWidget(
                                    speed: speed,
                                    changeSpeed:
                                        (val) => setState(() {
                                          speed = val;
                                        }),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: PowerWidget(
                                    isActive: isDeviceActive,
                                    onChanged:
                                        (val) => setState(() {
                                          isDeviceActive = val;
                                        }),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            TempWidget(
                              temp: temp,
                              changeTemp:
                                  (val) => setState(() {
                                    temp = val;
                                    progressVal = normalize(
                                      val,
                                      kMinDegree,
                                      kMaxDegree,
                                    );
                                  }),
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
