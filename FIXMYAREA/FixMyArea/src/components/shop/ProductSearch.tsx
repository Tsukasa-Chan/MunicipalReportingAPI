"use client";

import * as React from "react";

import { Input } from "../ui/input";
import { WP_Query } from "@/Services/wordpress/wp_query";

interface ProductsSearchProps {
  value: string;
  onChange: (value: string) => void;
  className?: string;
  placeholder?: string;
}

export function ProductsSearch({
  value,
  onChange,
  className,
  placeholder = "Search products",
}: ProductsSearchProps) {
  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.value);
  };

  return (
    <div className={className}>
      <Input
        type="search"
        value={value}
        onChange={handleChange}
        placeholder={placeholder}
      />
    </div>
  );
}

/**
 * Hook to create a properly configured WP_Query for product search.
 * WordPress uses "s" for search queries. When empty, returns null so
 * EcommerceProductsProvider can stay mounted without issuing a REST request.
 *
 * @param searchValue - The current search input value
 * @returns [wp_query, hasSearchQuery] tuple (like useState)
 */
export function useWPQueryForSearch(searchValue: string): [WP_Query | null, boolean] {
  const term = searchValue.trim();
  const hasSearchQuery = term !== "";

  const wp_query = React.useMemo(
    () => (hasSearchQuery ? new WP_Query({ s: term }) : null),
    [term, hasSearchQuery],
  );

  return [wp_query, hasSearchQuery];
}

/**
 * Build the URL for viewing all product search results.
 * Uses wvcClient.homeUrl() as the base and appends ?s=term&post_type=product.
 */
export function buildProductSearchUrl(searchTerm: string): string {
  const term = searchTerm.trim();
  if (!term) {
    return "";
  }

  const homeUrl =
    typeof wvcClient !== "undefined" &&
    typeof wvcClient.homeUrl === "function"
      ? String(wvcClient.homeUrl())
      : "/";
  const joiner = homeUrl.includes("?") ? "&" : "?";
  return `${homeUrl}${joiner}s=${encodeURIComponent(term)}&post_type=product`;
}
