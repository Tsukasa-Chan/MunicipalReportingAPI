"use client";

import React, { useCallback, useEffect, useId, useRef, useState } from "react";
import {
  ShoppingBag,
  ShoppingBasket,
  ShoppingCart,
  type LucideIcon,
} from "lucide-react";
import { cn } from "@/Helpers/utils";
import { Link } from "@/components/common/Link";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import {
  type CartItemCountDisplay,
  type CartItemView,
  type CartLayout,
  type CartView,
  fetchWooUrls,
  fetchCartView,
  shouldShowCartItemCount,
} from "@/Services/wordpress/cartUtils";

declare global {
  interface Window {
    wvcClient: any;
  }
  const wvcClient: any;
}

export type CartIconType = "cart" | "bag" | "basket";

const CART_ICON_MAP: Record<CartIconType, LucideIcon> = {
  cart: ShoppingCart,
  bag: ShoppingBag,
  basket: ShoppingBasket,
};

export interface CartIconProps {
  /** Additional class names for the trigger wrapper */
  className?: string;
  /** Icon size class (e.g., "size-5", "size-6") */
  iconSize?: string;
  /** Lucide cart glyph: cart (default), bag, or basket */
  iconType?: CartIconType;
  /** Button variant (kept for backward compatibility) */
  variant?: "default" | "destructive" | "outline" | "secondary" | "ghost" | "link";
  /** Button size (kept for backward compatibility) */
  size?: "default" | "sm" | "lg" | "icon";
  /** Show loading state on the trigger */
  showLoading?: boolean;
  /** Display the cart total price next to the icon when the cart has items */
  displayTotalPrice?: boolean;
  /** When to show the cart item count badge */
  cartItemCountDisplay?: CartItemCountDisplay;
  /** Overlay layout: full drawer or anchored mini popup */
  cartLayout?: CartLayout;
  /** Open the minicart after a product is added to the cart */
  openDrawerOnAdd?: boolean;
  /** Navigate to checkout on trigger click instead of opening the overlay */
  navigateToCheckoutOnClick?: boolean;
}

const EMPTY_CART: CartView = {
  itemsCount: 0,
  items: [],
  totals: {
    totalItems: 0,
    totalPrice: 0,
    totalDiscount: 0,
    totalTax: 0,
    totalShipping: 0,
    formattedTotalItems: "$0.00",
    formattedTotalPrice: "$0.00",
    currency: {
      code: "USD",
      symbol: "$",
      prefix: "$",
      suffix: "",
      minorUnit: 2,
      decimalSeparator: ".",
      thousandSeparator: ",",
    },
  },
  needsPayment: false,
  needsShipping: false,
};

function CartItemRow({
  item,
  Icon,
}: {
  item: CartItemView;
  Icon: LucideIcon;
}) {
  const content = (
    <>
      <div className="size-14 shrink-0 overflow-hidden rounded-md bg-muted">
        {item.imageSrc ? (
          <img
            src={item.imageSrc}
            alt={item.imageAlt}
            className="size-full object-cover"
          />
        ) : (
          <div className="flex size-full items-center justify-center text-muted-foreground">
            <Icon className="size-5" aria-hidden="true" />
          </div>
        )}
      </div>
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-medium text-foreground">{item.name}</p>
        {item.variations.length > 0 && (
          <p className="mt-0.5 truncate text-xs text-muted-foreground">
            {item.variations
              .map((variation) =>
                variation.value
                  ? `${variation.attribute}: ${variation.value}`
                  : variation.attribute
              )
              .join(", ")}
          </p>
        )}
        <p className="mt-1 text-xs text-muted-foreground">Qty {item.quantity}</p>
      </div>
      <div className="shrink-0 text-sm font-medium text-foreground">
        {item.formattedLineTotal}
      </div>
    </>
  );

  if (!item.permalink) {
    return <div className="flex items-start gap-3 py-3">{content}</div>;
  }

  return (
    <Link
      href={item.permalink}
      className="flex items-start gap-3 py-3 transition-opacity hover:opacity-80"
    >
      {content}
    </Link>
  );
}

function CartPanelContent({
  cart,
  isLoading,
  error,
  cartUrl,
  checkoutUrl,
  Icon,
  onNavigate,
}: {
  cart: CartView;
  isLoading: boolean;
  error: string | null;
  cartUrl: string;
  checkoutUrl: string;
  Icon: LucideIcon;
  onNavigate?: () => void;
}) {
  if (isLoading && cart.items.length === 0) {
    return (
      <div className="flex flex-1 items-center justify-center py-10 text-sm text-muted-foreground">
        Loading cart...
      </div>
    );
  }

  if (error && cart.items.length === 0) {
    return (
      <div className="flex flex-1 items-center justify-center py-10 text-sm text-destructive">
        {error}
      </div>
    );
  }

  if (cart.items.length === 0) {
    return (
      <div className="flex flex-1 flex-col items-center justify-center gap-3 py-10 text-center">
        <Icon className="size-8 text-muted-foreground" aria-hidden="true" />
        <p className="text-sm text-muted-foreground">Your cart is empty</p>
        {cartUrl && cartUrl !== "#" && (
          <Button asChild variant="outline" size="sm" onClick={onNavigate}>
            <Link href={cartUrl}>Browse cart</Link>
          </Button>
        )}
      </div>
    );
  }

  return (
    <>
      <div className="flex-1 overflow-y-auto px-1">
        <ul className="divide-y">
          {cart.items.map((item) => (
            <li key={item.key}>
              <CartItemRow item={item} Icon={Icon} />
            </li>
          ))}
        </ul>
      </div>
      <div className="mt-auto flex flex-col gap-3 border-t pt-4">
        <div className="flex items-center justify-between text-sm">
          <span className="text-muted-foreground">Total</span>
          <span className="font-semibold text-foreground">
            {cart.totals.formattedTotalPrice}
          </span>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <Button asChild variant="outline" className="flex-1" onClick={onNavigate}>
            <Link href={cartUrl}>View cart</Link>
          </Button>
          <Button asChild className="flex-1" onClick={onNavigate}>
            <Link href={checkoutUrl}>Checkout</Link>
          </Button>
        </div>
      </div>
    </>
  );
}

/** Visible height of the WordPress admin bar, or 0 when it is absent. */
function measureWpAdminBar(): number {
  if (typeof document === "undefined") return 0;
  const bar = document.getElementById("wpadminbar");
  if (!bar) return 0;
  const style = window.getComputedStyle(bar);
  if (style.display === "none" || style.visibility === "hidden") return 0;
  return bar.getBoundingClientRect().height;
}

/**
 * CartIcon — shopping cart trigger with read-only minicart (drawer or popup).
 *
 * Features:
 * - Fetches cart via wvcClient.getCart() (full Store API cart incl. items),
 *   the same root-level client the WordPress providers use for wp_query calls.
 *   wvcClient.cart is only the add-to-cart / URLs helper.
 * - Reacts to "wvc_cart_updated" (dispatched by AddToCartButton)
 * - Configurable count badge, total price, layout, and open-on-add behavior
 * - Keeps named export and default usage: <CartIcon variant="ghost" size="icon" />
 *
 * @example
 * ```tsx
 * <CartIcon variant="ghost" size="icon" />
 * <CartIcon iconType="bag" cartLayout="popup" displayTotalPrice openDrawerOnAdd />
 * ```
 */
export function CartIcon({
  className,
  iconSize = "size-4",
  iconType = "cart",
  variant = "ghost",
  size = "icon",
  showLoading = true,
  displayTotalPrice = false,
  cartItemCountDisplay = "only-if-items",
  cartLayout = "drawer",
  openDrawerOnAdd = false,
  navigateToCheckoutOnClick = false,
}: CartIconProps) {
  const titleId = useId();
  const requestIdRef = useRef(0);
  const Icon = CART_ICON_MAP[iconType] ?? ShoppingCart;
  const [cart, setCart] = useState<CartView>(EMPTY_CART);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isOpen, setIsOpen] = useState(false);
  const [cartUrl, setCartUrl] = useState("#");
  const [checkoutUrl, setCheckoutUrl] = useState("#");
  const [openInNewTab, setOpenInNewTab] = useState(false);
  const [wpAdminBarHeight, setWpAdminBarHeight] = useState(0);

  const refreshCart = useCallback(async (flushCache = true) => {
    const requestId = ++requestIdRef.current;
    setIsLoading(true);
    setError(null);
    try {
      const nextCart = await fetchCartView(flushCache);
      if (requestId !== requestIdRef.current) return;
      setCart(nextCart);
    } catch (err) {
      console.error("Failed to fetch cart:", err);
      if (requestId !== requestIdRef.current) return;
      setError("Unable to load cart");
      setCart(EMPTY_CART);
    } finally {
      if (requestId === requestIdRef.current) {
        setIsLoading(false);
      }
    }
  }, []);

  useEffect(() => {
    void refreshCart(true);

    const handleCartUpdate = () => {
      void (async () => {
        await refreshCart(true);
        if (openDrawerOnAdd && !navigateToCheckoutOnClick) {
          setIsOpen(true);
        }
      })();
    };

    document.addEventListener("wvc_cart_updated", handleCartUpdate);
    return () => {
      document.removeEventListener("wvc_cart_updated", handleCartUpdate);
    };
  }, [refreshCart, openDrawerOnAdd, navigateToCheckoutOnClick]);

  useEffect(() => {
    const detectWpAdminBar = () => setWpAdminBarHeight(measureWpAdminBar());

    detectWpAdminBar();
    window.addEventListener("resize", detectWpAdminBar);
    return () => window.removeEventListener("resize", detectWpAdminBar);
  }, []);

  // Refetch from Store API whenever the minicart opens.
  useEffect(() => {
    if (!isOpen || navigateToCheckoutOnClick) return;
    // Re-check admin bar in case it was injected after first paint.
    setWpAdminBarHeight(measureWpAdminBar());
    void refreshCart(true);
  }, [isOpen, navigateToCheckoutOnClick, refreshCart]);

  useEffect(() => {
    async function loadUrls() {
      try {
        const urls = await fetchWooUrls();
        setCartUrl(urls.cart || "#");
        setCheckoutUrl(urls.checkout || "#");
        setOpenInNewTab(
          typeof wvcClient !== "undefined" &&
            Boolean(wvcClient?.cart?.options?.cartOpenInNewTab)
        );
      } catch {
        // Keep defaults
      }
    }
    loadUrls();
  }, []);

  const badgeCount =
    cart.itemsCount > 0
      ? cart.itemsCount
      : cart.items.reduce((sum, item) => sum + item.quantity, 0);
  const showCount = shouldShowCartItemCount(badgeCount, cartItemCountDisplay);
  const showTotal =
    displayTotalPrice && badgeCount > 0 && Boolean(cart.totals.formattedTotalPrice);
  const countLabel = badgeCount > 99 ? "99+" : String(badgeCount);

  const handleCheckoutNavigate = () => {
    const target = checkoutUrl && checkoutUrl !== "#" ? checkoutUrl : cartUrl;
    if (!target || target === "#") return;
    if (openInNewTab) {
      window.open(target, "_blank", "noopener,noreferrer");
    } else if (typeof window !== "undefined") {
      window.location.assign(target);
    }
  };

  const triggerButton = (
    <Button
      type="button"
      variant={variant}
      size={size}
      className={cn("relative overflow-visible gap-2", className)}
      aria-label={
        badgeCount > 0
          ? `Shopping cart, ${badgeCount} items`
          : "Shopping cart"
      }
      aria-haspopup={navigateToCheckoutOnClick ? undefined : "dialog"}
      aria-expanded={navigateToCheckoutOnClick ? undefined : isOpen}
      onClick={navigateToCheckoutOnClick ? handleCheckoutNavigate : undefined}
    >
      <Icon className={iconSize} aria-hidden="true" />
      {showTotal && (
        <span className="text-sm font-medium">{cart.totals.formattedTotalPrice}</span>
      )}
      {!isLoading && showCount && (
        <span className="absolute -top-1.5 -right-1.5 z-10 min-w-4 h-4 bg-red-600 rounded-full flex items-center justify-center px-1 text-[10px] font-semibold leading-none text-white">
          {countLabel}
        </span>
      )}
      {showLoading && isLoading && (
        <span className="absolute -top-1 -right-1 z-10 size-2 bg-primary rounded-full animate-pulse" />
      )}
    </Button>
  );

  const panel = (
    <CartPanelContent
      cart={cart}
      isLoading={isLoading}
      error={error}
      cartUrl={cartUrl}
      checkoutUrl={checkoutUrl}
      Icon={Icon}
      onNavigate={() => setIsOpen(false)}
    />
  );

  if (navigateToCheckoutOnClick) {
    return triggerButton;
  }

  if (cartLayout === "popup") {
    return (
      <Popover open={isOpen} onOpenChange={setIsOpen}>
        <PopoverTrigger asChild>{triggerButton}</PopoverTrigger>
        <PopoverContent
          align="end"
          collisionPadding={wpAdminBarHeight + 8}
          className="flex w-80 flex-col gap-2 overflow-hidden p-4"
          style={{ maxHeight: `calc(100vh - ${wpAdminBarHeight + 16}px)` }}
          aria-labelledby={titleId}
        >
          <div className="mb-1 shrink-0">
            <p id={titleId} className="text-sm font-semibold text-foreground">
              Your cart
            </p>
            <p className="text-xs text-muted-foreground">
              {badgeCount === 0
                ? "No items yet"
                : `${badgeCount} item${badgeCount === 1 ? "" : "s"}`}
            </p>
          </div>
          <div className="flex min-h-0 flex-1 flex-col overflow-hidden">
            {panel}
          </div>
        </PopoverContent>
      </Popover>
    );
  }

  return (
    <Sheet open={isOpen} onOpenChange={setIsOpen}>
      <SheetTrigger asChild>{triggerButton}</SheetTrigger>
      <SheetContent
        side="right"
        className="flex w-full flex-col sm:max-w-md"
        // Inline offsets: Tailwind class merging drops top/bottom overrides
        // against the base `inset-y-0`, which pushed the panel off-screen.
        style={
          wpAdminBarHeight
            ? { top: wpAdminBarHeight, bottom: 0, height: "auto" }
            : undefined
        }
      >
        {/* Title must be a Dialog.Title descendant of Content for Radix a11y. */}
        <SheetTitle className="sr-only">Your cart</SheetTitle>
        <SheetDescription className="sr-only">
          {badgeCount === 0
            ? "No items yet"
            : `${badgeCount} item${badgeCount === 1 ? "" : "s"}`}
        </SheetDescription>
        <SheetHeader className="text-left">
          <p id={titleId} className="text-foreground text-lg font-semibold">
            Your cart
          </p>
          <p className="text-muted-foreground text-sm">
            {badgeCount === 0
              ? "No items yet"
              : `${badgeCount} item${badgeCount === 1 ? "" : "s"}`}
          </p>
        </SheetHeader>
        <div className="flex min-h-0 flex-1 flex-col px-4 pb-4">{panel}</div>
      </SheetContent>
    </Sheet>
  );
}