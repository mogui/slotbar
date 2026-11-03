// Slotbar notification shim (SPEC 8.1): document start, all frames, page content world.
(() => {
  const handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.slotbarNotify;
  if (!handler) return;

  // Identifies this page instance, so a click only reaches the page that raised the notification.
  const pageId = (crypto.randomUUID && crypto.randomUUID()) || String(Math.random()).slice(2) + Date.now();
  const byId = new Map();

  class Notification extends EventTarget {
    constructor(title, options = {}) {
      super();
      if (arguments.length === 0) throw new TypeError("Failed to construct 'Notification': 1 argument required.");
      options = options || {};
      this.title = String(title);
      this.body = options.body == null ? "" : String(options.body);
      this.tag = options.tag == null ? "" : String(options.tag);
      this.silent = !!options.silent;
      this.icon = options.icon == null ? "" : String(options.icon);
      this.data = options.data === undefined ? null : options.data;
      this.onclick = null;
      this.onshow = null;
      this.onclose = null;
      this.onerror = null;
      this._id = null;
      this._closed = false;
      this._clickListeners = 0;
      this._posted = handler.postMessage({
        op: "show", title: this.title, body: this.body, tag: this.tag, silent: this.silent, pageId, data: jsonData(this.data),
      }).then((id) => {
        this._id = id;
        if (this._closed) {
          handler.postMessage({ op: "close", id });
        } else {
          byId.set(id, this);
          this._fire("show");
        }
      }, () => this._fire("error"));
    }

    addEventListener(type, listener, options) {
      if (type === "click" && listener) this._clickListeners++;
      super.addEventListener(type, listener, options);
    }

    close() {
      if (this._closed) return;
      this._closed = true;
      if (this._id != null) {
        byId.delete(this._id);
        handler.postMessage({ op: "close", id: this._id });
      }
      this._fire("close");
    }

    _fire(type) {
      const event = new Event(type, { cancelable: true });
      this.dispatchEvent(event);
      const listener = this["on" + type];
      if (typeof listener === "function") listener.call(this, event);
    }

    static get permission() { return "granted"; }
    static get maxActions() { return 0; }
    static requestPermission(callback) {
      if (typeof callback === "function") callback("granted");
      return Promise.resolve("granted");
    }
  }

  // `data` for the app's deep link when no page handler opens the conversation (SPEC 8.3).
  function jsonData(data) {
    try {
      const json = JSON.stringify(data);
      return json && json.length <= 8192 ? json : "";
    } catch (_) {
      return "";
    }
  }

  Object.defineProperty(window, "Notification", { value: Notification, writable: true, configurable: true });

  if (window.ServiceWorkerRegistration) {
    ServiceWorkerRegistration.prototype.showNotification = function (title, options) {
      return new Notification(title, options)._posted;
    };
  }

  // Called by the app when the user clicks a notification (SPEC 8.3): "handled" when the page listens for the
  // click, "unhandled" when nothing does (service worker notifications), false when the notification is gone.
  Object.defineProperty(window, "__slotbarNotificationClicked", {
    value: (id, page) => {
      if (page !== pageId) return false;
      const notification = byId.get(id);
      if (!notification) return false;
      const handled = typeof notification.onclick === "function" || notification._clickListeners > 0;
      notification._fire("click");
      return handled ? "handled" : "unhandled";
    },
  });
})();
