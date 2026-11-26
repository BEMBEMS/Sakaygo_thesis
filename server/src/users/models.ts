import type { UserRole } from '../users/roles.js';

export type VerificationStatus =
  | 'unverified'
  | 'pending'
  | 'verified'
  | 'rejected'
  | 'restricted';

export interface AuthUser {
  userId: string;
  username: string;
  email: string | null;
  phoneNumber: string | null;
  role: UserRole;
  firstName: string;
  lastName: string;
  isActive: boolean;
  verificationStatus: VerificationStatus | null;
  passengerId: string | null;
  driverId: string | null;
  todaOrgId: string | null;
  operatingZoneId: string | null;
}

export interface PassengerProfile {
  passengerId: string;
  passengerClass: 'standard' | 'priority';
  currentLatitude: number | null;
  currentLongitude: number | null;
}

export interface DriverProfile {
  driverId: string;
  todaOrgId: string;
  operatingZoneId: string | null;
  licenseNumber: string;
  todaMembershipId: string;
  vehiclePlateNumber: string;
  verificationStatus: VerificationStatus;
  driverStatus: 'offline' | 'available' | 'onboard' | 'unavailable';
}

export interface TodaOption {
  todaId: string;
  code: string;
  name: string;
  serviceAreaName: string;
  zoneCode: string | null;
}

export interface ZoneSummary {
  zoneId: string;
  code: string;
  name: string;
  todaOrgId: string | null;
  zoneStatus: 'active' | 'inactive';
  coverageDescription: string;
  geojsonSource: string;
  hasBoundary: boolean;
  allowCrossZone: boolean;
}
