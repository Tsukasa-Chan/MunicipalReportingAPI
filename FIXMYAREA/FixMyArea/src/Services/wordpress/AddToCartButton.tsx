import React, { useState } from "react";

import { cn } from "@/Helpers/utils";
import { Button } from "@/components/ui/button";
import { Link } from "@/components/common/Link";
import { Loader } from "lucide-react";
import type { EcommerceProduct } from "@/Models/types";
import { isExternalProduct, isVariableProduct } from "./ecommerceProductUtils";

declare global {
	const wvcClient: any;
}

export interface AddToCartButtonProps extends React.HTMLAttributes<HTMLDivElement> {
	productId: number | string;
	/** When provided without variationId, variable products show a "Choose variant" link to the product page. */
	product?: EcommerceProduct;
	/** When set, this ID is sent to the cart (WooCommerce resolves parent/attributes). */
	variationId?: number | string;
	text?: React.ReactNode;
	loadingText?: React.ReactNode;
	icon?: React.ReactNode;
	showQuantity?: boolean;
	minQuantity?: number;
	maxQuantity?: number;
	buttonClassName?: string;
	quantityClassName?: string;
	variant?: "default" | "destructive" | "outline" | "secondary" | "ghost" | "link";
	size?: "default" | "sm" | "lg" | "icon";
	disabled?: boolean;
}

export const AddToCartButton: React.FC<AddToCartButtonProps> = ({
	productId,
	product,
	variationId,
	className,
	text = "Add to Cart",
	loadingText = "Adding...",
	icon,
	showQuantity = true,
	minQuantity = 1,
	maxQuantity = 99,
	buttonClassName,
	quantityClassName,
	variant = "default",
	size = "default",
	disabled = false,
	...props
}) => {
	const [quantity, setQuantity] = useState(minQuantity);
	const [isAdding, setIsAdding] = useState(false);
	const [error, setError] = useState<string | null>(null);
	const [successMessage, setSuccessMessage] = useState<string | null>(null);

	if (product && isExternalProduct(product)) {
		const externalUrl = product.product_url;
		if (!externalUrl) {
			return null;
		}

		const externalLabel = product.button_text?.trim() || "Buy product";

		return (
			<div className={cn("flex flex-col gap-2", className)} {...props}>
				<div className="flex items-center gap-2">
					<Button
						asChild
						className={cn(
							"flex-1 gap-2",
							buttonClassName,
							disabled && "pointer-events-none opacity-50"
						)}
						variant={variant}
						size={size}
					>
						<a
							href={externalUrl}
							target="_blank"
							rel="noopener noreferrer"
							onClick={(e) => e.stopPropagation()}
						>
							{icon}
							{externalLabel}
						</a>
					</Button>
				</div>
			</div>
		);
	}

	if (product && isVariableProduct(product) && variationId == null) {
		if (!product.link) {
			return null;
		}

		return (
			<div className={cn("flex flex-col gap-2", className)} {...props}>
				<div className="flex items-center gap-2">
					<Button
						asChild
						className={cn(
							"flex-1 gap-2",
							buttonClassName,
							disabled && "pointer-events-none opacity-50"
						)}
						variant={variant}
						size={size}
					>
						<Link to={product.link} onClick={(e) => e.stopPropagation()}>
							{icon}
							Choose variant
						</Link>
					</Button>
				</div>
			</div>
		);
	}

	const decrement = () => setQuantity(Math.max(minQuantity, quantity - 1));
	const increment = () => setQuantity(Math.min(maxQuantity, quantity + 1));

	const handleAddToCart = async () => {
		setIsAdding(true);
		setError(null);
		setSuccessMessage(null);

		try {
			if (wvcClient?.cart?.addToCart) {
				const cartProductId =
					variationId != null ? Number(variationId) : Number(productId);
				const response = await wvcClient.cart.addToCart({
					id: cartProductId,
					quantity,
				});

				if (response?.success) {
					document.dispatchEvent(new Event("wvc_cart_updated"));
					setSuccessMessage(response.message || "Product added to cart!");
					setTimeout(() => setSuccessMessage(null), 3000);
				} else {
					setError(response?.message || "Failed to add product to cart");
				}
			} else {
				console.error("wvcClient.cart.addToCart is not available");
				setError("Cart functionality unavailable");
			}
		} catch (err: any) {
			console.error("Add to cart error:", err);
			setError(err.message || "Failed to add product.");
		} finally {
			setIsAdding(false);
		}
	};

	return (
		<div className={cn("flex flex-col gap-2", className)} {...props}>
			<div className="flex items-center gap-2">
				{showQuantity && (
					<div className={cn("flex items-center border rounded-md", quantityClassName)}>
						<button
							className="px-3 py-1 hover:bg-gray-100 disabled:opacity-50"
							onClick={decrement}
							disabled={isAdding || disabled || quantity <= minQuantity}
							type="button"
						>
							-
						</button>
						<span className="px-2 py-1 min-w-[2rem] text-center">{quantity}</span>
						<button
							className="px-3 py-1 hover:bg-gray-100 disabled:opacity-50"
							onClick={increment}
							disabled={isAdding || disabled || quantity >= maxQuantity}
							type="button"
						>
							+
						</button>
					</div>
				)}

				<Button
					onClick={handleAddToCart}
					disabled={isAdding || disabled}
					className={cn("flex-1 gap-2", buttonClassName)}
					variant={variant}
					size={size}
				>
					{isAdding ? (
						<>
							<Loader className="h-4 w-4 animate-spin" aria-hidden="true" />
							{loadingText}
						</>
					) : (
						<>
							{icon}
							{text}
						</>
					)}
				</Button>
			</div>

			{successMessage && (
				<p
					className="text-sm text-green-600 animate-in fade-in slide-in-from-top-1 [&_a]:underline [&_a]:font-medium"
					dangerouslySetInnerHTML={{ __html: successMessage }}
				/>
			)}

			{error && (
				<p
					className="text-sm text-red-600 animate-in fade-in slide-in-from-top-1 [&_a]:underline [&_a]:font-medium"
					dangerouslySetInnerHTML={{ __html: error }}
				/>
			)}
		</div>
	);
};
