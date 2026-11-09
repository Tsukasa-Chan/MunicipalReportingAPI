import { decodeHtmlEntities } from "@/Helpers/utils";
import type {
	EcommerceProduct,
	EcommerceProductAttribute,
	EcommerceProductAttributeTerm,
	EcommerceProductType,
	EcommerceProductVariation,
	EcommerceProductVariationRef,
	EcommerceVariationAttributeSelection,
	Term,
} from "@/Models/types";
import { WP_Query } from "./wp_query";

declare global {
	const wvcClient: any;
}

const variationCache = new Map<string, EcommerceProductVariation[]>();

const safeExtractText = (value: any): string | undefined => {
	if (!value) return undefined;
	if (typeof value === "string") return value;
	if (typeof value === "object" && typeof value.rendered === "string") {
		return value.rendered;
	}
	return undefined;
};

const parsePriceFromRaw = (
	raw: any
): {
	price: number;
	discounted_price: number;
	price_min?: number;
	price_max?: number;
	currency_code: string;
	currency_symbol: string;
	currency_prefix?: string;
	currency_suffix?: string;
	on_sale: boolean;
	formatted_price: string;
	formatted_discounted_price: string;
	formatAmount: (amount: number) => string;
} => {
	const prices = raw?.prices ?? {};
	const hasMinorUnit = prices?.currency_minor_unit != null;
	const minorUnit = hasMinorUnit ? Number(prices.currency_minor_unit) : 0;
	const divisor = minorUnit > 0 ? Math.pow(10, minorUnit) : 1;
	const toMajor = (val: any): number | undefined => {
		if (val == null || val === "") return undefined;
		return Number(val) / divisor;
	};

	const rawRegularPrice = prices?.regular_price ?? raw?.price;
	const rawSalePrice = prices?.sale_price ?? raw?.discounted_price;
	const price = toMajor(rawRegularPrice) ?? 0;
	const discounted_price = toMajor(rawSalePrice) ?? price;

	let price_min: number | undefined;
	let price_max: number | undefined;
	if (prices?.price_range) {
		price_min = toMajor(prices.price_range.min_amount);
		price_max = toMajor(prices.price_range.max_amount);
	}

	const currency_code = prices?.currency_code ? String(prices.currency_code) : "USD";
	const currency_symbol = prices?.currency_symbol
		? decodeHtmlEntities(String(prices.currency_symbol))
		: "$";
	const currency_prefix =
		prices?.currency_prefix != null
			? decodeHtmlEntities(String(prices.currency_prefix))
			: undefined;
	const currency_suffix =
		prices?.currency_suffix != null
			? decodeHtmlEntities(String(prices.currency_suffix))
			: undefined;
	const decimalSeparator = prices?.currency_decimal_separator
		? String(prices.currency_decimal_separator)
		: ".";
	const thousandSeparator =
		prices?.currency_thousand_separator != null
			? String(prices.currency_thousand_separator)
			: ",";

	const formatAmount = (amount: number): string => {
		const decimals = hasMinorUnit ? minorUnit : 2;
		const [intPart, decPart] = amount.toFixed(decimals).split(".");
		const groupedInt = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, thousandSeparator || "");
		const numeric = decPart ? `${groupedInt}${decimalSeparator}${decPart}` : groupedInt;
		const prefix = currency_prefix ?? currency_symbol ?? "";
		const suffix = currency_suffix ?? "";
		return `${prefix}${numeric}${suffix}`;
	};

	const formatted_price = formatAmount(price);
	const formatted_discounted_price = formatAmount(discounted_price);
	const on_sale =
		raw?.on_sale != null ? Boolean(raw.on_sale) : discounted_price < price;

	return {
		price,
		discounted_price,
		price_min,
		price_max,
		currency_code,
		currency_symbol,
		currency_prefix,
		currency_suffix,
		on_sale,
		formatted_price,
		formatted_discounted_price,
		formatAmount,
	};
};

const normalizeAttributeTerms = (terms: any[]): EcommerceProductAttributeTerm[] => {
	if (!Array.isArray(terms)) return [];
	return terms
		.map((term) => ({
			id: term?.id ?? term?.term_id,
			name: decodeHtmlEntities(String(term?.name ?? term?.label ?? "")),
			slug: String(term?.slug ?? term?.value ?? ""),
			default: Boolean(term?.default),
		}))
		.filter((term) => term.name && term.slug);
};

const normalizeAttributes = (raw: any): EcommerceProductAttribute[] | undefined => {
	const source = raw?.attributes;
	if (!Array.isArray(source) || source.length === 0) return undefined;

	const attributes = source
		.filter((attr) => attr && (attr.variation === true || attr.has_variations === true || Array.isArray(attr.terms)))
		.map((attr) => ({
			id: attr?.id,
			name: decodeHtmlEntities(String(attr?.name ?? "")),
			taxonomy: attr?.taxonomy ? String(attr.taxonomy) : undefined,
			has_variations: Boolean(attr?.variation ?? attr?.has_variations ?? true),
			terms: normalizeAttributeTerms(attr?.terms ?? []),
		}))
		.filter((attr) => attr.name && attr.terms.length > 0);

	return attributes.length > 0 ? attributes : undefined;
};

const normalizeVariationRefs = (raw: any): EcommerceProductVariationRef[] | undefined => {
	if (!Array.isArray(raw?.variations) || raw.variations.length === 0) return undefined;

	const refs = raw.variations
		.map((variation: any) => {
			if (typeof variation === "number" || typeof variation === "string") {
				return { id: variation, attributes: [] as Array<{ name: string; value: string }> };
			}
			return {
				id: variation?.id ?? variation?.variation_id,
				attributes: Array.isArray(variation?.attributes)
					? variation.attributes.map((a: any) => ({
							name: String(a?.name ?? ""),
							value: String(a?.value ?? ""),
						}))
					: [],
			};
		})
		.filter((ref) => ref.id != null);

	return refs.length > 0 ? refs : undefined;
};

/**
 * Store API variation items often return attributes: [] but expose selected options via
 * permalink query params (attribute_pa_*) and/or the human-readable variation string.
 */
export const extractVariationAttributePairs = (
	raw: any
): Array<{ name: string; value: string }> => {
	if (Array.isArray(raw?.attributes) && raw.attributes.length > 0) {
		return raw.attributes
			.map((attr: any) => ({
				name: String(attr?.name ?? attr?.id ?? ""),
				value: String(attr?.value ?? ""),
			}))
			.filter((attr: { name: string; value: string }) => attr.name && attr.value);
	}

	const pairs: Array<{ name: string; value: string }> = [];
	const permalink = String(raw?.permalink ?? raw?.link ?? "");
	if (permalink) {
		try {
			const url = new URL(permalink, "http://localhost");
			url.searchParams.forEach((value, key) => {
				if (key.startsWith("attribute_")) {
					pairs.push({
						name: key.slice("attribute_".length),
						value,
					});
				}
			});
		} catch {
			// ignore malformed URLs
		}
	}
	if (pairs.length > 0) {
		return pairs;
	}

	const variationLabel = raw?.variation;
	if (typeof variationLabel === "string" && variationLabel.trim()) {
		for (const part of variationLabel.split(",")) {
			const colonIndex = part.indexOf(":");
			if (colonIndex === -1) continue;
			const name = part.slice(0, colonIndex).trim();
			const value = part.slice(colonIndex + 1).trim();
			if (name && value) {
				pairs.push({ name, value });
			}
		}
	}

	return pairs;
};

const getVariationAttributePairs = (
	variation: EcommerceProduct | EcommerceProductVariation
): Array<{ name: string; value: string }> => {
	const typed = variation as EcommerceProductVariation;
	if (typed.variation_attribute_values?.length) {
		return typed.variation_attribute_values;
	}

	const attrs = (variation as any)?.attributes;
	if (
		Array.isArray(attrs) &&
		attrs.length > 0 &&
		attrs[0] &&
		typeof attrs[0] === "object" &&
		"value" in attrs[0]
	) {
		return attrs.map((attr: any) => ({
			name: String(attr?.name ?? ""),
			value: String(attr?.value ?? ""),
		}));
	}

	return extractVariationAttributePairs(variation);
};

const resolveProductType = (raw: any): EcommerceProductType => {
	const rawType = String(raw?.type ?? raw?.product_type ?? "simple").toLowerCase();
	if (
		rawType === "variable" ||
		rawType === "variation" ||
		rawType === "external" ||
		rawType === "grouped"
	) {
		return rawType;
	}
	return "simple";
};

/** Store API external/affiliate products expose URL + CTA via add_to_cart. */
const resolveExternalProductUrl = (raw: any): string | undefined => {
	if (typeof raw?.product_url === "string" && raw.product_url.trim()) {
		return raw.product_url.trim();
	}
	if (typeof raw?.external_url === "string" && raw.external_url.trim()) {
		return raw.external_url.trim();
	}
	const addToCartUrl = raw?.add_to_cart?.url;
	if (typeof addToCartUrl === "string" && addToCartUrl.trim()) {
		return addToCartUrl.trim();
	}
	return undefined;
};

const resolveExternalButtonText = (raw: any): string | undefined => {
	if (typeof raw?.button_text === "string" && raw.button_text.trim()) {
		return raw.button_text.trim();
	}
	const addToCart = raw?.add_to_cart;
	if (!addToCart || typeof addToCart !== "object") {
		return undefined;
	}
	for (const key of ["text", "single_text", "description"] as const) {
		const value = addToCart[key];
		if (typeof value === "string" && value.trim()) {
			return value.trim();
		}
	}
	return undefined;
};

const mapTerm = (t: any, defaultTaxonomy?: string): Term => ({
	id: Number(t?.id ?? 0),
	name: decodeHtmlEntities(String(t?.name ?? "")),
	slug: String(t?.slug ?? ""),
	taxonomy: String(t?.taxonomy ?? defaultTaxonomy ?? ""),
	link: t?.link,
});

export const normalizeEcommerceProduct = (raw: any): EcommerceProduct => {
	const title = decodeHtmlEntities(
		safeExtractText(raw?.title) ??
			raw?.post_title ??
			String(raw?.title || raw?.name || "Untitled")
	);

	const shortDescription =
		safeExtractText(raw?.short_description) ??
		safeExtractText(raw?.excerpt) ??
		raw?.post_excerpt ??
		undefined;

	const longDescription =
		safeExtractText(raw?.long_description) ??
		safeExtractText(raw?.description) ??
		safeExtractText(raw?.content) ??
		raw?.post_content ??
		shortDescription ??
		undefined;

	const link = raw?.resolved_url || raw?.link || raw?.permalink || raw?.url || undefined;

	// All product images: featured first, then gallery. Prefer the theme's
	// gallery_image_urls field; fall back to the Store API images[] array.
	const gallery_image_urls: string[] = (
		Array.isArray(raw?.gallery_image_urls)
			? raw.gallery_image_urls
			: Array.isArray(raw?.images)
				? raw.images.map((img: any) => img?.src)
				: []
	).filter((url: any): url is string => typeof url === "string" && url.length > 0);

	const featured_image_url =
		raw?._embedded?.["wp:featuredmedia"]?.[0]?.source_url ??
		gallery_image_urls[0] ??
		raw?.images?.[0]?.src ??
		raw?.featured_media_url ??
		raw?.featured_image_url ??
		undefined;

	let categories: Term[] = [];
	if (Array.isArray(raw?.categories) && raw.categories.length > 0) {
		categories = raw.categories.map((t: any) => mapTerm(t, "product_cat"));
	} else {
		const termGroups: any[][] | undefined = raw?._embedded?.["wp:term"];
		if (Array.isArray(termGroups)) {
			categories = termGroups
				.reduce((acc, group) => acc.concat(group), [])
				.filter((t: any) => t && t.taxonomy === "product_cat")
				.map((t: any) => mapTerm(t));
		}
	}

	let tags: Term[] = [];
	if (Array.isArray(raw?.tags) && raw.tags.length > 0) {
		tags = raw.tags.map((t: any) => mapTerm(t, "product_tag"));
	} else {
		const termGroups: any[][] | undefined = raw?._embedded?.["wp:term"];
		if (Array.isArray(termGroups)) {
			tags = termGroups
				.reduce((acc, group) => acc.concat(group), [])
				.filter((t: any) => t && t.taxonomy === "product_tag")
				.map((t: any) => mapTerm(t));
		}
	}

	let customFields: Record<string, any> | undefined = undefined;
	if (raw?.meta) {
		const postType = raw?.type || "product";
		const prefix = `wvc_${postType}_`;
		const fields: Record<string, any> = {};

		Object.keys(raw.meta).forEach((key) => {
			if (key.startsWith(prefix)) {
				const fieldKey = key.replace(prefix, "");
				fields[fieldKey] = raw.meta[key];
			}
		});

		if (Object.keys(fields).length > 0) {
			customFields = fields;
		}
	}

	const {
		price,
		discounted_price,
		price_min,
		price_max,
		currency_code,
		currency_symbol,
		currency_prefix,
		currency_suffix,
		on_sale,
		formatted_price,
		formatted_discounted_price,
	} = parsePriceFromRaw(raw);
	const type = resolveProductType(raw);
	const attributes = normalizeAttributes(raw);
	const variations = normalizeVariationRefs(raw);
	const variation_attribute_values =
		type === "variation" ? extractVariationAttributePairs(raw) : undefined;

	const is_in_stock =
		raw?.is_in_stock != null
			? Boolean(raw.is_in_stock)
			: raw?.stock_status
				? String(raw.stock_status) !== "outofstock"
				: true;

	return {
		id: String(raw?.id ?? raw?.ID),
		title: String(title),
		slug: raw?.slug,
		short_description: typeof shortDescription === "string" ? shortDescription : undefined,
		long_description: typeof longDescription === "string" ? longDescription : undefined,
		link,
		date: raw?.date || raw?.post_date || undefined,
		featured_image_url,
		// Never empty when a featured image exists, so consumers can map over
		// this single field for both single-image and multi-image products.
		gallery_image_urls:
			gallery_image_urls.length > 0
				? gallery_image_urls
				: featured_image_url
					? [featured_image_url]
					: [],
		categories: categories && categories.length ? categories : [],
		tags: tags && tags.length ? tags : [],
		customFields,
		price,
		discounted_price,
		currency_code,
		currency_symbol,
		currency_prefix,
		currency_suffix,
		on_sale,
		formatted_price,
		formatted_discounted_price,
		type,
		virtual: Boolean(raw?.virtual),
		downloadable: Boolean(raw?.downloadable),
		product_url: resolveExternalProductUrl(raw),
		button_text: resolveExternalButtonText(raw),
		attributes,
		variations,
		price_min,
		price_max,
		price_html: typeof raw?.price_html === "string" ? raw.price_html : undefined,
		is_purchasable: raw?.is_purchasable ?? raw?.purchasable ?? undefined,
		is_in_stock,
		stock_status: raw?.stock_status ? String(raw.stock_status) : undefined,
		parent_id: raw?.parent ?? raw?.parent_id ?? undefined,
		...(variation_attribute_values?.length
			? { variation_attribute_values }
			: {}),
	} as EcommerceProduct;
};

export const convertWPResponseToEcommerceProducts = (input: any): EcommerceProduct[] => {
	if (!Array.isArray(input)) return [];
	return input.map(normalizeEcommerceProduct);
};

export const isVariableProduct = (product: EcommerceProduct): boolean =>
	product.type === "variable" ||
	Boolean(product.attributes?.length && product.attributes.some((a) => a.terms.length > 0));

export const isExternalProduct = (product: EcommerceProduct): boolean =>
	product.type === "external";

export const isSimpleProduct = (product: EcommerceProduct): boolean =>
	!isVariableProduct(product) && !isExternalProduct(product);

export const formatProductPrice = (product: EcommerceProduct): string => {
	if (product.formatted_discounted_price || product.formatted_price) {
		return product.formatted_discounted_price ?? product.formatted_price ?? "";
	}

	if (
		isVariableProduct(product) &&
		product.price_min != null &&
		product.price_max != null &&
		product.price_min !== product.price_max
	) {
		const prefix = product.currency_prefix ?? product.currency_symbol ?? "$";
		const suffix = product.currency_suffix ?? "";
		const format = (amount: number) => `${prefix}${amount.toFixed(2)}${suffix}`;
		return `${format(product.price_min)} – ${format(product.price_max)}`;
	}

	const sale = product.discounted_price ?? product.price;
	const regular = product.price;
	const prefix = product.currency_prefix ?? product.currency_symbol ?? "$";
	const suffix = product.currency_suffix ?? "";
	if (sale != null && regular != null && sale < regular) {
		return `${prefix}${sale.toFixed(2)}${suffix}`;
	}
	if (regular != null) {
		return `${prefix}${regular.toFixed(2)}${suffix}`;
	}
	return "";
};

const stripScreenReaderText = (html: string): string =>
	html.replace(/<span[^>]*class="[^"]*screen-reader-text[^"]*"[^>]*>[\s\S]*?<\/span>/gi, "")
		.trim();

export const getProductPriceHtml = (product: EcommerceProduct): string | undefined => {
	const raw = product.price_html?.trim();
	if (!raw) return undefined;

	let decoded = raw;
	if (raw.includes("&lt;") || raw.includes("&gt;") || raw.includes("&amp;")) {
		decoded = raw
			.replace(/&amp;/g, "&")
			.replace(/&lt;/g, "<")
			.replace(/&gt;/g, ">")
			.replace(/&quot;/g, "\"")
			.replace(/&#039;/g, "'");
	}

	const sanitized = stripScreenReaderText(decoded);
	return sanitized || undefined;
};

export const getVariationAttributeKeys = (product: EcommerceProduct): EcommerceProductAttribute[] =>
	(product.attributes ?? []).filter((attr) => attr.terms.length > 0);

export const getAttributeSelectionKey = (attr: EcommerceProductAttribute): string =>
	attr.taxonomy || attr.name;

/** Build initial dropdown selection from Store API default attribute terms. */
export const getDefaultAttributeSelection = (
	product: EcommerceProduct
): EcommerceVariationAttributeSelection => {
	const selection: EcommerceVariationAttributeSelection = {};
	for (const attr of getVariationAttributeKeys(product)) {
		const defaultTerm = attr.terms.find((term) => term.default);
		if (defaultTerm?.slug) {
			selection[getAttributeSelectionKey(attr)] = defaultTerm.slug;
		}
	}
	return selection;
};

export const isAttributeSelectionComplete = (
	product: EcommerceProduct,
	selection: EcommerceVariationAttributeSelection
): boolean => {
	const attrs = getVariationAttributeKeys(product);
	if (attrs.length === 0) return false;
	return attrs.every((attr) => {
		const key = getAttributeSelectionKey(attr);
		return Boolean(selection[key]);
	});
};

const normalizeAttributeValue = (value: string): string =>
	decodeHtmlEntities(value).trim().toLowerCase();

export const variationMatchesSelection = (
	variation: EcommerceProduct | EcommerceProductVariation,
	product: EcommerceProduct,
	selection: EcommerceVariationAttributeSelection
): boolean => {
	const attrs = getVariationAttributeKeys(product);
	if (attrs.length === 0) return false;

	const variationAttributes = getVariationAttributePairs(variation);
	if (variationAttributes.length === 0) return false;

	return attrs.every((attr) => {
		const key = getAttributeSelectionKey(attr);
		const selected = normalizeAttributeValue(selection[key] ?? "");
		if (!selected) return false;

		const selectedTerm = attr.terms.find(
			(term) =>
				normalizeAttributeValue(term.slug) === selected ||
				normalizeAttributeValue(term.name) === selected
		);
		const selectedLabel = selectedTerm?.name ?? selection[key];
		const selectedSlug = selectedTerm?.slug ?? selection[key];

		const match = variationAttributes.find((va) => {
			const vaName = normalizeAttributeValue(String(va?.name ?? ""));
			const vaValue = normalizeAttributeValue(String(va?.value ?? ""));
			const attrName = normalizeAttributeValue(attr.name);
			const attrTaxonomy = normalizeAttributeValue(attr.taxonomy ?? "");
			const nameMatches =
				vaName === attrName ||
				vaName === attrTaxonomy ||
				(attrTaxonomy && vaName === attrTaxonomy.replace(/^pa_/, ""));

			return (
				nameMatches &&
				(vaValue === selected ||
					vaValue === normalizeAttributeValue(selectedLabel) ||
					vaValue === normalizeAttributeValue(selectedSlug))
			);
		});

		return Boolean(match);
	});
};

export const findMatchingVariation = (
	variations: EcommerceProductVariation[],
	product: EcommerceProduct,
	selection: EcommerceVariationAttributeSelection
): EcommerceProductVariation | null => {
	for (const variation of variations) {
		if (variationMatchesSelection(variation, product, selection)) {
			return variation;
		}
	}
	return null;
};

export const buildVariationCartAttributes = (
	product: EcommerceProduct,
	selection: EcommerceVariationAttributeSelection
): Record<string, string> => {
	const out: Record<string, string> = {};
	for (const attr of getVariationAttributeKeys(product)) {
		const key = getAttributeSelectionKey(attr);
		const selectedSlug = selection[key];
		if (!selectedSlug) continue;
		const taxonomyKey = attr.taxonomy?.startsWith("pa_")
			? `attribute_${attr.taxonomy}`
			: `attribute_${attr.name.toLowerCase().replace(/\s+/g, "-")}`;
		out[taxonomyKey] = selectedSlug;
	}
	return out;
};

export const fetchProductVariations = async (
	product: EcommerceProduct
): Promise<EcommerceProductVariation[]> => {
	const cacheKey = String(product.id);
	if (variationCache.has(cacheKey)) {
		return variationCache.get(cacheKey)!;
	}

	const includeIds = (product.variations ?? [])
		.map((v) => Number(v.id))
		.filter((id) => !Number.isNaN(id));

	const parentId = Number(product.id);
	const queryVars: Record<string, any> = {
		type: "variation",
		parent: parentId,
		post_parent: parentId,
		per_page: 100,
		post_type: "product",
	};
	if (includeIds.length > 0) {
		queryVars.include = includeIds;
	}

	const wpQuery = new WP_Query(queryVars);
	wpQuery.parse_query_vars();

	// Store API product type/parent must reach wc/store/v1/products. wpQueryToRest does not
	// map query_vars.type or query_vars.parent yet, so pass them via get_wp_query_results params.
	const storeApiParams = {
		type: "variation",
		parent: parentId,
	};

	let rawPosts: any[] = [];

	if (typeof wvcClient !== "undefined" && wvcClient?.get_wp_query_results) {
		const res = await wvcClient.get_wp_query_results(
			wpQuery.toJSON(),
			storeApiParams,
			false
		);
		rawPosts = res?.posts ?? [];
	} else if (typeof wvcClient !== "undefined" && wvcClient?.getStoreProducts) {
		const res = await wvcClient.getStoreProducts(queryVars);
		rawPosts = Array.isArray(res) ? res : res?.products ?? [];
	}

	const normalized = rawPosts.map(
		(raw) => normalizeEcommerceProduct(raw) as EcommerceProductVariation
	);
	variationCache.set(cacheKey, normalized);
	return normalized;
};

export const clearVariationCache = (): void => {
	variationCache.clear();
};
