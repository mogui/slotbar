// Slotbar: Chat Unread state (SPEC 8.4). Reports the favicon href; native maps _dot_ / _no_dot_.
(() => {
  if (window.top !== window) return;
  const handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.slotbarUnread;
  if (!handler) return;
  let last = null;

  function check() {
    const icon = document.querySelector('link[rel~="icon"]');
    const href = icon ? icon.href : null;
    if (href === last) return;
    last = href;
    handler.postMessage({ kind: "chat", href });
  }

  new MutationObserver(check).observe(document.documentElement, { childList: true, subtree: true, attributes: true, attributeFilter: ["href", "rel"] });
  check();
})();
