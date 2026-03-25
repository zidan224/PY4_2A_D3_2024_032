class AccessControlService {
  // 4 Role System (plus Ketua)
  static const String roleKetua = 'Ketua';
  static const String roleAdmin = 'Admin';
  static const String roleAsisten = 'Asisten';
  static const String roleAnggota = 'Anggota';

  static List<String> get availableRoles => [
    roleKetua,
    roleAdmin,
    roleAsisten,
    roleAnggota,
  ];

  // Action permissions
  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  /// Permission mapping untuk setiap role
  static final Map<String, List<String>> _rolePermissions = {
    roleKetua: [actionCreate, actionRead, actionUpdate, actionDelete],
    roleAdmin: [actionCreate, actionRead, actionUpdate, actionDelete],
    roleAsisten: [actionCreate, actionRead, actionUpdate, actionDelete],
    roleAnggota: [actionCreate, actionRead, actionUpdate, actionDelete],
  };

  /// Cek apakah user bisa perform action pada log
  static bool canPerform(String role, String action, {bool isOwner = false}) {
    final permissions = _rolePermissions[role] ?? [];

    // semua role bisa
    if (action == actionCreate) {
      return permissions.contains(action);
    }

    //HANYA milik sendiri (semua role)
    if (action == actionUpdate || action == actionDelete) {
      return isOwner && permissions.contains(action);
    }

    // Read: sesuai dengan visibility filter
    return permissions.contains(action);
  }

  static bool canViewLogWithPrivacy(
    String viewerRole,
    String authorRole,
    bool isSameAuthor,
    bool isLogPublic,
  ) {
    if (isSameAuthor) return true;

    if (!isLogPublic && !isSameAuthor) return false;

    return canViewLog(viewerRole, authorRole, false);
  }

  /// Cek apakah user bisa VIEW log milik author lain
  static bool canViewLog(
    String viewerRole,
    String authorRole,
    bool isSameAuthor,
  ) {
    if (isSameAuthor) return true;

    // Ketika log sudah Public:
    // - Anggota dan Ketua dapat melihat semua
    // - Asisten tetap hanya dapat melihat log Anggota (optional)
    // - Admin dijadikan setara dengan Ketua jika digunakan
    if (viewerRole == roleAnggota ||
        viewerRole == roleKetua ||
        viewerRole == roleAdmin) {
      return true;
    }

    if (viewerRole == roleAsisten) {
      return authorRole == roleAnggota;
    }

    return false;
  }

  /// Get role hierarchy untuk filtering
  static List<String> getVisibleRoles(String userRole) {
    switch (userRole) {
      case roleKetua:
      case roleAdmin:
        return [
          roleKetua,
          roleAdmin,
          roleAsisten,
          roleAnggota,
        ]; // Ketua/Admin lihat semua
      case roleAsisten:
        return [roleAsisten, roleAnggota]; // Asisten lihat sendiri + anggota
      case roleAnggota:
        return [
          roleKetua,
          roleAdmin,
          roleAsisten,
          roleAnggota,
        ]; // Anggota lihat semua
      default:
        return [roleAnggota];
    }
  }
}
