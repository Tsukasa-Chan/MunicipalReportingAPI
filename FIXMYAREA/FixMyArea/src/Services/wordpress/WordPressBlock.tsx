import { useRef, useEffect } from "react";

export function WordPressBlock({ html, className }: { html: string; className?: string }) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    // don't clobber server-populated markup or re-inject on every render
    if (el.childNodes.length > 0) return;

    const range = document.createRange();
    range.selectNodeContents(el);
    // parses the full string -> elements AND <!-- ... --> comment nodes
    el.appendChild(range.createContextualFragment(html));
  }, [html]);

  return <div ref={ref} className={className} />;
}