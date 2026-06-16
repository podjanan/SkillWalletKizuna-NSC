import 'package:flutter/material.dart';
import '../theme/palette.dart';

class MainBottomNav extends StatefulWidget {
  const MainBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> {
  bool _centerPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: Palette.skyGradient,
        boxShadow: Palette.buttonShadow,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconButton(index: 0, icon: Icons.home_rounded),
              _buildCenterPlus(),
              _buildIconButton(index: 2, icon: Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({required int index, required IconData icon}) {
    final bool isSelected = widget.selectedIndex == index;
    return GestureDetector(
      onTap: () => widget.onTabSelected(index),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? Palette.yellow : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCenterPlus() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _centerPressed = true),
      onTapUp: (_) {
        setState(() => _centerPressed = false);
        widget.onTabSelected(1);
      },
      onTapCancel: () => setState(() => _centerPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _centerPressed ? Palette.skyDark : Colors.transparent,
          boxShadow: _centerPressed ? Palette.buttonShadow : null,
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
