"use client";

import React, { useEffect, useState } from "react";
import { Bell, CircleCheck as CheckCircle2, ChevronDown, Menu, Plus, RefreshCw, Search, Shield, SlidersHorizontal, X } from 'lucide-react';
import { motion, useReducedMotion } from "framer-motion";
import { Link } from "@/components/common/Link";
import { WvcLogo } from "@/Services/wordpress/WvcLogo";
import {
  MenuProvider,
  useMenu,
  type MenuItem,
} from "@/Services/wordpress/WordPressMenuProvider";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  NavigationMenu,
  NavigationMenuContent,
  NavigationMenuItem,
  NavigationMenuLink,
  NavigationMenuList,
  NavigationMenuTrigger,
} from "@/components/ui/navigation-menu";

function RecursiveDropdownItems({
  items,
  depth = 0,
}: {
  items: MenuItem[];
  depth?: number;
}) {
  return (
    <ul className={`grid gap-1 ${depth > 0 ? "pl-3 border-l border-border/40 mt-1" : "min-w-[190px] p-2"}`}>
      {items.map((child, i) => (
        <li key={child.id || `child-${depth}-${i}`} data-index={i} className="flex flex-col">
          <NavigationMenuLink asChild>
            <Link
              to={child.href || "#"}
              className="px-2.5 py-1.5 text-xs font-medium rounded-md hover:bg-accent hover:text-accent-foreground text-foreground transition-colors"
            >
              {child.label}
            </Link>
          </NavigationMenuLink>
          {child.children && child.children.length > 0 && (
            <RecursiveDropdownItems items={child.children} depth={depth + 1} />
          )}
        </li>
      ))}
    </ul>
  );
}

function HeaderMenuConsumer() {
  const { menuItems, loading } = useMenu();

  if (loading) {
    return (
      <div className="flex items-center gap-2">
        <div className="h-8 w-16 bg-muted/30 animate-pulse rounded-md" />
        <div className="h-8 w-20 bg-muted/30 animate-pulse rounded-md" />
        <div className="h-8 w-16 bg-muted/30 animate-pulse rounded-md" />
      </div>
    );
  }

  return (
    <NavigationMenu viewport={false}>
      <NavigationMenuList className="gap-1">
        {menuItems.map((item, i) => (
          <NavigationMenuItem key={item.id || `nav-${i}`} data-index={i}>
            {item.children && item.children.length > 0 ? (
              <>
                <NavigationMenuTrigger className="h-8 px-3 text-xs uppercase tracking-wider font-semibold text-secondary-foreground bg-transparent hover:bg-sidebar-accent hover:text-secondary-foreground focus:bg-sidebar-accent data-[state=open]:bg-sidebar-accent">
                  {item.label}
                </NavigationMenuTrigger>
                <NavigationMenuContent className="bg-popover text-popover-foreground shadow-lg border border-border rounded-lg">
                  <RecursiveDropdownItems items={item.children} />
                </NavigationMenuContent>
              </>
            ) : (
              <NavigationMenuLink asChild>
                <Link
                  to={item.href || "#"}
                  className="inline-flex h-8 items-center px-3 text-xs uppercase tracking-wider font-semibold text-secondary-foreground rounded-md transition-colors hover:bg-sidebar-accent hover:text-secondary-foreground"
                >
                  {item.label}
                </Link>
              </NavigationMenuLink>
            )}
          </NavigationMenuItem>
        ))}
      </NavigationMenuList>
    </NavigationMenu>
  );
}

function MobileRecursiveItems({
  items,
  depth = 0,
  onNavigate,
}: {
  items: MenuItem[];
  depth?: number;
  onNavigate: () => void;
}) {
  return (
    <ul className={`space-y-1 ${depth > 0 ? "pl-4 border-l border-border/40 mt-1" : ""}`}>
      {items.map((child, i) => (
        <li key={child.id || `mob-${depth}-${i}`} data-index={i} className="flex flex-col">
          <Link
            to={child.href || "#"}
            onClick={onNavigate}
            className="px-3 py-2 text-sm rounded-md font-medium text-foreground hover:bg-accent hover:text-accent-foreground transition-colors"
          >
            {child.label}
          </Link>
          {child.children && child.children.length > 0 && (
            <MobileRecursiveItems
              items={child.children}
              depth={depth + 1}
              onNavigate={onNavigate}
            />
          )}
        </li>
      ))}
    </ul>
  );
}

function MobileMenuConsumer({ onClose }: { onClose: () => void }) {
  const { menuItems, loading } = useMenu();

  if (loading) {
    return (
      <div className="space-y-3 py-2">
        <div className="h-8 w-full bg-muted/40 animate-pulse rounded-md" />
        <div className="h-8 w-3/4 bg-muted/40 animate-pulse rounded-md" />
        <div className="h-8 w-4/5 bg-muted/40 animate-pulse rounded-md" />
      </div>
    );
  }

  return (
    <nav className="space-y-1 py-2">
      {menuItems.map((item, i) => (
        <div key={item.id || `mob-item-${i}`} data-index={i} className="space-y-1">
          <Link
            to={item.href || "#"}
            onClick={onClose}
            className="block px-3 py-2 text-sm font-semibold rounded-md text-foreground hover:bg-accent hover:text-accent-foreground transition-colors"
          >
            {item.label}
          </Link>
          {item.children && item.children.length > 0 && (
            <MobileRecursiveItems
              items={item.children}
              depth={1}
              onNavigate={onClose}
            />
          )}
        </div>
      ))}
    </nav>
  );
}

export default function Portal() {
  const [isMobileOpen, setIsMobileOpen] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const shouldReduceMotion = useReducedMotion();

  // Smooth scroll handler for anchor links
  useEffect(() => {
    const handleAnchorClick = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      const anchor = target.closest("a[href]") as HTMLAnchorElement | null;

      if (anchor) {
        const href = anchor.getAttribute("href");
        if (!href) return;

        if (href === "/#") {
          e.preventDefault();
          window.scrollTo({ top: 0, behavior: "smooth" });
          return;
        }

        let hash = "";
        if (href.startsWith("#")) {
          hash = href;
        } else if (href.startsWith("/") && href.includes("#")) {
          const [path, hashPart] = href.split("#");
          if (hashPart === "") {
            e.preventDefault();
            window.scrollTo({ top: 0, behavior: "smooth" });
            return;
          }
          if (path === "/" || path === window.location.pathname) {
            hash = "#" + hashPart;
          }
        }

        if (hash && hash !== "#") {
          const element = document.querySelector(hash);
          if (element) {
            e.preventDefault();
            element.scrollIntoView({ behavior: "smooth", block: "start" });
          }
        }
      }
    };

    document.addEventListener("click", handleAnchorClick);
    return () => document.removeEventListener("click", handleAnchorClick);
  }, []);

  const handleManualSync = () => {
    setIsRefreshing(true);
    setTimeout(() => {
      setIsRefreshing(false);
    }, 700);
  };

  return (
    <section
      id="portal-header"
      data-nav="dark"
      className="dark bg-background text-foreground sticky top-0 z-40 w-full border-b border-sidebar-border bg-sidebar/95 backdrop-blur-md transition-colors"
    >
      <header className="mx-auto flex h-16 max-w-[1560px] items-center justify-between px-4 sm:px-6 lg:px-8">
        {/* Left Section: Logo & Status Badge */}
        <div className="flex items-center gap-3 sm:gap-5">
          <Link
            to="/"
            className="flex items-center gap-2 outline-none focus-visible:ring-2 focus-visible:ring-ring rounded-md"
            aria-label="MUNICORE Homepage"
          >
            <WvcLogo className="h-7 w-auto" />
          </Link>

          <div className="hidden sm:block h-5 w-[1px] bg-sidebar-border" />

          {/* Operational Status Pill */}
          <div className="flex items-center gap-2">
            <Badge
              variant="outline"
              className="bg-sidebar-accent/50 border-sidebar-border text-sidebar-foreground px-2.5 py-1 text-[11px] font-mono tracking-wide flex items-center gap-1.5"
            >
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-chart-2 opacity-75" />
                <span className="relative inline-flex rounded-full h-2 w-2 bg-chart-2" />
              </span>
              <span className="hidden md:inline font-semibold">WARD DISPATCH:</span>
              <span className="text-accent">ONLINE</span>
            </Badge>

            <span className="hidden xl:inline-flex items-center gap-1 text-[11px] font-mono text-secondary-foreground/70 bg-sidebar-accent/30 px-2 py-0.5 rounded border border-sidebar-border/40">
              <CheckCircle2 className="size-3 text-chart-2" />
              {"99.8% SLA"}
            </span>
          </div>
        </div>

        {/* Center Section: Primary Navigation via WordPress Menu */}
        <div className="hidden lg:flex items-center">
          <MenuProvider menu_id="3" className="portal-header-menu">
            <HeaderMenuConsumer />
          </MenuProvider>
        </div>

        {/* Right Section: Quick Action Controls, Sync & Supervisor Profile */}
        <div className="flex items-center gap-2 sm:gap-3">
          {/* Quick Refresh Telemetry Button */}
          <Button
            variant="ghost"
            size="icon"
            onClick={handleManualSync}
            className="text-secondary-foreground hover:bg-sidebar-accent hover:text-secondary-foreground size-8 sm:size-9"
            aria-label="Refresh municipal incident telemetry"
          >
            <RefreshCw
              className={`size-4 ${isRefreshing && !shouldReduceMotion ? "animate-spin" : ""}`}
            />
          </Button>

          {/* System Broadcasts / Notification Indicator */}
          <div className="relative">
            <Button
              variant="ghost"
              size="icon"
              className="text-secondary-foreground hover:bg-sidebar-accent hover:text-secondary-foreground size-8 sm:size-9"
              aria-label="View municipal hazard alerts"
            >
              <Bell className="size-4" />
            </Button>
            <span className="absolute top-1.5 right-1.5 flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-chart-1 opacity-75" />
              <span className="relative inline-flex rounded-full h-2 w-2 bg-chart-1" />
            </span>
          </div>

          {/* Primary Action Button */}
          <Button
            size="sm"
            className="hidden sm:inline-flex rounded-full bg-primary text-primary-foreground font-semibold shadow-sm hover:bg-primary/90 px-3.5 h-8 text-xs gap-1.5 transition-[box-shadow,background-color]"
          >
            <Plus className="size-3.5" />
            <span>New Incident</span>
          </Button>

          {/* Supervisor Context Card / Avatar */}
          <div className="hidden md:flex items-center gap-2.5 pl-2 border-l border-sidebar-border">
            <Avatar className="size-8 border border-sidebar-border ring-1 ring-ring/30">
              <AvatarFallback className="bg-sidebar-accent text-secondary-foreground text-xs font-semibold">
                SD
              </AvatarFallback>
            </Avatar>
            <div className="flex flex-col text-left">
              <div className="flex items-center gap-1">
                <span className="text-xs font-semibold text-secondary-foreground leading-tight">
                  Jane Doe
                </span>
                <Shield className="size-3 text-chart-4" />
              </div>
              <span className="text-[10px] font-mono text-secondary-foreground/70 uppercase leading-none">
                Supervisor
              </span>
            </div>
          </div>

          {/* Mobile Navigation Drawer Toggle */}
          <Button
            variant="ghost"
            size="icon"
            onClick={() => setIsMobileOpen((prev) => !prev)}
            className="lg:hidden text-secondary-foreground hover:bg-sidebar-accent hover:text-secondary-foreground size-8 sm:size-9"
            aria-label="Toggle navigation drawer"
            aria-expanded={isMobileOpen}
          >
            {isMobileOpen ? <X className="size-5" /> : <Menu className="size-5" />}
          </Button>
        </div>
      </header>

      {/* Mobile Accordion Drawer */}
      {isMobileOpen && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: "auto" }}
          exit={{ opacity: 0, height: 0 }}
          transition={{ duration: shouldReduceMotion ? 0.01 : 0.2 }}
          className="lg:hidden border-t border-sidebar-border bg-sidebar px-4 pt-3 pb-6 space-y-4"
        >
          {/* Mobile Profile Banner */}
          <div className="flex items-center justify-between p-3 rounded-lg bg-sidebar-accent/50 border border-sidebar-border">
            <div className="flex items-center gap-3">
              <Avatar className="size-9 border border-sidebar-border">
                <AvatarFallback className="bg-secondary text-secondary-foreground text-xs font-semibold">
                  SD
                </AvatarFallback>
              </Avatar>
              <div>
                <p className="text-xs font-semibold text-secondary-foreground">
                  City Supervisor Jane Doe
                </p>
                <p className="text-[11px] font-mono text-secondary-foreground/70">
                  Wards 1-8 Administration
                </p>
              </div>
            </div>
            <Badge className="bg-chart-2 text-primary-foreground text-[10px] uppercase font-mono">
              Active
            </Badge>
          </div>

          {/* Mobile Navigation Menu */}
          <div className="bg-sidebar-accent/20 rounded-lg p-2 border border-sidebar-border/60">
            <MenuProvider menu_id="3" className="portal-mobile-menu">
              <MobileMenuConsumer onClose={() => setIsMobileOpen(false)} />
            </MenuProvider>
          </div>

          {/* Quick Actions in Mobile Drawer */}
          <div className="pt-2 flex flex-col gap-2">
            <Button
              className="w-full rounded-full bg-primary text-primary-foreground font-semibold shadow-sm hover:bg-primary/90 text-xs h-9 justify-center gap-2"
              onClick={() => setIsMobileOpen(false)}
            >
              <Plus className="size-4" />
              <span>Create Infrastructure Incident</span>
            </Button>

            <div className="flex items-center justify-between px-2 pt-1 text-[11px] font-mono text-secondary-foreground/60">
              <span>MUNICORE Platform v2.4</span>
              <span>123 Civic Avenue</span>
            </div>
          </div>
        </motion.div>
      )}
    </section>
  );
}