"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export function AuthForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [registerMode, setRegisterMode] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const response = await fetch(registerMode ? "/api/auth/register" : "/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = (await response.json()) as { error?: string };
      if (!response.ok) {
        setError(data.error ?? "Something went wrong.");
        return;
      }
      router.push("/");
      router.refresh();
    } catch {
      setError("Network error. Try again.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} className="flex w-full max-w-md flex-col gap-4">
      <label className="flex flex-col gap-1 text-sm">
        Institute email
        <input
          type="email"
          required
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          placeholder="name.pgpex26@iimshillong.ac.in"
          className="rounded-xl border border-stone-300 bg-white px-3 py-2 text-base"
        />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        Password
        <input
          type="password"
          required
          minLength={6}
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          className="rounded-xl border border-stone-300 bg-white px-3 py-2 text-base"
        />
      </label>
      {error ? <p className="text-sm text-red-700">{error}</p> : null}
      <button
        type="submit"
        disabled={busy}
        className="rounded-xl bg-[#7B1E2C] px-4 py-3 font-medium text-white disabled:opacity-60"
      >
        {busy ? "Please wait…" : registerMode ? "Create account" : "Sign in"}
      </button>
      <button
        type="button"
        onClick={() => setRegisterMode((value) => !value)}
        className="text-sm text-[#7B1E2C] underline"
      >
        {registerMode ? "Already have an account? Sign in" : "New student? Create an account"}
      </button>
    </form>
  );
}
