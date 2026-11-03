// Slotbar: Gmail Unread state (SPEC 8.4). Inbox DOM count; Atom feed only while the DOM count is missing.
// Runs only in the Slot's own page: Child windows (pop-out compose) share this script and get a false reply.
(async () => {
  if (window.top !== window) return;
  const handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.slotbarUnread;
  if (!handler) return;
  if (!(await handler.postMessage({ kind: "isSlotPage" }))) return;
  const STARTUP_GRACE_MS = 15000;
  const ATOM_INTERVAL_MS = 60000;
  const startedAt = Date.now();
  let lastPosted = null;
  let atomTimer = null;
  let scheduled = false;

  function post(source, count) {
    const key = source + ":" + count;
    if (key === lastPosted) return;
    lastPosted = key;
    handler.postMessage({ kind: "gmail", source, count });
  }

  // The number shown next to the Inbox link, in the row that holds only that link; none shown = 0.
  function domCount() {
    const link = document.querySelector('a[href*="#inbox"]');
    if (!link) return null;
    let row = link;
    while (row.parentElement && row.parentElement.querySelectorAll("a[href]").length === 1) row = row.parentElement;
    for (const el of row.querySelectorAll("*")) {
      if (el.children.length) continue;
      const text = (el.textContent || "").trim().replace(/[.,   ]/g, "");
      if (/^\d+$/.test(text)) return parseInt(text, 10);
    }
    return 0;
  }

  function atomURL() {
    const account = location.pathname.match(/^\/mail\/u\/\d+/);
    return (account ? account[0] : "/mail") + "/feed/atom";
  }

  async function readAtom() {
    try {
      const response = await fetch(atomURL(), { credentials: "include", cache: "no-store" });
      if (!response.ok) throw new Error("HTTP " + response.status);
      const xml = new DOMParser().parseFromString(await response.text(), "application/xml");
      const full = xml.querySelector("fullcount");
      const count = full ? parseInt(full.textContent, 10) : NaN;
      if (isNaN(count)) throw new Error("no fullcount");
      if (atomTimer !== null) post("atom", count);
    } catch (_) {
      if (atomTimer !== null) post("failed", 0);
    }
  }

  function check() {
    scheduled = false;
    const count = domCount();
    if (count !== null) {
      if (atomTimer !== null) { clearInterval(atomTimer); atomTimer = null; }
      post("dom", count);
    } else if (atomTimer === null && Date.now() - startedAt >= STARTUP_GRACE_MS) {
      atomTimer = setInterval(readAtom, ATOM_INTERVAL_MS);
      readAtom();
    }
  }

  function schedule() {
    if (scheduled) return;
    scheduled = true;
    setTimeout(check, 500);
  }

  new MutationObserver(schedule).observe(document.documentElement, { childList: true, subtree: true, characterData: true });
  setTimeout(check, STARTUP_GRACE_MS);
  schedule();
})();
