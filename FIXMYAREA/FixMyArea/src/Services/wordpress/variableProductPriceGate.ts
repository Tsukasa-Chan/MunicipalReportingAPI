type Listener = () => void;

const suppressedProductIds = new Set<string | number>();
const listeners = new Set<Listener>();

const notify = () => {
	listeners.forEach((listener) => listener());
};

/**
 * While VariableProductAddToCart is mounted for a variable product, hide sibling
 * ProductPrice nodes that would otherwise show the parent price range.
 */
export const suppressVariableParentPrice = (productId: string | number): (() => void) => {
	suppressedProductIds.add(productId);
	notify();
	return () => {
		suppressedProductIds.delete(productId);
		notify();
	};
};

export const isVariableParentPriceSuppressed = (productId: string | number): boolean =>
	suppressedProductIds.has(productId);

export const subscribeVariableParentPriceSuppressed = (listener: Listener): (() => void) => {
	listeners.add(listener);
	return () => {
		listeners.delete(listener);
	};
};
