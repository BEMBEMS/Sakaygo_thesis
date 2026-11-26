import { z } from 'zod';

const usernameSchema = z
  .string()
  .trim()
  .min(3)
  .max(50)
  .regex(/^[A-Za-z0-9_.-]+$/, 'Username contains unsupported characters');

const passwordSchema = z.string().min(8).max(128);
const nameSchema = z.string().trim().min(1).max(100);
const optionalEmailSchema = z.string().email().max(200).nullable().optional();
const optionalPhoneSchema = z
  .string()
  .trim()
  .min(7)
  .max(20)
  .nullable()
  .optional();

export const passengerRegistrationSchema = z
  .object({
    username: usernameSchema,
    password: passwordSchema,
    firstName: nameSchema,
    lastName: nameSchema,
    email: optionalEmailSchema,
    phoneNumber: optionalPhoneSchema,
    passengerClass: z.enum(['standard', 'priority']).default('standard'),
  })
  .strict();

export const driverRegistrationSchema = z
  .object({
    username: usernameSchema,
    password: passwordSchema,
    firstName: nameSchema,
    lastName: nameSchema,
    email: optionalEmailSchema,
    phoneNumber: optionalPhoneSchema,
    todaOrgId: z.string().uuid(),
    licenseNumber: z.string().trim().min(5).max(100),
    todaMembershipId: z.string().trim().min(3).max(100),
    vehiclePlateNumber: z.string().trim().min(3).max(30),
  })
  .strict();

export const loginSchema = z
  .object({
    identifier: z.string().trim().min(1).max(200),
    password: z.string().min(1).max(128),
  })
  .strict();

export const locationValidationSchema = z
  .object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
  })
  .strict();

export type PassengerRegistrationPayload = z.infer<
  typeof passengerRegistrationSchema
>;
export type DriverRegistrationPayload = z.infer<
  typeof driverRegistrationSchema
>;
export type LoginPayload = z.infer<typeof loginSchema>;
export type LocationValidationPayload = z.infer<
  typeof locationValidationSchema
>;
