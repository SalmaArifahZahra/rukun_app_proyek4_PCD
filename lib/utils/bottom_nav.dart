import "package:curved_navigation_bar/curved_navigation_bar.dart";
import "package:flutter/material.dart";
import 'package:rukun_app_proyek4/viewmodels/nav_viewmodel.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';

class BottomNav extends StatefulWidget {
  final List<NavItem> items;

  const BottomNav({super.key, required this.items});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      extendBody: true,
      body: widget.items[_page].page,

      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: ColorsUtils.b200,
        color: ColorsUtils.b500,
        animationDuration: const Duration(milliseconds: 300),

        items: widget.items
            .map((e) => Icon(e.icon, size: 26, color: ColorsUtils.white))
            .toList(),

        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
      ),
    );
  }
}
