class CreateEmailResponse {
  final String message;

  CreateEmailResponse({required this.message});

  factory CreateEmailResponse.fromJson(Map<String, dynamic> json) {
    return CreateEmailResponse(message: json['message'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'message': message};
  }
}
