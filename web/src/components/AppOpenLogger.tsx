"use client";

import { useEffect } from "react";

export function AppOpenLogger() {
  useEffect(() => {
    void fetch("/api/analytics", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ phase: "app_open" }),
    });
  }, []);
  return null;
}
