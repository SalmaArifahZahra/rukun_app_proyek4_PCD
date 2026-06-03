import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';

enum UserRole { rt, rw }

class SuratPermission {
  final UserRole role;
  final SuratStatus status;

  SuratPermission(this.role, this.status);

  bool get canUploadDraft =>
      role == UserRole.rt && status == SuratStatus.diajukan;

  bool get canUploadSigned =>
      role == UserRole.rw && status == SuratStatus.disetujui;

  bool get canAct {
    if (role == UserRole.rt && status == SuratStatus.diajukan) {
      return true;
    }

    if (role == UserRole.rw &&
        (status == SuratStatus.diajukan ||
            status == SuratStatus.disetujui)) {
      return true;
    }

    return false;
  }

  bool get canViewDetail {
    return status != SuratStatus.diajukan ||
        role == UserRole.rt ||
        role == UserRole.rw;
  }

  bool get showButton {
    return canAct || canViewDetail;
  }

  bool get canOpenModal => canAct || status == SuratStatus.selesai;

  bool get isReadOnly => status == SuratStatus.selesai || !canAct;
}
