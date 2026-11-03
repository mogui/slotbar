// Reports the best link[rel~="icon"] URL (or null) to the Slot, at load and whenever the icon links change (SPEC 4.4).
(() => {
  const handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.slotbarFavicon;
  if (!handler) return;

  // Largest declared size wins; "any" (scalable) beats every fixed size; ties go to the last link.
  const score = (link) => {
    const sizes = (link.getAttribute("sizes") || "").toLowerCase().split(/\s+/);
    if (sizes.includes("any")) return Infinity;
    return Math.max(0, ...sizes.map((s) => parseInt(s.split("x")[0], 10) || 0));
  };

  const best = () => {
    let chosen = null;
    for (const link of document.querySelectorAll('link[rel~="icon" i]')) {
      if (!link.href) continue;
      if (!chosen || score(link) >= score(chosen)) chosen = link;
    }
    return chosen ? chosen.href : null;
  };

  let last;
  const report = () => {
    const href = best();
    if (href === last) return;
    last = href;
    handler.postMessage(href);
  };

  new MutationObserver((mutations) => {
    for (const m of mutations) {
      const nodes = [m.target, ...m.addedNodes, ...m.removedNodes];
      if (nodes.some((n) => n.nodeName === "LINK")) { report(); return; }
    }
  }).observe(document, { subtree: true, childList: true, attributes: true, attributeFilter: ["href", "rel", "sizes"] });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", report, { once: true });
  } else {
    report();
  }
})();
