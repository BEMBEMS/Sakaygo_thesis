export const USER_ROLES = ['passenger', 'driver', 'admin', 'lgu', 'toda'] as const;

export type UserRole = (typeof USER_ROLES)[number];

export const ADMIN_ROLES = ['admin', 'lgu', 'toda'] as const;

export type AdminRole = (typeof ADMIN_ROLES)[number];

export function isAdminRole(role: UserRole): role is AdminRole {
  return (ADMIN_ROLES as readonly string[]).includes(role);
}
