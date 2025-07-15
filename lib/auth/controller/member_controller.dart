import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_wave/auth/auth_firebase.dart';

import '../domain/entities/member.dart';

class MemberState {
  final Member? member;

  const MemberState({this.member});

  MemberState copyWith({required Member member}) {
    return MemberState(member: member);
  }
}

class MemberController extends StateNotifier<MemberState> {
  MemberController(super.state);

  Future<void> refreshMember() async {
    var result = await AuthService().findByCurrentUser();
    print("findResult : ${result}");
    if (result == null) return;
    state = state.copyWith(member: result);
  }
}
