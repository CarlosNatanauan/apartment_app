class ApiEndpoints {
  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String googleAuth = '/auth/google';
  static const String deleteAccount = '/auth/account';
  static const String updateRole = '/auth/me/role';

  // Spaces
  static const String spaces = '/spaces';
  static const String mySpaces = '/spaces/my';
  static const String joinSpace = '/spaces/join';
  static String spaceDetails(String id) => '/spaces/$id';
  static String updateSpace(String id) => '/spaces/$id';
  static String deleteSpace(String id) => '/spaces/$id';
  static String spaceRequests(String id) => '/spaces/$id/requests';
  static String spaceMembers(String id) => '/spaces/$id/members';
  static String spaceAudit(String id) => '/spaces/$id/audit';

  // Rooms
  static String createRooms(String spaceId) => '/spaces/$spaceId/rooms';
  static String listRooms(String spaceId) => '/spaces/$spaceId/rooms';
  static String updateRoom(String spaceId, String roomId) => 
      '/spaces/$spaceId/rooms/$roomId';
  static String deleteRoom(String spaceId, String roomId) => 
      '/spaces/$spaceId/rooms/$roomId';

  // Memberships
  static const String myMemberships = '/memberships/me';
  static String approveMembership(String id) => '/memberships/$id/approve';
  static String rejectMembership(String id) => '/memberships/$id/reject';
  static String moveMembership(String id) => '/memberships/$id/move';
  static String leaveMembership(String id) => '/memberships/$id/leave';
  static String removeMembership(String id) => '/memberships/$id/remove';

  // 🆕 NEW: Maintenance
  static const String createMaintenance = '/maintenance';
  static const String myMaintenance = '/maintenance/my';
  static String maintenanceDetails(String id) => '/maintenance/$id';
  static String addMaintenanceComment(String id) => '/maintenance/$id/comments';
  static String cancelMaintenance(String id) => '/maintenance/$id/cancel';
  static String spaceMaintenance(String spaceId) => '/spaces/$spaceId/maintenance';
  static String updateMaintenanceStatus(String id) => '/maintenance/$id/status';
}