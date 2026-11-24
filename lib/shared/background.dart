import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  static final Map<String,Image> _images = {
    'background': Image.asset('assets/images/background.png', fit: BoxFit.cover,),
    'pillar' : Image.asset('assets/images/pillar.png', fit: BoxFit.cover,)
  };

  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _images['background']!,
        ),
        Row(
          mainAxisAlignment: .spaceBetween,
          crossAxisAlignment: .stretch,
          children: [
            Flexible(
              flex: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                ),
                child: _images['pillar'],
              ),
            ),
            Flexible(
              flex: 1,
              child: Transform.flip(
                flipX: true,
                flipY: false,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 400
                  ),
                  child: _images['pillar'],
                ),
              ),
            )
          ],
        )
      ],
    );
  }
}