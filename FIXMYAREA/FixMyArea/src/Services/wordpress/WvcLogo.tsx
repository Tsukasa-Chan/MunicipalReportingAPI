import { useEffect, useState } from 'react';

interface WvcLogoProps {
  className?: string;
  style?: React.CSSProperties;
}

declare const wvcClient:
  | { getLogo?: (skipCache?: boolean) => Promise<{ attachment_id: number; url: string } | null> }
  | undefined;

interface LogoState {
  svgContent: string | null;
  imgUrl: string | null;
}

async function fetchLogoData(url: string): Promise<LogoState> {
  // Only SVG needs fetching (to inline it for theme recoloring). Everything else
  // renders as a plain <img>, which loads cross-origin without a CORS preflight.
  // We must NOT rely on a fixed raster allow-list: WordPress transcodes large
  // uploads to avif/webp (e.g. logo-scaled.avif), and fetch()-ing those from a
  // different origin (the editor preview) is CORS-blocked. So treat anything that
  // is not an .svg URL as an image and render it directly.
  if (!/\.svg(\?|#|$)/i.test(url)) {
    return { svgContent: null, imgUrl: url };
  }
  try {
    const res = await fetch(url);
    if (!res.ok) return { svgContent: null, imgUrl: url };
    const contentType = res.headers.get('Content-Type') ?? '';
    if (contentType.includes('image/svg+xml')) {
      const raw = await res.text();
      // Only generated logos (a single fill color) are recolored to the theme via
      // currentColor. A user-supplied brand SVG with multiple fill colors keeps its
      // original colors untouched.
      const distinctFills = new Set(
        (raw.match(/\bfill="([^"]*)"/gi) ?? [])
          .map((m) => m.replace(/\bfill="([^"]*)"/i, '$1').trim().toLowerCase())
          .filter((c) => c && c !== 'none' && c !== 'currentcolor'),
      );
      const isMonochrome = distinctFills.size <= 1;
      // Strip hardcoded width/height/style from root <svg> so the component
      // controls sizing, then inject height:100%;width:auto so it fills its container.
      let svgContent = raw;
      if (isMonochrome) {
        svgContent = svgContent.replace(/\bfill="[^"]*"/g, 'fill="currentColor"');
      }
      svgContent = svgContent.replace(/<svg\b([^>]*)>/i, (_, attrs) => {
        const cleaned = attrs.replace(/\s+(?:width|height|style)="[^"]*"/g, '');
        return `<svg${cleaned} style="height:100%;width:auto;display:block">`;
      });
      return { svgContent, imgUrl: null };
    }
    return { svgContent: null, imgUrl: url };
  } catch {
    // SVG fetch failed (e.g. cross-origin CORS in the editor preview) — fall back
    // to rendering the URL as a plain <img> rather than showing no logo at all.
    return { svgContent: null, imgUrl: url };
  }
}

export function WvcLogo({ className = 'h-10 w-auto', style }: WvcLogoProps) {
  const [logo, setLogo] = useState<LogoState>({ svgContent: null, imgUrl: null });

  useEffect(() => {
    if (typeof wvcClient === 'undefined' || typeof wvcClient?.getLogo !== 'function') return;
    
    // Fetch logo on mount — getLogo() returns cached data instantly on first load,
    // falls back to REST if not pre-loaded
    wvcClient.getLogo().then((meta) => {
      if (meta?.url) fetchLogoData(meta.url).then(setLogo);
    });

    // Re-fetch when WordPress updates the logo
    const handleRefresh = () => {
      wvcClient?.getLogo?.(true)?.then((updated) => {
        if (updated?.url) fetchLogoData(updated.url).then(setLogo);
      });
    };
    //if (typeof window === 'undefined') return

    window.addEventListener('WVC_LOGO_REFRESH', handleRefresh);
    return () => window.removeEventListener('WVC_LOGO_REFRESH', handleRefresh);
  }, []);

  if (logo.svgContent) {
    return (
      <span className={className} style={{ display: 'inline-block', ...style }} data-wvc-role="logo">
        <span
          style={{ color: 'var(--color-logo)', display: 'block', height: '100%' }}
          dangerouslySetInnerHTML={{ __html: logo.svgContent }}
        />
      </span>
    );
  }

  if (logo.imgUrl) {
    return (
      <span className={className} style={{ display: 'inline-block', ...style }} data-wvc-role="logo">
        <img
          src={logo.imgUrl}
          alt="Logo"
          style={{ display: 'block', height: '100%', width: 'auto' }}
        />
      </span>
    );
  }

  return null;
}