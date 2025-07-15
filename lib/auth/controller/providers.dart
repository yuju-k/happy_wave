import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'member_controller.dart';

final memberControllerProvider = StateNotifierProvider<MemberController, MemberState>((ref) {
  return MemberController(MemberState());
});
