"use client";

import React from "react";
import { Search, House as Home, ArrowLeft } from 'lucide-react';
import { Link } from "@/components/common/Link";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

declare const WVC: { homeUrl: string };
declare const wvcClient: { isShop?: () => boolean } | undefined;

export default function NotFound() {
  const homeUrl = typeof WVC !== "undefined" && WVC.homeUrl ? WVC.homeUrl : "/";

  return (
    <section
      id="not-found-template-section"
      data-nav="light"
      className="relative flex min-h-[75vh] items-center justify-center bg-background px-4 py-20 text-foreground sm:px-6 lg:px-8"
    >
      <div className="relative mx-auto flex w-full max-w-2xl flex-col items-center text-center">
        {/* Subtle Decorative Indicator */}
        <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-border bg-card px-4 py-1.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground shadow-2xs">
          <span className="inline-block size-2 rounded-full bg-primary" />
          <span>Error 404</span>
        </div>

        {/* Heading */}
        <h1 className="font-default text-4xl font-bold tracking-tight text-foreground sm:text-5xl lg:text-6xl">
          Page Not Found
        </h1>

        {/* Short Helpful Message */}
        <p className="mt-4 max-w-lg text-base text-muted-foreground sm:text-lg">
          The page you requested could not be found or may have moved. Search our site below or return to the main dashboard.
        </p>

        {/* Native WordPress Search Form */}
        <div className="mt-8 w-full max-w-md">
          <form
            method="get"
            action={homeUrl}
            className="flex flex-col gap-3 sm:flex-row sm:items-center"
          >
            {typeof wvcClient !== "undefined" &&
              typeof wvcClient.isShop === "function" &&
              wvcClient.isShop() && (
                <input type="hidden" name="post_type" value="product" />
              )}

            <div className="relative w-full flex-1">
              <Search
                className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 size-4 text-muted-foreground"
                aria-hidden="true"
              />
              <Input
                type="search"
                name="s"
                placeholder="Search resources, reports..."
                required
                aria-label="Search"
                className="h-11 rounded-lg border-border bg-card pl-10 pr-4 text-card-foreground placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring"
              />
            </div>

            <Button
              type="submit"
              size="lg"
              className="h-11 rounded-lg px-6 font-medium"
            >
              Search
            </Button>
          </form>
        </div>

        {/* Action Link to Home */}
        <div className="mt-8 flex items-center justify-center gap-4">
          <Button
            asChild
            variant="outline"
            className="h-10 gap-2 rounded-lg border-border bg-card px-5 text-card-foreground hover:bg-muted"
          >
            <Link to="/">
              <Home className="size-4" />
              <span>Return Home</span>
            </Link>
          </Button>

          <Button
            asChild
            variant="ghost"
            className="h-10 gap-2 rounded-lg text-foreground hover:bg-muted"
          >
            <Link to="/AdminPortalPage">
              <ArrowLeft className="size-4" />
              <span>Admin Portal</span>
            </Link>
          </Button>
        </div>
      </div>
    </section>
  );
}