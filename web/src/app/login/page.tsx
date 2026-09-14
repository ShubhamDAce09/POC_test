import { AuthForm } from "@/components/AuthForm";

export default function LoginPage() {
  return (
    <main className="flex min-h-full flex-1 flex-col items-center justify-center bg-[#F7F3EC] px-6 py-16 text-[#1F1A17]">
      <div className="mb-8 max-w-md">
        <p className="text-sm uppercase tracking-wide text-[#7B1E2C]">IIM Shillong</p>
        <h1 className="mt-2 text-3xl font-semibold">Personalized class timetable</h1>
        <p className="mt-3 text-stone-700">
          Sign in with your @iimshillong.ac.in email. Timetables and usage stats are stored in
          Neon and this site deploys on Vercel.
        </p>
      </div>
      <AuthForm />
    </main>
  );
}
