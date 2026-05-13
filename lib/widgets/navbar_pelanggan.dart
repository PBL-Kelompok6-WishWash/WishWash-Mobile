import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color cyan = Color(0xFF42C6D4);
    const Color greyText = Color(0xFF7A8D9C);

    return BottomAppBar(
      padding: EdgeInsets.zero,
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      elevation: 20,
      child: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_filled,
              label: 'Home',
              index: 0,
              currentIndex: currentIndex,
              onTap: onTap,
              cyan: cyan,
              greyText: greyText,
            ),

            _buildNavItem(
              icon: Icons.receipt_long,
              label: 'Orders',
              index: 1,
              currentIndex: currentIndex,
              onTap: onTap,
              cyan: cyan,
              greyText: greyText,
            ),

            const SizedBox(width: 50),

            _buildNavItem(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              index: 2,
              currentIndex: currentIndex,
              onTap: onTap,
              cyan: cyan,
              greyText: greyText,
            ),

            _buildNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              index: 3,
              currentIndex: currentIndex,
              onTap: onTap,
              cyan: cyan,
              greyText: greyText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required Function(int) onTap,
    required Color cyan,
    required Color greyText,
  }) {
    final bool isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? cyan : greyText.withOpacity(0.5),
            size: 26,
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? cyan : greyText.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
