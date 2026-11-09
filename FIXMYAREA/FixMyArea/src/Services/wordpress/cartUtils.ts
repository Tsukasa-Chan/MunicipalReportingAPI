export type CartItemCountDisplay = "always" | "only-if-items" | "never";
export type CartLayout = "drawer" | "popup";

export interface CartCurrency {
  code: string;
  symbol: string;
  prefix: string;
  suffix: string;
  minorUnit: number;
  decimalSeparator: string;
  thousandSeparator: string;
}

export interface CartTotalsView {
  totalItems: number;
  totalPrice: number;
  totalDiscount: number;
  totalTax: number;
  totalShipping: number;
  formattedTotalItems: string;
  formattedTotalPrice: string;
  currency: CartCurrency;
}

export interface CartVariationLabel {
  attribute: string;
  value: string;
}

export interface CartItemView {
  key: string;
  id: number;
  name: string;
  quantity: number;
  permalink: string;
  imageSrc?: string;
  imageAlt: string;
  variations: CartVariationLabel[];
  unitPrice: number;
  lineTotal: number;
  formattedUnitPrice: string;
  formattedLineTotal: string;
  quantityEditable: boolean;
}

export interface CartView {
  itemsCount: number;
  items: CartItemView[];
  totals: CartTotalsView;
  needsPayment: boolean;
  needsShipping: boolean;
}

export interface WooUrls {
  cart: string;
  checkout: string;
  account: string;
}

declare global {
  interface Window {
    wvcClient: any;
  }
  // Injected by the WordPress theme (same global AddToCartButton uses).
  const wvcClient: any;
}

const DEFAULT_CURRENCY: CartCurrency = {
  code: "USD",
  symbol: "$",
  prefix: "$",
  suffix: "",
  minorUnit: 2,
  decimalSeparator: ".",
  thousandSeparator: ",",
};

const safeDecode = (text: string): string => {
  if (typeof document === "undefined") {
    return text
      .replace(/&amp;/g, "&")
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">")
      .replace(/&quot;/g, '"')
      .replace(/&#39;/g, "'")
      .replace(/&nbsp;/g, " ");
  }
  try {
    const textarea = document.createElement("textarea");
    textarea.innerHTML = text;
    const decoded = textarea.value;
    textarea.remove();
    return decoded;
  } catch {
    return text;
  }
};

const toNumber = (value: unknown, fallback = 0): number => {
  if (value == null || value === "") return fallback;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const readCurrency = (source: any): CartCurrency => {
  if (!source || typeof source !== "object") {
    return { ...DEFAULT_CURRENCY };
  }

  const minorUnit = toNumber(source.currency_minor_unit, DEFAULT_CURRENCY.minorUnit);
  const symbol = source.currency_symbol
    ? safeDecode(String(source.currency_symbol))
    : DEFAULT_CURRENCY.symbol;
  const prefix =
    source.currency_prefix != null
      ? safeDecode(String(source.currency_prefix))
      : symbol;
  const suffix =
    source.currency_suffix != null
      ? safeDecode(String(source.currency_suffix))
      : "";

  return {
    code: source.currency_code ? String(source.currency_code) : DEFAULT_CURRENCY.code,
    symbol,
    prefix,
    suffix,
    minorUnit: minorUnit >= 0 ? minorUnit : DEFAULT_CURRENCY.minorUnit,
    decimalSeparator: source.currency_decimal_separator
      ? String(source.currency_decimal_separator)
      : DEFAULT_CURRENCY.decimalSeparator,
    thousandSeparator:
      source.currency_thousand_separator != null
        ? String(source.currency_thousand_separator)
        : DEFAULT_CURRENCY.thousandSeparator,
  };
};

/**
 * Format a WooCommerce Store API minor-unit price string/number into a display string.
 */
export const formatCartMoney = (
  amountMinor: unknown,
  currency: CartCurrency = DEFAULT_CURRENCY
): string => {
  const minor = toNumber(amountMinor, 0);
  const divisor = currency.minorUnit > 0 ? Math.pow(10, currency.minorUnit) : 1;
  const major = minor / divisor;
  const decimals = currency.minorUnit > 0 ? currency.minorUnit : 0;
  const [intPart, decPart] = major.toFixed(decimals).split(".");
  const groupedInt = intPart.replace(
    /\B(?=(\d{3})+(?!\d))/g,
    currency.thousandSeparator || ""
  );
  const numeric = decPart
    ? `${groupedInt}${currency.decimalSeparator}${decPart}`
    : groupedInt;
  return `${currency.prefix}${numeric}${currency.suffix}`;
};

export const minorToMajor = (
  amountMinor: unknown,
  currency: CartCurrency = DEFAULT_CURRENCY
): number => {
  const minor = toNumber(amountMinor, 0);
  const divisor = currency.minorUnit > 0 ? Math.pow(10, currency.minorUnit) : 1;
  return minor / divisor;
};

export const shouldShowCartItemCount = (
  count: number,
  mode: CartItemCountDisplay
): boolean => {
  if (mode === "never") return false;
  if (mode === "always") return true;
  return count > 0;
};

const normalizeVariation = (raw: any): CartVariationLabel | null => {
  if (!raw || typeof raw !== "object") return null;
  const attribute = String(raw.attribute ?? raw.name ?? "").trim();
  const value = String(raw.value ?? "").trim();
  if (!attribute && !value) return null;
  return {
    attribute: attribute || "Option",
    value: value || "",
  };
};

export const normalizeCartItem = (raw: any): CartItemView | null => {
  if (!raw || typeof raw !== "object") return null;

  const key = String(raw.key ?? raw.id ?? "").trim();
  if (!key) return null;

  const pricesCurrency = readCurrency(raw.prices ?? raw.totals);
  const totalsCurrency = readCurrency(raw.totals ?? raw.prices);
  const unitPriceMinor = raw.prices?.price ?? raw.prices?.sale_price ?? "0";
  const lineTotalMinor =
    raw.totals?.line_total ?? raw.totals?.line_subtotal ?? unitPriceMinor;

  const images = Array.isArray(raw.images) ? raw.images : [];
  const firstImage = images[0];
  const imageSrc =
    (firstImage?.thumbnail && String(firstImage.thumbnail)) ||
    (firstImage?.src && String(firstImage.src)) ||
    undefined;
  const imageAlt =
    (firstImage?.alt && String(firstImage.alt)) ||
    (firstImage?.name && String(firstImage.name)) ||
    String(raw.name ?? "Product");

  const variations = Array.isArray(raw.variation)
    ? raw.variation
        .map(normalizeVariation)
        .filter((entry): entry is CartVariationLabel => entry != null)
    : [];

  return {
    key,
    id: toNumber(raw.id, 0),
    name: String(raw.name ?? "Product"),
    quantity: Math.max(0, toNumber(raw.quantity, 0)),
    permalink: String(raw.permalink ?? ""),
    imageSrc,
    imageAlt,
    variations,
    unitPrice: minorToMajor(unitPriceMinor, pricesCurrency),
    lineTotal: minorToMajor(lineTotalMinor, totalsCurrency),
    formattedUnitPrice: formatCartMoney(unitPriceMinor, pricesCurrency),
    formattedLineTotal: formatCartMoney(lineTotalMinor, totalsCurrency),
    quantityEditable: Boolean(raw.quantity_limits?.editable ?? true),
  };
};

export const normalizeCartItems = (raw: unknown): CartItemView[] => {
  const list = Array.isArray(raw)
    ? raw
    : Array.isArray((raw as any)?.items)
      ? (raw as any).items
      : [];
  return list
    .map(normalizeCartItem)
    .filter((item): item is CartItemView => item != null);
};

export const normalizeCart = (
  rawCart: any,
  rawItems?: unknown
): CartView => {
  const items = normalizeCartItems(
    rawItems !== undefined ? rawItems : rawCart?.items
  );
  const totalsSource = rawCart?.totals ?? {};
  const currency = readCurrency(totalsSource);
  const itemsCount =
    rawCart?.items_count != null
      ? toNumber(rawCart.items_count, items.length)
      : items.reduce((sum, item) => sum + item.quantity, 0);

  const totalItemsMinor = totalsSource.total_items ?? "0";
  const totalPriceMinor = totalsSource.total_price ?? totalItemsMinor;
  const totalDiscountMinor = totalsSource.total_discount ?? "0";
  const totalTaxMinor = totalsSource.total_tax ?? "0";
  const totalShippingMinor = totalsSource.total_shipping ?? "0";

  return {
    itemsCount,
    items,
    totals: {
      totalItems: minorToMajor(totalItemsMinor, currency),
      totalPrice: minorToMajor(totalPriceMinor, currency),
      totalDiscount: minorToMajor(totalDiscountMinor, currency),
      totalTax: minorToMajor(totalTaxMinor, currency),
      totalShipping: minorToMajor(totalShippingMinor, currency),
      formattedTotalItems: formatCartMoney(totalItemsMinor, currency),
      formattedTotalPrice: formatCartMoney(totalPriceMinor, currency),
      currency,
    },
    needsPayment: Boolean(rawCart?.needs_payment),
    needsShipping: Boolean(rawCart?.needs_shipping),
  };
};

export const normalizeWooUrls = (raw: any): WooUrls => ({
  cart: String(raw?.cart ?? "#"),
  checkout: String(raw?.checkout ?? "#"),
  account: String(raw?.account ?? "/my-account"),
});

/**
 * The theme's `wvc.js` and the live editor's iframe stub expose the same
 * `wvcClient` shape:
 *
 * - Store API reads live on the client itself, next to
 *   `get_wp_query_results`: `wvcClient.getCart(flushCache)`.
 * - `wvcClient.cart` is the mutation/navigation helper only
 *   (`addToCart`, `currentState`, `getUrls`, ...). It has no `getCart`.
 *
 * `typeof` guards the bare global so a missing theme script degrades to an
 * empty cart instead of a ReferenceError (same pattern as
 * `ecommerceProductUtils.ts`).
 */
function hasWvcClient(): boolean {
  return typeof wvcClient !== "undefined" && wvcClient != null;
}

function coerceCartPayload(raw: unknown): unknown {
  if (!raw || typeof raw !== "object") return raw;
  const payload = raw as Record<string, unknown>;

  // Theme helpers sometimes return { success, data } envelopes.
  if (
    payload.data != null &&
    typeof payload.data === "object" &&
    payload.items_count == null &&
    payload.totals == null &&
    !Array.isArray(raw)
  ) {
    return coerceCartPayload(payload.data);
  }

  return payload;
}

/**
 * Fetch cart via Store API getCart (full cart incl. items + totals).
 */
export async function fetchCartView(
  flushCache = true
): Promise<CartView> {
  if (!hasWvcClient()) {
    console.warn("wvcClient is not available");
    return normalizeCart({});
  }

  if (typeof wvcClient.getCart !== "function") {
    console.warn("wvcClient.getCart is not available");
    return normalizeCart({});
  }

  const rawCart = await wvcClient.getCart(flushCache);
  return normalizeCart(coerceCartPayload(rawCart));
}

/**
 * Cart/checkout/account URLs come from the cart helper (`wvcClient.cart.getUrls`),
 * which is also where `addToCart` lives.
 */
export async function fetchWooUrls(): Promise<WooUrls> {
  if (!hasWvcClient() || typeof wvcClient.cart?.getUrls !== "function") {
    return normalizeWooUrls({});
  }

  const urls = await wvcClient.cart.getUrls();
  return normalizeWooUrls(urls);
}
