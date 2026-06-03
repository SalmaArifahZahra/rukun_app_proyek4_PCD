import 'package:flutter_test/flutter_test.dart';
import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';
import 'package:rukun_app_proyek4/views/pages/surat/utils/surat_permission.dart';

void main() {
  group('BUG-015: Surat permission for RW', () {
    test('RW can act on diajukan surat', () {
      final perm = SuratPermission(UserRole.rw, SuratStatus.diajukan);

      expect(perm.canAct, true, reason: 'RW should be able to act on diajukan');
      expect(perm.isReadOnly, false, reason: 'RW should not be read-only on diajukan');
    });

    test('RW can act on disetujui surat', () {
      final perm = SuratPermission(UserRole.rw, SuratStatus.disetujui);

      expect(perm.canAct, true, reason: 'RW should be able to act on disetujui');
      expect(perm.isReadOnly, false, reason: 'RW should not be read-only on disetujui');
    });

    test('RW cannot act on selesai surat', () {
      final perm = SuratPermission(UserRole.rw, SuratStatus.selesai);

      expect(perm.canAct, false, reason: 'RW should not be able to act on selesai');
      expect(perm.isReadOnly, true, reason: 'RW should be read-only on selesai');
    });

    test('RW cannot act on ditolak surat', () {
      final perm = SuratPermission(UserRole.rw, SuratStatus.ditolak);

      expect(perm.canAct, false, reason: 'RW should not be able to act on ditolak');
      expect(perm.isReadOnly, true, reason: 'RW should be read-only on ditolak');
    });

    test('RW can upload signed on disetujui', () {
      final perm = SuratPermission(UserRole.rw, SuratStatus.disetujui);

      expect(perm.canUploadSigned, true);
    });

    test('RW cannot upload draft', () {
      final perm = SuratPermission(UserRole.rw, SuratStatus.diajukan);

      expect(perm.canUploadDraft, false, reason: 'Only RT can upload draft');
    });
  });

  group('Surat permission for RT', () {
    test('RT can act on diajukan surat', () {
      final perm = SuratPermission(UserRole.rt, SuratStatus.diajukan);

      expect(perm.canAct, true, reason: 'RT should be able to act on diajukan');
      expect(perm.isReadOnly, false, reason: 'RT should not be read-only on diajukan');
    });

    test('RT cannot act on disetujui surat', () {
      final perm = SuratPermission(UserRole.rt, SuratStatus.disetujui);

      expect(perm.canAct, false, reason: 'RT should not be able to act on disetujui');
      expect(perm.isReadOnly, true, reason: 'RT should be read-only on disetujui');
    });

    test('RT cannot act on selesai surat', () {
      final perm = SuratPermission(UserRole.rt, SuratStatus.selesai);

      expect(perm.canAct, false, reason: 'RT should not be able to act on selesai');
      expect(perm.isReadOnly, true, reason: 'RT should be read-only on selesai');
    });

    test('RT can upload draft on diajukan', () {
      final perm = SuratPermission(UserRole.rt, SuratStatus.diajukan);

      expect(perm.canUploadDraft, true);
    });

    test('RT cannot upload signed', () {
      final perm = SuratPermission(UserRole.rt, SuratStatus.disetujui);

      expect(perm.canUploadSigned, false, reason: 'Only RW can upload signed');
    });
  });

  group('isReadOnly consistency with canAct', () {
    test('isReadOnly is always opposite of canAct (except selesai)', () {
      final scenarios = [
        (UserRole.rt, SuratStatus.diajukan),
        (UserRole.rt, SuratStatus.disetujui),
        (UserRole.rt, SuratStatus.ditolak),
        (UserRole.rw, SuratStatus.diajukan),
        (UserRole.rw, SuratStatus.disetujui),
        (UserRole.rw, SuratStatus.ditolak),
      ];

      for (final (role, status) in scenarios) {
        final perm = SuratPermission(role, status);
        expect(
          perm.isReadOnly,
          !perm.canAct,
          reason: '$role + ${status.name}: isReadOnly should be !canAct',
        );
      }
    });

    test('selesai is always read-only regardless of role', () {
      final rt = SuratPermission(UserRole.rt, SuratStatus.selesai);
      final rw = SuratPermission(UserRole.rw, SuratStatus.selesai);

      expect(rt.isReadOnly, true);
      expect(rw.isReadOnly, true);
      expect(rt.canAct, false);
      expect(rw.canAct, false);
    });
  });
}
