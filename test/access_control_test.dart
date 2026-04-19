import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_032/services/access_control_service.dart';

void main() {
  group('AccessControlService Unit Tests', () {
    group('canPerform (Action Permissions)', () {
      test('Semua role harus bisa melakukan Create', () {
        expect(
          AccessControlService.canPerform(
            AccessControlService.roleAnggota,
            'create',
          ),
          isTrue,
        );
        expect(
          AccessControlService.canPerform(
            AccessControlService.roleKetua,
            'create',
          ),
          isTrue,
        );
      });

      test(
        'Update/Delete hanya boleh dilakukan oleh pemilik (isOwner = true)',
        () {
          // Pemilik boleh update
          expect(
            AccessControlService.canPerform(
              AccessControlService.roleAnggota,
              'update',
              isOwner: true,
            ),
            isTrue,
          );

          // Bukan pemilik tidak boleh update meskipun admin
          expect(
            AccessControlService.canPerform(
              AccessControlService.roleAdmin,
              'update',
              isOwner: false,
            ),
            isFalse,
          );

          // Bukan pemilik tidak boleh delete
          expect(
            AccessControlService.canPerform(
              AccessControlService.roleKetua,
              'delete',
              isOwner: false,
            ),
            isFalse,
          );
        },
      );
    });

    group('canViewLogWithPrivacy (Visibility Logic)', () {
      test(
        'User harus selalu bisa melihat log miliknya sendiri (isSameAuthor = true)',
        () {
          expect(
            AccessControlService.canViewLogWithPrivacy(
              AccessControlService.roleAnggota,
              AccessControlService.roleAdmin,
              true, // isSameAuthor
              false, // privat
            ),
            isTrue,
          );
        },
      );

      test('User lain tidak boleh melihat log jika log tersebut Privat', () {
        expect(
          AccessControlService.canViewLogWithPrivacy(
            AccessControlService.roleAdmin,
            AccessControlService.roleAnggota,
            false, // bukan pemilik
            false, // isLogPublic = false (Privat)
          ),
          isFalse,
        );
      });

      test(
        'Asisten hanya boleh melihat log Anggota meskipun log tersebut Public',
        () {
          // Asisten lihat Anggota (Public) -> Boleh
          expect(
            AccessControlService.canViewLogWithPrivacy(
              AccessControlService.roleAsisten,
              AccessControlService.roleAnggota,
              false,
              true,
            ),
            isTrue,
          );

          // Asisten lihat Ketua (Public) -> Tidak Boleh (Sesuai logika canViewLog kamu)
          expect(
            AccessControlService.canViewLogWithPrivacy(
              AccessControlService.roleAsisten,
              AccessControlService.roleKetua,
              false,
              true,
            ),
            isFalse,
          );
        },
      );
    });

    group('getVisibleRoles (Hierarchy)', () {
      test('Ketua dan Admin harus bisa melihat semua role', () {
        final roles = AccessControlService.getVisibleRoles(
          AccessControlService.roleKetua,
        );
        expect(roles.length, equals(4));
        expect(
          roles,
          containsAll([
            AccessControlService.roleKetua,
            AccessControlService.roleAdmin,
            AccessControlService.roleAsisten,
            AccessControlService.roleAnggota,
          ]),
        );
      });

      test('Asisten hanya boleh melihat role Asisten dan Anggota', () {
        final roles = AccessControlService.getVisibleRoles(
          AccessControlService.roleAsisten,
        );
        expect(
          roles,
          equals([
            AccessControlService.roleAsisten,
            AccessControlService.roleAnggota,
          ]),
        );
      });
    });
  });
}
