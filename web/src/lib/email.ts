import { ALLOWED_EMAIL_DOMAIN } from "./constants";

export function normalizeEmail(email: string) {
  return email.trim().toLowerCase();
}

export function isInstituteEmail(email: string) {
  const normalized = normalizeEmail(email);
  const [local, domain] = normalized.split("@");
  return Boolean(local) && domain === ALLOWED_EMAIL_DOMAIN;
}

export function adminEmails() {
  return (process.env.ADMIN_EMAILS ?? "shubham.pgpex26@iimshillong.ac.in")
    .split(",")
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean);
}

export function isAdminEmail(email: string) {
  return adminEmails().includes(normalizeEmail(email));
}
