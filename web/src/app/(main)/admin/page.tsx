import { redirect } from "next/navigation";
import { getKpis } from "@/lib/analytics";
import { getSession } from "@/lib/auth";
import { isAdminEmail } from "@/lib/email";

export default async function AdminPage() {
  const user = await getSession();
  if (!user || !isAdminEmail(user.email)) redirect("/");
  const kpis = await getKpis();

  return (
    <main>
      <h1 className="mb-2 text-2xl font-semibold">Usage KPIs</h1>
      <p className="mb-6 text-sm text-stone-600">
        Stored in Neon. Restricted to {user.email}.
      </p>
      <dl className="grid grid-cols-2 gap-3 md:grid-cols-3">
        {Object.entries(kpis.totals).map(([name, count]) => (
          <div key={name} className="rounded-xl bg-white p-4 shadow-sm">
            <dt className="text-sm text-stone-500">{name}</dt>
            <dd className="text-2xl font-semibold">{count}</dd>
          </div>
        ))}
        <div className="rounded-xl bg-white p-4 shadow-sm">
          <dt className="text-sm text-stone-500">unique login users</dt>
          <dd className="text-2xl font-semibold">{kpis.uniqueLoginUsers}</dd>
        </div>
      </dl>
      <h2 className="mb-2 mt-8 text-lg font-semibold">Recent events</h2>
      <div className="overflow-x-auto rounded-xl bg-white shadow-sm">
        <table className="min-w-full text-left text-sm">
          <thead>
            <tr className="border-b">
              <th className="px-3 py-2">When</th>
              <th className="px-3 py-2">Event</th>
              <th className="px-3 py-2">User</th>
            </tr>
          </thead>
          <tbody>
            {kpis.recent.map((event) => (
              <tr key={event.id} className="border-b last:border-0">
                <td className="px-3 py-2 whitespace-nowrap">
                  {event.createdAt.toISOString().replace("T", " ").slice(0, 19)}
                </td>
                <td className="px-3 py-2">{event.name}</td>
                <td className="px-3 py-2">{event.userEmail ?? "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </main>
  );
}
