import React, { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";

import { cn } from "@/Helpers/utils";
import type { EcommerceProduct, EcommerceProductVariation, EcommerceVariationAttributeSelection } from "@/Models/types";
import {
	fetchProductVariations,
	findMatchingVariation,
	getAttributeSelectionKey,
	getDefaultAttributeSelection,
	getVariationAttributeKeys,
	isAttributeSelectionComplete,
	isVariableProduct,
} from "./ecommerceProductUtils";
import { AddToCartButton } from "./AddToCartButton";
import { ProductPrice } from "./ProductPrice";
import { suppressVariableParentPrice } from "./variableProductPriceGate";
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { Loader } from "lucide-react";

export interface ProductVariationSelectorProps {
	product: EcommerceProduct;
	selection: EcommerceVariationAttributeSelection;
	onChange: (selection: EcommerceVariationAttributeSelection) => void;
	className?: string;
}

export const ProductVariationSelector: React.FC<ProductVariationSelectorProps> = ({
	product,
	selection,
	onChange,
	className,
}) => {
	const attributes = getVariationAttributeKeys(product);
	if (!isVariableProduct(product) || attributes.length === 0) {
		return null;
	}

	const handleChange = (attrKey: string, value: string) => {
		onChange({ ...selection, [attrKey]: value });
	};

	return (
		<div className={cn("space-y-4", className)}>
			{attributes.map((attr) => {
				const key = getAttributeSelectionKey(attr);
				const selected = selection[key] ?? "";
				return (
					<div key={key} className="space-y-2">
						<Label htmlFor={`variation-${product.id}-${key}`}>{attr.name}</Label>
						<Select value={selected || undefined} onValueChange={(val) => handleChange(key, val)}>
							<SelectTrigger id={`variation-${product.id}-${key}`} className="w-full">
								<SelectValue placeholder={`Select ${attr.name}`} />
							</SelectTrigger>
							<SelectContent>
								{attr.terms.map((term) => (
									<SelectItem key={`${key}-${term.slug}`} value={term.slug}>
										{term.name}
									</SelectItem>
								))}
							</SelectContent>
						</Select>
					</div>
				);
			})}
		</div>
	);
};

export type VariableProductResolutionState =
	| "idle"
	| "loading"
	| "ready"
	| "out_of_stock"
	| "no_match"
	| "error";

export interface VariableProductAddToCartProps extends React.HTMLAttributes<HTMLDivElement> {
	product: EcommerceProduct;
	showQuantity?: boolean;
	buttonClassName?: string;
	text?: React.ReactNode;
	variant?: "default" | "destructive" | "outline" | "secondary" | "ghost" | "link";
	size?: "default" | "sm" | "lg" | "icon";
	/**
	 * Fired whenever the resolved variation changes: the matched variation when a
	 * complete, in-stock selection resolves, or null when the selection is
	 * incomplete/unavailable. Use it to swap the product gallery to the selected
	 * variation's image, e.g. onVariationResolved={(v) => setActiveImage(v?.featured_image_url ?? null)}.
	 */
	onVariationResolved?: (variation: EcommerceProduct | null) => void;
}

export const VariableProductAddToCart: React.FC<VariableProductAddToCartProps> = ({
	product,
	showQuantity = true,
	buttonClassName,
	text = "Add to Cart",
	variant = "default",
	size = "default",
	className,
	onVariationResolved,
	...props
}) => {
	const [selection, setSelection] = useState<EcommerceVariationAttributeSelection>(() =>
		getDefaultAttributeSelection(product)
	);
	const [resolutionState, setResolutionState] = useState<VariableProductResolutionState>("idle");
	const [resolvedVariationId, setResolvedVariationId] = useState<number | string | null>(null);
	const [resolvedVariation, setResolvedVariation] = useState<EcommerceProduct | null>(null);
	const [errorMessage, setErrorMessage] = useState<string | null>(null);

	// Emit the resolved variation (or null) whenever it changes, using the latest
	// callback without re-firing on unrelated re-renders.
	const onVariationResolvedRef = useRef(onVariationResolved);
	useEffect(() => {
		onVariationResolvedRef.current = onVariationResolved;
	}, [onVariationResolved]);
	useEffect(() => {
		onVariationResolvedRef.current?.(resolvedVariation);
	}, [resolvedVariation]);

	const isVariable = isVariableProduct(product);

	// Hide sibling ProductPrice range for this variable product; only the selected
	// variation price (rendered below) should be visible on the product page.
	useLayoutEffect(() => {
		if (!isVariable) return;
		return suppressVariableParentPrice(product.id);
	}, [isVariable, product.id]);

	// Re-apply Store API default terms when the product or its attributes change.
	const attributesKey = useMemo(
		() => JSON.stringify(product.attributes ?? []),
		[product.attributes]
	);
	useEffect(() => {
		setSelection(getDefaultAttributeSelection(product));
		// product is read for defaults; identity churn is gated by id + attributesKey.
		// eslint-disable-next-line react-hooks/exhaustive-deps
	}, [product.id, attributesKey]);

	const selectionComplete = useMemo(
		() => isAttributeSelectionComplete(product, selection),
		[product, selection]
	);

	// Serialize the selection so the resolve effect keys on stable primitives
	// (product id + selection content) instead of fresh object identities. This
	// prevents the effect from re-running on unrelated re-renders and cancelling
	// its own in-flight resolution before it can commit.
	const selectionKey = useMemo(() => JSON.stringify(selection), [selection]);
	const productId = product.id;

	// Monotonic request id: only the most recently started resolution is allowed
	// to commit, which makes the result robust to out-of-order async completions.
	const requestIdRef = useRef(0);

	useEffect(() => {
		const requestId = ++requestIdRef.current;
		const isStale = () => requestId !== requestIdRef.current;

		const resolve = async () => {
			if (!isAttributeSelectionComplete(product, selection)) {
				setResolutionState("idle");
				setResolvedVariationId(null);
				setResolvedVariation(null);
				setErrorMessage(null);
				return;
			}

			setResolutionState("loading");
			setErrorMessage(null);

			try {
				const variations = await fetchProductVariations(product);
				if (isStale()) return;
				const match = findMatchingVariation(variations, product, selection);
				if (isStale()) return;

				if (!match) {
					setResolutionState("no_match");
					setResolvedVariationId(null);
					setResolvedVariation(null);
					return;
				}

				const inStock = match.is_in_stock !== false && match.stock_status !== "outofstock";
				setResolvedVariationId(match.id);
				setResolvedVariation(match);
				setResolutionState(inStock ? "ready" : "out_of_stock");
			} catch (err: any) {
				if (isStale()) return;
				setResolutionState("error");
				setResolvedVariationId(null);
				setResolvedVariation(null);
				setErrorMessage(err?.message ?? "Failed to load variation.");
			}
		};

		resolve();
		// product/selection are read via stable proxies (productId, selectionKey).
		// eslint-disable-next-line react-hooks/exhaustive-deps
	}, [productId, selectionKey]);

	if (!isVariableProduct(product)) {
		return (
			<AddToCartButton
				product={product}
				productId={product.id}
				showQuantity={showQuantity}
				buttonClassName={buttonClassName}
				text={text}
				variant={variant}
				size={size}
				className={className}
				{...props}
			/>
		);
	}

	return (
		<div className={cn("space-y-4", className)} {...props}>
			<ProductVariationSelector product={product} selection={selection} onChange={setSelection} />

			{resolvedVariation && (
				<ProductPrice
					product={resolvedVariation}
					as="p"
					className="text-lg font-semibold"
				/>
			)}

			{resolutionState === "loading" && (
				<p className="flex items-center gap-2 text-sm text-muted-foreground">
					<Loader className="h-4 w-4 animate-spin" aria-hidden="true" />
					Checking availability…
				</p>
			)}

			{resolutionState === "no_match" && selectionComplete && (
				<p className="text-sm text-muted-foreground">
					This combination is not available. Please choose different options.
				</p>
			)}

			{resolutionState === "out_of_stock" && (
				<p className="text-sm text-destructive">This variation is out of stock.</p>
			)}

			{resolutionState === "error" && errorMessage && (
				<p className="text-sm text-destructive">{errorMessage}</p>
			)}

			{resolutionState === "ready" && resolvedVariationId != null && (
				<AddToCartButton
					productId={product.id}
					variationId={resolvedVariationId}
					showQuantity={showQuantity}
					buttonClassName={buttonClassName}
					text={text}
					variant={variant}
					size={size}
					className="w-full"
				/>
			)}
		</div>
	);
};