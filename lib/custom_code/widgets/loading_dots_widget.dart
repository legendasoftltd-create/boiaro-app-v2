import 'package:flutter/material.dart';

class LoadingDotsWidget extends StatefulWidget {
  final Color? color;
  final double size;

  const LoadingDotsWidget({
    Key? key,
    this.color,
    this.size = 6.0,
  }) : super(key: key);

  @override
  State<LoadingDotsWidget> createState() => _LoadingDotsWidgetState();
}

class _LoadingDotsWidgetState extends State<LoadingDotsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;
    
    return SizedBox(
      height: widget.size * 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: widget.size * 0.5),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(
                    0.3 + (_animations[index].value * 0.7),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

