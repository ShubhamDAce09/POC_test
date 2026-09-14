import Link from "next/link";
import { redirect } from "next/navigation";
import { AppOpenLogger } from "@/components/AppOpenLogger";
import { getSession } from "@/lib/auth";
import { isAdminEmail } from "@/lib/email";

async function logout() {
  "use server";
  const { clearSessionCookie } = await import("@/lib/auth");
  await clearSessionCookie();
  redirect("/login");
}

export default async function MainLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await getSession();
  if (!user) redirect("/login");

  return (
    <div className="min-h-full bg-[#F7F3EC] text-[#1F1A17]">
      <AppOpenLogger />
      <header className="bg-[#7B1E2C] text-white">
        <div className="mx-auto flex max-w-5xl flex-wrap items-center justify-between gap-3 px-6 py-4">
          <Link href="/" className="font-semibold">
            IIM Shillong Timetable
          </Link>
          <nav className="flex flex-wrap items-center gap-4 text-sm">
            <Link href="/timetable">My timetable</Link>
            <Link href="/electives">Electives</Link>
            <Link href="/upload">Office file</Link>
            {isAdminEmail(user.email) ? <Link href="/admin">Usage KPIs</Link> : null}
            <span className="opacity-80">{user.email}</span>
            <form action={logout}>
              <button type="submit" className="underline">
                Sign out
              </button>
            </form>
          </nav>
        </div>
      </header>
      <div className="mx-auto w-full max-w-5xl px-6 py-8">{children}</div>
    </div>
  );
}
