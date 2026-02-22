// Enums
enum MaintenanceStatus {
  pending('PENDING'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  final String value;
  const MaintenanceStatus(this.value);

  static MaintenanceStatus fromString(String value) {
    return MaintenanceStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MaintenanceStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case MaintenanceStatus.pending:
        return 'Pending';
      case MaintenanceStatus.inProgress:
        return 'In Progress';
      case MaintenanceStatus.completed:
        return 'Completed';
      case MaintenanceStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum MaintenanceCategory {
  plumbing('PLUMBING', 'Plumbing'),
  electrical('ELECTRICAL', 'Electrical'),
  hvac('HVAC', 'HVAC'),
  appliance('APPLIANCE', 'Appliance'),
  structural('STRUCTURAL', 'Structural'),
  pestControl('PEST_CONTROL', 'Pest Control'),
  cleaning('CLEANING', 'Cleaning'),
  other('OTHER', 'Other');

  final String value;
  final String displayName;
  const MaintenanceCategory(this.value, this.displayName);

  static MaintenanceCategory fromString(String value) {
    return MaintenanceCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MaintenanceCategory.other,
    );
  }
}

// =======================================================
// MODELS
// =======================================================

class MaintenanceRequest {
  final String id;
  final MaintenanceCategory category;
  final String? customCategory;
  final String title;
  final String description;

  /// OLD API (base64 data URL)
  final String? imageData;

  /// NEW API (relative path like "/uploads/maintenance/uuid.jpg")
  final String? imageUrl;

  final MaintenanceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  // Space info
  final String? spaceId;
  final String? spaceName;

  // Room info
  final String? roomId;
  final String? roomNumber;

  // Tenant info (for landlord view)
  final String? tenantId;
  final String? tenantFirstName;
  final String? tenantLastName;
  final String? tenantEmail;

  // Comments
  final int commentCount;

  MaintenanceRequest({
    required this.id,
    required this.category,
    this.customCategory,
    required this.title,
    required this.description,
    this.imageData,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.spaceId,
    this.spaceName,
    this.roomId,
    this.roomNumber,
    this.tenantId,
    this.tenantFirstName,
    this.tenantLastName,
    this.tenantEmail,
    this.commentCount = 0,
  });

  // Computed properties
  String get categoryDisplay {
    if (category == MaintenanceCategory.other && customCategory != null) {
      return customCategory!;
    }
    return category.displayName;
  }

  String? get tenantFullName {
    if (tenantFirstName != null && tenantLastName != null) {
      return '$tenantFirstName $tenantLastName';
    }
    return null;
  }

  bool get isPending => status == MaintenanceStatus.pending;
  bool get isInProgress => status == MaintenanceStatus.inProgress;
  bool get isCompleted => status == MaintenanceStatus.completed;
  bool get isCancelled => status == MaintenanceStatus.cancelled;

  bool get canCancel => status == MaintenanceStatus.pending;

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    // ids
    final requestId = (json['id'] ?? json['requestId']) as String;

    // category (null-safe + default)
    final categoryStr = (json['category'] as String?) ?? 'OTHER';
    final category = MaintenanceCategory.fromString(categoryStr);
    final customCategory = json['customCategory'] as String?;

    // basic
    final title = (json['title'] as String?) ?? '';
    final description = (json['description'] as String?) ?? '';

    // image (support old + new backend)
    final imageData = json['imageData'] as String?;
    final imageUrl = json['imageUrl'] as String?;

    // status
    final statusStr = (json['status'] as String?) ?? 'PENDING';
    final status = MaintenanceStatus.fromString(statusStr);

    // timestamps (updatedAt can be null)
    final createdAt = DateTime.parse(json['createdAt'] as String);
    final updatedAtStr = json['updatedAt'] as String?;
    final updatedAt =
        updatedAtStr != null ? DateTime.parse(updatedAtStr) : createdAt;

    DateTime? resolvedAt;
    final resolvedAtStr = json['resolvedAt'] as String?;
    if (resolvedAtStr != null) {
      resolvedAt = DateTime.parse(resolvedAtStr);
    }

    // space (NEW backend: space.id, old: space.spaceId)
    final space = json['space'] as Map<String, dynamic>?;
    final spaceId = (space?['spaceId'] ?? space?['id']) as String?;
    final spaceName = space?['name'] as String?;

    // room (NEW backend: room.id, old: room.roomId)
    final room = json['room'] as Map<String, dynamic>?;
    final roomId = (room?['roomId'] ?? room?['id']) as String?;
    final roomNumber = room?['roomNumber']?.toString();

    // tenant info
    final tenant = json['tenant'] as Map<String, dynamic>?;
    final tenantId = (tenant?['tenantId'] ?? tenant?['id']) as String?;
    final tenantFirstName = tenant?['firstName'] as String?;
    final tenantLastName = tenant?['lastName'] as String?;
    final tenantEmail = tenant?['email'] as String?;

    // comments
    final commentCount = (json['commentCount'] as int?) ?? 0;

    return MaintenanceRequest(
      id: requestId,
      category: category,
      customCategory: customCategory,
      title: title,
      description: description,
      imageData: imageData,
      imageUrl: imageUrl,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      resolvedAt: resolvedAt,
      spaceId: spaceId,
      spaceName: spaceName,
      roomId: roomId,
      roomNumber: roomNumber,
      tenantId: tenantId,
      tenantFirstName: tenantFirstName,
      tenantLastName: tenantLastName,
      tenantEmail: tenantEmail,
      commentCount: commentCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': id,
      'category': category.value,
      if (customCategory != null) 'customCategory': customCategory,
      'title': title,
      'description': description,
      if (imageData != null) 'imageData': imageData,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
      if (spaceId != null) 'spaceId': spaceId,
      if (spaceName != null) 'spaceName': spaceName,
      if (roomId != null) 'roomId': roomId,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (tenantId != null) 'tenantId': tenantId,
      if (tenantFirstName != null) 'tenantFirstName': tenantFirstName,
      if (tenantLastName != null) 'tenantLastName': tenantLastName,
      if (tenantEmail != null) 'tenantEmail': tenantEmail,
      'commentCount': commentCount,
    };
  }

  @override
  String toString() {
    return 'MaintenanceRequest('
        'id: $id, '
        'category: $categoryDisplay, '
        'title: $title, '
        'status: ${status.displayName}, '
        'space: $spaceName, '
        'room: $roomNumber'
        ')';
  }
}

class MaintenanceComment {
  final String id;
  final String content;
  final DateTime createdAt;
  final CommentAuthor author;

  MaintenanceComment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.author,
  });

  factory MaintenanceComment.fromJson(Map<String, dynamic> json) {
    final commentId = (json['commentId'] ?? json['id']) as String;
    final content = (json['content'] as String?) ?? '';
    final createdAt = DateTime.parse(json['createdAt'] as String);

    final authorJson = (json['author'] as Map<String, dynamic>?) ?? const {};
    final author = CommentAuthor.fromJson(authorJson);

    return MaintenanceComment(
      id: commentId,
      content: content,
      createdAt: createdAt,
      author: author,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'author': author.toJson(),
    };
  }
}

class CommentAuthor {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;

  CommentAuthor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });

  String get fullName => '$firstName $lastName';

  bool get isLandlord => role == 'LANDLORD';
  bool get isTenant => role == 'TENANT';

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    final authorId = (json['authorId'] ?? json['id']) as String? ?? '';
    final firstName = (json['firstName'] as String?) ?? '';
    final lastName = (json['lastName'] as String?) ?? '';
    final email = (json['email'] as String?) ?? '';
    final role = (json['role'] as String?) ?? '';

    return CommentAuthor(
      id: authorId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorId': id,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'role': role,
    };
  }
}

class MaintenanceRequestDetails extends MaintenanceRequest {
  final List<MaintenanceComment> comments;

  MaintenanceRequestDetails({
    required super.id,
    required super.category,
    super.customCategory,
    required super.title,
    required super.description,
    super.imageData,
    super.imageUrl,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.resolvedAt,
    super.spaceId,
    super.spaceName,
    super.roomId,
    super.roomNumber,
    super.tenantId,
    super.tenantFirstName,
    super.tenantLastName,
    super.tenantEmail,
    super.commentCount = 0,
    this.comments = const [],
  });

  factory MaintenanceRequestDetails.fromJson(Map<String, dynamic> json) {
    final baseRequest = MaintenanceRequest.fromJson(json);

    final commentsJson = json['comments'] as List? ?? [];
    final comments = commentsJson
        .map((c) => MaintenanceComment.fromJson(c as Map<String, dynamic>))
        .toList();

    return MaintenanceRequestDetails(
      id: baseRequest.id,
      category: baseRequest.category,
      customCategory: baseRequest.customCategory,
      title: baseRequest.title,
      description: baseRequest.description,
      imageData: baseRequest.imageData,
      imageUrl: baseRequest.imageUrl,
      status: baseRequest.status,
      createdAt: baseRequest.createdAt,
      updatedAt: baseRequest.updatedAt,
      resolvedAt: baseRequest.resolvedAt,
      spaceId: baseRequest.spaceId,
      spaceName: baseRequest.spaceName,
      roomId: baseRequest.roomId,
      roomNumber: baseRequest.roomNumber,
      tenantId: baseRequest.tenantId,
      tenantFirstName: baseRequest.tenantFirstName,
      tenantLastName: baseRequest.tenantLastName,
      tenantEmail: baseRequest.tenantEmail,
      commentCount: comments.length,
      comments: comments,
    );
  }
}