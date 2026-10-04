import 'package:flutter/material.dart';

enum SidebarMenu { tagihanKoko, dashboard, wallet, saving, deposit, debt, transaction, danaVsTagihan, incomeExpenseDetail, netWorthHistory }

class NavigationProvider with ChangeNotifier {
  SidebarMenu _currentMenu = SidebarMenu.dashboard;
  SidebarMenu get currentMenu => _currentMenu;
  void setMenu(SidebarMenu menu) {
    _currentMenu = menu;
    notifyListeners();
  }
}
