import {useEffect, useLayoutEffect, useRef, useState} from 'react'

type UseRevealOnScrollOptions = {
    once?: boolean
    threshold?: number | number[]
    rootMargin?: string
}

export function useRevealOnScroll<T extends HTMLElement = HTMLElement>({
                                                                           once = true,
                                                                           threshold = 0.2,
                                                                           rootMargin = '0px'
                                                                       }: UseRevealOnScrollOptions = {}) {
    const ref = useRef<T | null>(null)
    const [isVisible, setIsVisible] = useState(false)

    // Use layout effect on client, regular effect on server (SSR-safe)
    const useIsomorphicLayoutEffect =
        typeof window !== 'undefined' ? useLayoutEffect : useEffect

    // Check if element is already visible BEFORE first paint
    useIsomorphicLayoutEffect(() => {
        const node = ref.current
        if (!node || typeof window === 'undefined') return

        const rect = node.getBoundingClientRect()
        const alreadyVisible =
            rect.top < window.innerHeight &&
            rect.bottom > 0 &&
            rect.left < window.innerWidth &&
            rect.right > 0

        if (alreadyVisible) {
            setIsVisible(true)
        }
    }, [])

    // Set up IntersectionObserver for scroll-triggered reveals
    useEffect(() => {
        const node = ref.current
        if (!node || (once && isVisible)) return

        if (typeof IntersectionObserver === 'undefined') {
            setIsVisible(true)
            return
        }

        const observer = new IntersectionObserver(
            entries => {
                const entry = entries[0]

                if (entry?.isIntersecting) {
                    setIsVisible(true)
                    if (once) observer.unobserve(entry.target)
                } else if (!once) {
                    setIsVisible(false)
                }
            },
            {threshold, rootMargin}
        )

        observer.observe(node)
        return () => observer.disconnect()
    }, [once, rootMargin, threshold, isVisible])

    return {ref, isVisible}
}
