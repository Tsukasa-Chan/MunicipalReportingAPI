import React, { useEffect, useMemo, useRef, useState } from "react";

import type { EcommerceProduct } from "@/Models/types";
import { DEFAULT_ECOMMERCE_PRODUCT_EMBEDS, DEFAULT_ECOMMERCE_PRODUCT_FIELDS } from "@/Models/types";
import { WP_Query, type WP_Query_Vars } from "./wp_query";
import {
	convertWPResponseToEcommerceProducts,
	normalizeEcommerceProduct,
} from "./ecommerceProductUtils";

import { EcommerceProductsContext } from "./WordPressEcommerceProductsContext";

declare global {
    const wvcClient: any;
}

import type { QueryParams, EcommerceProductsContextType } from "./WordPressEcommerceProductsContext";

export { normalizeEcommerceProduct, convertWPResponseToEcommerceProducts };
export {
	isVariableProduct,
	isSimpleProduct,
	formatProductPrice,
	getProductPriceHtml,
	fetchProductVariations,
	findMatchingVariation,
	getDefaultAttributeSelection,
} from "./ecommerceProductUtils";
export { AddToCartButton, type AddToCartButtonProps } from "./AddToCartButton";
export { ProductPrice, type ProductPriceProps } from "./ProductPrice";
export {
	VariableProductAddToCart,
	ProductVariationSelector,
	type VariableProductAddToCartProps,
	type ProductVariationSelectorProps,
	type VariableProductResolutionState,
} from "./VariableProductAddToCart";

type WordPressEcommerceProductsProviderProps = {
    children: React.ReactNode;
    postType?: string;      // post type to fetch (defaults to 'product')
    // null = intentionally idle (e.g. empty product search); omit/undefined = default query
    wp_query?: WP_Query | QueryParams | null;
} & React.HTMLAttributes<HTMLDivElement>;

const WordPressEcommerceProductsProvider = ({
    children,
    postType = 'product',
    wp_query: wp_query_prop,
    ...divProps
}: WordPressEcommerceProductsProviderProps) => {
    // Convert wp_query prop to WP_Query object if it's not already
    // Ensure post_type is set from postType prop if not already in wp_query
    // Explicit null means "do not fetch" (empty search idle state).
    const initialWPQuery = useMemo(() => {
        if (wp_query_prop === null) {
            return null;
        }

        let query: WP_Query;
        if (wp_query_prop instanceof WP_Query) {
            query = wp_query_prop;
        } else if (wp_query_prop && typeof wp_query_prop === 'object') {
            // Convert plain object to WP_Query
            query = new WP_Query(wp_query_prop as WP_Query_Vars);
        } else {
            query = new WP_Query({});
        }
        
        // Ensure post_type is set from postType prop if not already in query
        if (!query.get("post_type")) {
            query.set("post_type", postType);
        }
        
        return query;
    }, [wp_query_prop, postType]);

    // Editable query state (seeded from props)
    const [wp_query, setWPQueryState] = useState<WP_Query | null>(initialWPQuery);
    const [embedsState, setEmbedsState] = useState<string[]>(DEFAULT_ECOMMERCE_PRODUCT_EMBEDS);
    const [fieldsState, setFieldsState] = useState<string[]>(DEFAULT_ECOMMERCE_PRODUCT_FIELDS);

    // Derived query params from wp_query.query_vars for backward compatibility
    const query = useMemo(() => {
        return wp_query?.query_vars || {};
    }, [wp_query]);

    // Data + status
    const [posts, setPosts] = useState<EcommerceProduct[]>([]);
    const [loading, setLoading] = useState<boolean>(wp_query_prop !== null);
    const [isRefetching, setIsRefetching] = useState<boolean>(false);
    const [error, setError] = useState<string | null>(null);
    const [total, setTotal] = useState<number>(0);
    const [totalPages, setTotalPages] = useState<number>(0);
    const abortControllerRef = useRef<AbortController | null>(null);
    const providerInstanceIdRef = useRef<string>(`products-provider-${Math.random().toString(36).slice(2, 10)}`);
    const activeRequestKeyRef = useRef<string>("");
    const fetchGenerationRef = useRef(0);
    const skipReactiveFetchRef = useRef(false);

    // Sync on query *content*, not object identity: generated sections often build
    // a new WP_Query (or a new params object) on every render for the same query,
    // and that identity churn must not restart the fetch or drop an in-flight response.
    let wp_query_prop_hash: string;
    if (wp_query_prop === null) {
        wp_query_prop_hash = "null";
    } else if (wp_query_prop instanceof WP_Query) {
        wp_query_prop_hash = wp_query_prop.getHash();
    } else if (wp_query_prop && typeof wp_query_prop === "object") {
        try {
            wp_query_prop_hash = JSON.stringify(wp_query_prop);
        } catch {
            wp_query_prop_hash = "";
        }
    } else {
        wp_query_prop_hash = "";
    }
    useEffect(() => {
        skipReactiveFetchRef.current = false;
        if (wp_query_prop === null) {
            setWPQueryState(null);
        } else if (wp_query_prop instanceof WP_Query) {
            if (!wp_query_prop.get("post_type")) {
                wp_query_prop.set("post_type", postType);
            }
            setWPQueryState(wp_query_prop);
        } else if (wp_query_prop && typeof wp_query_prop === 'object') {
            const nextQuery = new WP_Query(wp_query_prop as WP_Query_Vars);
            if (!nextQuery.get("post_type")) {
                nextQuery.set("post_type", postType);
            }
            setWPQueryState(nextQuery);
        } else {
            const nextQuery = new WP_Query({});
            nextQuery.set("post_type", postType);
            setWPQueryState(nextQuery);
        }
        // wp_query_prop identity is intentionally NOT a dependency (see hash above).
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [wp_query_prop_hash, postType]);

    const handleError = (e?: unknown) => {
        const msg = (e as any)?.message ?? String(e);
        setError(msg);
    };

    // Process WP_Query to determine what should be rendered
    // Extract query vars and determine if we should render a list of posts
    const shouldRenderPosts = useMemo(() => {
        if (!wp_query) return true; // Default to rendering posts
        
        // Check query flags to determine what to render
        // For ecommerce products, we typically want to render a list
        // Single product queries (is_single) might be handled differently
        if (wp_query.is_single) {
            // Single product - render one product
            return true;
        }
        
        // Archive, category, tag, search, etc. - render list
        return true; // Always render posts for ecommerce products
    }, [wp_query]);

    const effectiveDeps = [
        wp_query?.getHash() || JSON.stringify(query),
        JSON.stringify(embedsState),
        JSON.stringify(fieldsState),
    ];

    const fetch = (opts?: {
        wp_query?: WP_Query | Partial<QueryParams>;
        embeds?: string[];
        fields?: string[];
        append?: boolean;
        refresh?: boolean;
        flushCache?: boolean;
    }): Promise<void> => {
        const isRefresh = Boolean(opts?.refresh);
        const shouldFlushCache = Boolean(opts?.flushCache);
        if (isRefresh && isRefetching) return Promise.resolve();

        setError(null);
        if (isRefresh) setIsRefetching(true);
        else setLoading(true);

        // Monotonic generation: only the latest request may clear loading flags,
        // so a superseded first fetch can never leave the grid stuck on skeleton.
        const generation = ++fetchGenerationRef.current;

        // Determine which WP_Query to use
        let queryToUse: WP_Query;
        if (opts?.wp_query instanceof WP_Query) {
            queryToUse = opts.wp_query;
        } else if (opts?.wp_query && typeof opts.wp_query === 'object') {
            // Merge partial query params into current wp_query
            const currentQuery = wp_query || new WP_Query({});
            const mergedVars = { ...currentQuery.query_vars, ...opts.wp_query };
            queryToUse = new WP_Query(mergedVars);
        } else {
            queryToUse = wp_query || new WP_Query({});
        }

        // Ensure query vars are parsed
        queryToUse.parse_query_vars();

        // Extract post_type from wp_query, fallback to postType prop
        const queryPostType = queryToUse.get("post_type");
        const effectivePostType = (queryPostType && typeof queryPostType === "string") 
            ? queryPostType 
            : (Array.isArray(queryPostType) && queryPostType.length > 0 && typeof queryPostType[0] === "string")
                ? queryPostType[0]
                : postType;
        queryToUse.set("post_type", effectivePostType);

        const usedEmbeds = opts?.embeds ?? embedsState;
        const usedFields = opts?.fields ?? fieldsState;
        const requestHash = JSON.stringify({
            query: queryToUse.toJSON(),
            postType: effectivePostType,
            embeds: usedEmbeds,
            fields: usedFields,
            append: Boolean(opts?.append),
            refresh: isRefresh,
        });
        const requestKey = `${providerInstanceIdRef.current}:${requestHash}`;
        activeRequestKeyRef.current = requestKey;

        // Use get_wp_query_results instead of getPosts
        // post_type is already in wp_query.query_vars
        return wvcClient.get_wp_query_results(
            queryToUse.toJSON(),
            {
                embeds: usedEmbeds,
                fields: usedFields,
            },
            shouldFlushCache
        ).then((res: any) => {
            if (activeRequestKeyRef.current !== requestKey) {
                return;
            }
            const normalized = (res?.posts ?? []).map(normalizeEcommerceProduct);
            setPosts(prev => (opts?.append ? [...prev, ...normalized] : normalized));
            setTotal(Number(res?.total ?? 0));
            setTotalPages(Number(res?.total_pages ?? 0));
        }).catch((e: any) => {
            if (activeRequestKeyRef.current !== requestKey) {
                return;
            }
            handleError(e);
        }).finally(() => {
            // Stale *data* is dropped by requestKey above; loading flags are owned
            // by the newest request (by generation). When the newest request settles
            // nothing else is in flight, so clear BOTH flags: a superseded fetch
            // (initial load overtaken by a refresh, or loadMore overtaken by a sort)
            // must not leave loading or isRefetching stuck true.
            if (generation !== fetchGenerationRef.current) {
                return;
            }
            setIsRefetching(false);
            setLoading(false);
        });
    };

    // Initial + reactive fetch when query knobs change
    useEffect(() => {
        if (skipReactiveFetchRef.current) {
            skipReactiveFetchRef.current = false;
            return;
        }
        // Explicit null query (e.g. empty product search) — idle, no REST call
        if (!wp_query) {
            if (abortControllerRef.current) {
                abortControllerRef.current.abort();
                abortControllerRef.current = null;
            }
            setPosts([]);
            setTotal(0);
            setTotalPages(0);
            setError(null);
            setLoading(false);
            setIsRefetching(false);
            return;
        }
        fetch();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, effectiveDeps);

    // Setup event listener for external refresh events (mount/unmount only)
    useEffect(() => {
        const handleProductsRefresh = () => {
            refetch(true);
        };
        //if (typeof window === 'undefined') return

        window.addEventListener("WVC_PRODUCTS_REFRESH", handleProductsRefresh);

        // Cleanup function
        return () => {
            if (abortControllerRef.current) {
                abortControllerRef.current.abort();
            }
            window.removeEventListener("WVC_PRODUCTS_REFRESH", handleProductsRefresh);
        };
    }, []);

    const refetch = (flushCache = false): Promise<void> => {
        // Create new AbortController for refetch
        if (abortControllerRef.current) {
            abortControllerRef.current.abort();
        }
        abortControllerRef.current = new AbortController();
        return fetch({ refresh: true, flushCache });
    };

    // Expose convenient setters to children
    const setWPQuery: EcommerceProductsContextType["setWPQuery"] = (next) => {
        // Query mutations (filters, pagination, etc.) must use replace semantics.
        skipReactiveFetchRef.current = false;
        setWPQueryState(prev => {
            if (typeof next === "function") {
                return (next as any)(prev);
            } else {
                return next;
            }
        });
    };

    // setQuery is shallow: merges top-level keys only; does not deep-merge into tax_query / meta_query / date_query
    const setQuery: EcommerceProductsContextType["setQuery"] = (next) => {
        skipReactiveFetchRef.current = false;
        setWPQueryState(prev => {
            const currentQuery = prev || new WP_Query({});
            const nextObj = typeof next === "function" ? undefined : next;
            const updatedVars = typeof next === "function"
                ? (next as any)(currentQuery.query_vars)
                : { ...currentQuery.query_vars, ...next };
            const newQuery = new WP_Query(updatedVars);
            // Preserve tax_query, meta_query, date_query from prev when caller did not pass them at top level
            if (prev) {
                if (!(nextObj && "tax_query" in nextObj)) newQuery.tax_query = prev.tax_query;
                if (!(nextObj && "meta_query" in nextObj)) newQuery.meta_query = prev.meta_query;
                if (!(nextObj && "date_query" in nextObj)) newQuery.date_query = prev.date_query;
            }
            return newQuery;
        });
    };

    const setEmbeds: EcommerceProductsContextType["setEmbeds"] = (next) => {
        setEmbedsState(prev => (typeof next === "function" ? (next as any)(prev) : next));
    };

    const setFields: EcommerceProductsContextType["setFields"] = (next) => {
        setFieldsState(prev => (typeof next === "function" ? (next as any)(prev) : next));
    };

    // Pagination helpers derived from current query & totals
    const currentPage = Number(query?.paged ?? query?.page ?? 1) || 1;
    const hasNext = currentPage < (totalPages || 0);
    const hasPrev = currentPage > 1;

    const setPage = (page: number) => {
        // Standard pagination must always replace via the reactive fetch.
        skipReactiveFetchRef.current = false;
        const pageNum = Math.max(1, Math.floor(page || 1));
        setWPQueryState(prev => {
            const vars = { ...(prev?.query_vars ?? {}), paged: pageNum };
            const newQuery = new WP_Query(vars);
            // Preserve tax_query, meta_query, date_query (they live outside query_vars after parse)
            if (prev) {
                newQuery.tax_query = prev.tax_query;
                newQuery.meta_query = prev.meta_query;
                newQuery.date_query = prev.date_query;
            }
            return newQuery;
        });
    };

    const setSorting: EcommerceProductsContextType["setSorting"] = (orderby, order) => {
        skipReactiveFetchRef.current = false;
        setWPQueryState(prev => {
            const vars = { ...(prev?.query_vars ?? {}), orderby, order, paged: 1 };
            const newQuery = new WP_Query(vars);
            if (prev) {
                newQuery.tax_query = prev.tax_query;
                newQuery.meta_query = prev.meta_query;
                newQuery.date_query = prev.date_query;
            }
            return newQuery;
        });
    };

    const nextPage = () => hasNext && setPage(currentPage + 1);
    const prevPage = () => hasPrev && setPage(currentPage - 1);
    
    // Load more: fetches next page and appends to existing posts
    const loadMore = async (): Promise<void> => {
        if (!hasNext || isRefetching) return;
        const nextPageNum = currentPage + 1;
        await fetch({
            wp_query: { paged: nextPageNum },
            append: true,
            refresh: true,
        });
        // Track the loaded page for hasNext without triggering a replace fetch.
        skipReactiveFetchRef.current = true;
        setWPQueryState(prev => {
            if (!prev) return new WP_Query({ paged: nextPageNum });
            const vars = { ...prev.query_vars, paged: nextPageNum };
            const newQuery = new WP_Query(vars);
            if (prev) {
                newQuery.tax_query = prev.tax_query;
                newQuery.meta_query = prev.meta_query;
                newQuery.date_query = prev.date_query;
            }
            return newQuery;
        });
    };

    const value: EcommerceProductsContextType = useMemo(() => ({
        // data
        posts,
        total,
        totalPages,

        // status
        loading,
        isRefetching,
        error,

        // state
        wp_query,
        query,
        embeds: embedsState,
        fields: fieldsState,

        // setters
        setWPQuery,
        setQuery,
        setEmbeds,
        setFields,

        // pagination
        hasNext,
        hasPrev,
        currentPage,
        setPage,
        nextPage,
        prevPage,
        loadMore,
        setSorting,

        // network
        refetch,
        fetch,
    }), [
        posts,
        total,
        totalPages,
        loading,
        isRefetching,
        error,
        wp_query,
        query,
        embedsState,
        fieldsState,
        hasNext,
        hasPrev,
        currentPage,
    ]);

    return (
        <EcommerceProductsContext.Provider value={value}>
            <div
                {...divProps}
                data-wvc-dynamic="EcommerceProductsProvider"
            >
                {shouldRenderPosts && children}
            </div>
        </EcommerceProductsContext.Provider>
    );
};

export {
    WordPressEcommerceProductsProvider,
    WordPressEcommerceProductsProvider as EcommerceProductsProvider,
};
export { useEcommerceProducts } from "./WordPressEcommerceProductsContext";
export { ProductSortDropdown, type ProductSortOption } from "./ProductSortDropdown";
export { ProductsFilter, type ProductsFilterProps, type ProductsFilterTemplates, DEFAULT_TEMPLATES as DEFAULT_FILTER_TEMPLATES } from "./ProductsFilter";
