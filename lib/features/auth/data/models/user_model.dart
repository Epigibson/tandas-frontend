class UserModel {
  final String id;
  final String phone;
  final String? email;
  final String fullName;
  final String? clabe;
  final String? bankName;
  final String? avatarUrl;
  final int tandaScore;
  final int tandasCompleted;
  final int onTimePayments;
  final int latePayments;
  // Se activa a mano en la BD; habilita el panel de administración
  final bool isSuperuser;

  UserModel({
    required this.id,
    required this.phone,
    this.email,
    required this.fullName,
    this.clabe,
    this.bankName,
    this.avatarUrl,
    required this.tandaScore,
    required this.tandasCompleted,
    required this.onTimePayments,
    required this.latePayments,
    this.isSuperuser = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String,
      clabe: json['clabe'] as String?,
      bankName: json['bank_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      tandaScore: (json['tanda_score'] as num?)?.toInt() ?? 100,
      tandasCompleted: (json['tandas_completed'] as num?)?.toInt() ?? 0,
      onTimePayments: (json['on_time_payments'] as num?)?.toInt() ?? 0,
      latePayments: (json['late_payments'] as num?)?.toInt() ?? 0,
      isSuperuser: json['is_superuser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'full_name': fullName,
      'clabe': clabe,
      'bank_name': bankName,
      'avatar_url': avatarUrl,
      'tanda_score': tandaScore,
      'tandas_completed': tandasCompleted,
      'on_time_payments': onTimePayments,
      'late_payments': latePayments,
      'is_superuser': isSuperuser,
    };
  }
}
