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
    return ColoredBox(
      color: const Color(0xFFFFFCF8),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF0E3DC)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B3C26).withValues(alpha: .10),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isSelected
              ? Palette.terracotta.withValues(alpha: .12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isSelected ? Palette.terracotta : Palette.labelGrey,
          size: 25,
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
          color: _centerPressed ? Palette.terracottaDark : Palette.terracotta,
          boxShadow: [
            BoxShadow(
              color: Palette.terracotta.withValues(alpha: .30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
