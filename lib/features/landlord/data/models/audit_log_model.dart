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
        return 'Unit Created';
      case 'DELETE_ROOM':
        return 'Unit Deleted';
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
      case 'ROOM_REQUEST':
        return 'Unit Request';
      case 'LEASE_APPROVE':
        return 'Lease Approved';
      case 'LEASE_REJECT':
        return 'Lease Rejected';
      case 'LEASE_END_LANDLORD':
        return 'Lease Ended by Landlord';
      case 'LEASE_END_TENANT':
        return 'Lease Ended by Tenant';
      case 'CREATE_MAINTENANCE':
        return 'Maintenance Request';
      case 'CANCEL_MAINTENANCE':
        return 'Request Cancelled';
      case 'UPDATE_MAINTENANCE_STATUS':
        return 'Status Updated';
      default:
        return action.replaceAll('_', ' ');
    }
  }

  String get category {
    if (action.contains('MAINTENANCE')) return 'MAINTENANCE';
    if (action.contains('SPACE')) return 'SPACE';
    if (action == 'CREATE_ROOM' || action == 'DELETE_ROOM') return 'UNIT';
    return 'MEMBERSHIP';
  }

  String get details {
    if (meta == null) return '';

    switch (action) {
      case 'UPDATE_SPACE':
        return 'Changed from "${meta!['oldName']}" to "${meta!['newName']}"';
      case 'CREATE_ROOM':
        return 'Unit ${meta!['roomNumber']}';
      case 'MOVE':
        return 'Unit changed';
      case 'APPROVE':
        return 'Status: ${meta!['from']} → ${meta!['to']}';
      case 'LEASE_APPROVE':
        return 'Status: ${meta!['from']} → ${meta!['to']}';
      case 'CREATE_SPACE':
        return 'Join code: ${meta!['joinCode']}';
      case 'CREATE_MAINTENANCE':
        return meta!['title'] as String? ?? '';
      case 'UPDATE_MAINTENANCE_STATUS':
        return 'Status: ${meta!['from']} → ${meta!['to']}';
      default:
        return '';
    }
  }

  @override
  String toString() => 'AuditLog(id: $id, action: $action, createdAt: $createdAt)';
}