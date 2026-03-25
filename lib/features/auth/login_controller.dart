class LoginController {
  // User credentials: username -> password
  final Map<String, String> _users = {
    "admin": "123",
    "asisten": "123",
    "anggota": "123",
    "ketua": "123",
  };

  // Username -> Role mapping
  final Map<String, String> _userRoles = {
    "admin": "Admin",
    "asisten": "Asisten",
    "anggota": "Anggota",
    "ketua": "Ketua",
  };

  /// Logika pengecekan login
  bool login(String username, String password) {
    if (_users.containsKey(username) && _users[username] == password) {
      return true;
    }
    return false;
  }

  /// Get role berdasarkan username
  String? getRole(String username) {
    return _userRoles[username];
  }

  /// Get team ID (default TEAM_032)
  String getTeamId() => 'TEAM_032';

  /// Get semua available users untuk testing
  List<String> getAvailableUsers() => _users.keys.toList();
}
