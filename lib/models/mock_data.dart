/// Remaining mock data for Phase 2.
///
/// Only the user profile stays mocked — there's no auth in this phase, so the
/// avatar / name / join year are placeholders. All sleep, alarm, and preference
/// data is now real (Hive + SharedPreferences).
class MockUser {
  final String name;
  final String avatarUrl;
  final int joinedYear;

  const MockUser({
    required this.name,
    required this.avatarUrl,
    required this.joinedYear,
  });
}

const mockUser = MockUser(
  name: 'Alex Carter',
  avatarUrl: 'https://i.pravatar.cc/150?img=12',
  joinedYear: 2023,
);
