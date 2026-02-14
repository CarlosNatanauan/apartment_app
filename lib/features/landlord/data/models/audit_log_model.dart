class AuditLog {
  final String id;  // auditId
  final String action;
  final String actorId;
  final String? membershipId;
  final String? roomId;
  final Map<String, dynamic>? meta;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.action,
    required this.actorId,
    this.membershipId,
    this.roomId,
    this.meta,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['auditId'] as String,
      action: json['action'] as String,
      actorId: json['actorId'] as String,
      membershipId: json['membershipId'] as String?,
      roomId: json['roomId'] as String?,
      meta: json['meta'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auditId': id,
      'action': action,
      'actorId': actorId,
      if (membershipId != null) 'membershipId': membershipId,
      if (roomId != null) 'roomId': roomId,
      if (meta != null) 'meta': meta,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper getters for UI
  String get displayAction {
    switch (action) {
      case 'CREATE_SPACE':
        return 'Space Created';
      case 'UPDATE_SPACE':
        return 'Space Updated';
      case 'DELETE_SPACE':
        return 'Space Deleted';
      case 'CREATE_ROOM':
        return 'Room Created';
      case 'DELETE_ROOM':
        return 'Room Deleted';
      case 'JOIN_REQUEST':
        return 'Join Request';
      case 'APPROVE':
        return 'Approved';
      case 'REJECT':
        return 'Rejected';
      case 'MOVE':
        return 'Moved';
      case 'LEAVE':
        return 'Left Space';
      case 'REMOVE_TENANT':
        return 'Tenant Removed';
      default:
        return action.replaceAll('_', ' ');
    }
  }

  String get category {
    if (action.contains('SPACE')) return 'SPACE';
    if (action.contains('ROOM')) return 'ROOM';
    if (action.contains('JOIN') || action.contains('APPROVE') || action.contains('REJECT') || action.contains('MOVE') || action.contains('LEAVE') || action.contains('REMOVE')) {
      return 'MEMBERSHIP';
    }
    return 'OTHER';
  }

  String get details {
    if (meta == null) return '';
    
    switch (action) {
      case 'UPDATE_SPACE':
        return 'Changed from "${meta!['oldName']}" to "${meta!['newName']}"';
      case 'CREATE_ROOM':
        return 'Room ${meta!['roomNumber']}';
      case 'MOVE':
        return 'Room changed';
      case 'APPROVE':
        return 'Status: ${meta!['from']} → ${meta!['to']}';
      case 'CREATE_SPACE':
        return 'Join code: ${meta!['joinCode']}';
      default:
        return '';
    }
  }

  @override
  String toString() => 'AuditLog(id: $id, action: $action, createdAt: $createdAt)';
}