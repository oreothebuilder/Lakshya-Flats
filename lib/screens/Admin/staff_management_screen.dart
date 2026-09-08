export 'staff_screen.dart';

import 'package:flutter/material.dart';
import '../../models/user_role_model.dart';
import 'staff_screen.dart';

/// Legacy forwarder to [StaffScreen]
class StaffManagementScreen extends StatelessWidget {
  final AppUser? currentUser;

  const StaffManagementScreen({
    super.key,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return StaffScreen(currentUser: currentUser);
  }
}
