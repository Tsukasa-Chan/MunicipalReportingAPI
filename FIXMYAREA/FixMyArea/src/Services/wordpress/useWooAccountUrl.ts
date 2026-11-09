import { useEffect, useState } from "react";

import { fetchWooUrls } from "@/Services/wordpress/cartUtils";

/** Resolved My Account URL; defaults to /my-account until fetchWooUrls completes. */
export function useWooAccountUrl(): string {
  const [accountUrl, setAccountUrl] = useState("/my-account");

  useEffect(() => {
    let cancelled = false;
    void fetchWooUrls().then((urls) => {
      if (!cancelled && urls.account) {
        setAccountUrl(urls.account);
      }
    });
    return () => {
      cancelled = true;
    };
  }, []);

  return accountUrl;
}
