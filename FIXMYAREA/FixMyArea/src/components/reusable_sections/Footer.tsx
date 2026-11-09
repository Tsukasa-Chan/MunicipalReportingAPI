"use client";

import React from "react";
import { Activity, Phone } from 'lucide-react';

import { Link } from "@/components/common/Link";
import { Separator } from "@/components/ui/separator";
import { WvcLogo } from "@/Services/wordpress/WvcLogo";

export default function Footer() {
  return (
    <section
      id="system-footer"
      data-nav="dark"
      className="dark bg-background text-foreground border-t border-border/70 py-12 px-4 md:px-8 font-default"
    >
      <div className="max-w-7xl mx-auto space-y-10">
        {/* Main Footer Matrix */}
        <div className="grid grid-cols-1 md:grid-cols-12 gap-8 lg:gap-12">
          {/* Col 1: Identity & Operations Brief */}
          <div className="md:col-span-4 space-y-4">
            <Link to="/" className="inline-block">
              <WvcLogo className="h-8 w-auto max-w-[140px] object-contain" />
            </Link>
            <p className="text-xs leading-relaxed text-muted-foreground max-w-sm">
              Streamlining community infrastructure issue reporting, tracking, and fast supervisory resolution across civic districts.
            </p>
            <div className="pt-1 text-xs text-muted-foreground space-y-1.5">
              <div className="flex items-center gap-2">
                <Activity className="size-3.5 text-primary" />
                <span>Operating Hours: Mon-Fri 8am - 6pm; Sat 9am - 2pm</span>
              </div>
              <div className="flex items-center gap-2">
                <Phone className="size-3.5 text-primary" />
                <a href="tel:1234567890" className="hover:underline">
                  (123) 456-7890
                </a>
              </div>
            </div>
          </div>
        </div>

        <Separator className="bg-border/60" />

        {/* Bottom Sub-bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-muted-foreground">
          <p>
            {"© "}{new Date().getFullYear()}{" MUNICORE. Infrastructure Reporting System. All rights reserved."}
          </p>

          <div className="flex items-center gap-4 text-[11px]">
            <span className="font-mono text-muted-foreground/80">
              Community City, CC 45678
            </span>
          </div>
        </div>
      </div>
    </section>
  );
}