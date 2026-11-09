import React from "react";

import { WordPressBlock } from "./WordPressBlock";
import { WOOCOMMERCE_ACCOUNT_BLOCK_HTML } from "./woocommerceAccountBlockHtml";

export type WooCommerceAccountBlockProps = {
    className?: string;
};

export function WooCommerceAccountBlock({ className }: WooCommerceAccountBlockProps) {
    return (
        <WordPressBlock html={WOOCOMMERCE_ACCOUNT_BLOCK_HTML} className={className} />
    );
}
