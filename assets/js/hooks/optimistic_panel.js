/**
 * @file OptimisticPanel.js
 *
 * JavaScript hook for managing optimistic UI panel components (modals and slideovers).
 *
 * This hook implements a sophisticated state machine that handles the complex lifecycle
 * of optimistic UI panels, including:
 *
 * - Immediate client-side responses to user actions
 * - Server confirmation and synchronization
 * - Race condition handling between client and server
 * - Smooth transitions and ghost animations
 * - Focus management integration with Phoenix LiveView
 *
 * ## State Machine
 *
 * The hook manages seven distinct states:
 *
 * 1. **Closed** - Panel is hidden and inactive
 * 2. **Opening** - Panel is animating in, waiting for server confirmation
 * 3. **OpeningServerArrived** - Server confirmed open while client was opening
 * 4. **Open** - Panel is fully open and interactive
 * 5. **Closing** - Panel is closing optimistically
 * 6. **ClosingWaitingForServer** - Waiting for server to confirm close
 * 7. **ClosingWaitingForServerStateToOpen** - Server confirmed close but new open pending
 *
 * ## Event Handling
 *
 * The hook responds to these events:
 * - `REQUEST_OPEN` - User wants to open panel
 * - `REQUEST_CLOSE` - User wants to close panel
 * - `SERVER_REQUESTS_OPEN` - Server confirms panel should be open
 * - `SERVER_REQUESTS_CLOSE` - Server confirms panel should be closed
 * - `PANEL_OPEN_TRANSITION_END` - CSS transition completed
 *
 * ## Ghost Animations
 *
 * When content changes during panel lifecycle, the hook creates "ghost" elements
 * that animate out while new content animates in, providing seamless transitions.
 *
 * ## Focus Management
 *
 * Integrates with Phoenix LiveView's focus_wrap component and executes focus
 * commands when panels open to ensure proper accessibility.
 */

// --- Base State Class ---
class PanelState {
	constructor(panelContext) {
		this.panel = panelContext;
	}

	get name() {
		return this.constructor.name
			.substring(0, this.constructor.name.length - "State".length)
			.toLowerCase();
	}

	_getPanelId() {
		return this.panel && this.panel.panelIdForLog
			? this.panel.panelIdForLog
			: "UNKNOWN_PANEL";
	}

	onRequestOpen() {
		console.warn(
			`OptimisticPanel ${this._getPanelId()}: Event REQUEST_OPEN not handled in state ${this.name}`,
		);
	}
	onRequestClose() {
		console.warn(
			`OptimisticPanel ${this._getPanelId()}: Event REQUEST_CLOSE not handled in state ${this.name}`,
		);
	}
	onServerRequestsOpen() {
		console.warn(
			`OptimisticPanel ${this._getPanelId()}: Event SERVER_REQUESTS_OPEN not handled in state ${this.name}`,
		);
	}
	onServerRequestsClose() {
		console.warn(
			`OptimisticPanel ${this._getPanelId()}: Event SERVER_REQUESTS_CLOSE not handled in state ${this.name}`,
		);
	}
	onPanelOpenTransitionEnd() {
		console.warn(
			`OptimisticPanel ${this._getPanelId()}: Event PANEL_OPEN_TRANSITION_END not handled in state ${this.name}`,
		);
	}
	onEnter() {}
	onExit() {}
	onUpdate() {}
}

// --- Concrete State Implementations ---
class ClosedState extends PanelState {
	onEnter() {
		console.log(
			`OptimisticPanel DEBUG (${this._getPanelId()}): ClosedState.onEnter CALLED.`,
		);
		this.panel.closeInitiator = null;
		this.panel.hasCloseTransitionEnded = false;
	}
	onRequestOpen() {
		this.panel.transitionTo(this.panel.states.opening);
	}
	onServerRequestsOpen() {
		this.panel.transitionTo(this.panel.states.open, true);
	}
}

class OpeningState extends PanelState {
	onEnter() {
		this.panel.closeInitiator = null;

		this.panel.liveSocket.execJS(
			this.panel.el,
			this.panel.el.dataset.showLoading,
		);
		this.panel.liveSocket.execJS(
			this.panel.el,
			this.panel.el.dataset.showModal,
		);

		if (this.panel.panelContent && this.panel.onOpenTransitionEndEvent) {
			this.panel.panelContent.addEventListener(
				"transitionend",
				this.panel.onOpenTransitionEndEvent,
				{ once: true },
			);
		}
	}
	onPanelOpenTransitionEnd() {
		this.panel.transitionTo(this.panel.states.open);
	}
	onRequestClose() {
		this.panel.closeInitiator = "user";
		this.panel.transitionTo(this.panel.states.closing);
	}
	onServerRequestsClose() {
		this.panel.closeInitiator = "server";
		this.panel.transitionTo(this.panel.states.closing);
	}
	onServerRequestsOpen() {
		this.panel.transitionTo(this.panel.states.openingServerArrived);
	}
}

class OpeningServerArrivedState extends PanelState {
	onEnter() {
		console.log(
			`OptimisticPanel DEBUG (${this._getPanelId()}): OpeningServerArrivedState.onEnter CALLED.`,
		);
	}
	onPanelOpenTransitionEnd() {
		this.panel.transitionTo(this.panel.states.open);
	}
	onRequestClose() {
		this.panel.closeInitiator = "user";
		this.panel.transitionTo(this.panel.states.closing);
	}
	onServerRequestsClose() {
		this.panel.closeInitiator = "server";
		this.panel.transitionTo(this.panel.states.closing);
	}
	onUpdate() {
		this.panel.runFlipAnimation(
			this.panel.getMainContentInner ? this.panel.getMainContentInner() : null,
			this.panel.getLoadingContent ? this.panel.getLoadingContent() : null,
		);
	}
}

class OpenState extends PanelState {
	onEnter(isNonOptimistic = false) {
		this.panel.closeInitiator = null;

		if (isNonOptimistic) {
			this.panel.liveSocket.execJS(
				this.panel.el,
				this.panel.el.dataset.showModal,
			);
		}

		// Apply focus to first focusable element
		if (this.panel.el.dataset.focusFirst && this.panel.liveSocket) {
			this.panel.liveSocket.execJS(
				this.panel.el,
				this.panel.el.dataset.focusFirst,
			);
		}
	}
	onExit() {
		// Focus management is handled by LiveView's focus_wrap
	}
	onRequestClose() {
		this.panel.closeInitiator = "user";
		this.panel.transitionTo(this.panel.states.closing);
	}
	onServerRequestsClose() {
		this.panel.closeInitiator = "server";
		this.panel.transitionTo(this.panel.states.closed);
	}
}

class ClosingState extends PanelState {
	onEnter() {
		if (this.panel.panelContent && this.panel.onOpenTransitionEndEvent) {
			this.panel.panelContent.removeEventListener(
				"transitionend",
				this.panel.onOpenTransitionEndEvent,
			);
		}

		console.log(
			`OptimisticPanel DEBUG (${this._getPanelId()} - ClosingState.onEnter): Client close ('${this.panel.closeInitiator}'). Setting up ghost.`,
		);
		this.panel._setupGhostElementAnimation();
		this.panel.transitionTo(this.panel.states.closingWaitingForServerState);
	}
}

class ClosingWaitingForServerState extends PanelState {
	onEnter() {
		console.log(
			`OptimisticPanel DEBUG (${this._getPanelId()}): ClosingWaitingForServerState.onEnter - waiting for server confirmation.`,
		);
	}
	onRequestOpen() {
		console.log(
			`OptimisticPanel DEBUG (${this._getPanelId()} - ClosingWaitingForServerState.onRequestOpen): Open requested while waiting for server. Transitioning to ClosingWaitingForServerStateToOpen.`,
		);
		this.panel.transitionTo(
			this.panel.states.closingWaitingForServerStateToOpen,
		);
	}
	onServerRequestsClose() {
		console.log(
			`OptimisticPanel DEBUG (${this._getPanelId()} - ClosingWaitingForServerState.onServerRequestsClose): Server confirmed close. Transitioning to closed.`,
		);
		this.panel.closeInitiator = "server";
		this.panel.transitionTo(this.panel.states.closed);
	}
}

class ClosingWaitingForServerStateToOpen extends PanelState {
	onEnter() {
		console.log(
			`OptimisticPanel DEBUG (${this._getPanelId()}): ClosingWaitingForServerStateToOpen.onEnter - waiting for server confirmation then will open.`,
		);
	}
	onServerRequestsClose() {
		console.log(
			`OptimisticPanel DEBUG (${this._getPanelId()} - ClosingWaitingForServerStateToOpen.onServerRequestsClose): Server confirmed close. Immediately transitioning to opening.`,
		);
		this.panel.closeInitiator = "server";
		this.panel.transitionTo(this.panel.states.opening);
	}
}

// --- OptimisticPanel Hook ---
const OptimisticPanel = {
	mounted() {
		this.wrapper = this.el;
		const id = this.wrapper.id;
		if (!id) {
			console.error("OptimisticPanel FATAL: Hook element requires an ID.");
			return;
		}
		this.panelIdForLog = `#${id}`;

		this.overlay = this.wrapper.querySelector(`#${id}-overlay`);
		this.panelContent = this.wrapper.querySelector(`#${id}-panel_content`);
		this.getMainContentContainer = () =>
			this.wrapper.querySelector(`#${id}-main_content`);
		this.getLoadingContent = () =>
			this.wrapper.querySelector(`#${id}-loading_content`);
		this.getMainContentInner = () =>
			this.wrapper.querySelector(`#${id}-main_content_inner`);

		// Validate required elements and attributes
		if (!this.overlay || !this.panelContent) {
			console.error(
				`OptimisticPanel FATAL (${this.panelIdForLog}): Core elements missing (overlay or panelContent).`,
			);
			return;
		}

		const ds = this.wrapper.dataset;
		const pcds = this.panelContent.dataset;

		// Validate required dataset attributes
		if (!ds.showModal || !ds.hideModal || !ds.showLoading || !ds.hideLoading) {
			console.error(
				`OptimisticPanel FATAL (${this.panelIdForLog}): Required dataset attributes missing.`,
			);
			return;
		}
		this.config = {
			duration: Number(ds.duration) || 300,
			closeOnEscape: ds.closeOnEscape !== "false",
			closeOnOverlayClick: ds.closeOnOverlayClick !== "false",
			isModal: pcds.isModal === "true",
			slideFrom: ds.slideFrom || (pcds.isModal === "true" ? null : "left"),
		};
		this.effectiveGhostAnimationDuration = this.config.duration;
		this.ghostElement = null;
		this.closeInitiator = null;
		this.hasCloseTransitionEnded = false;

		this.onOpenTransitionEndEvent = () => {
			this.processPanelEvent("PANEL_OPEN_TRANSITION_END");
		};

		this.states = {
			closed: new ClosedState(this),
			opening: new OpeningState(this),
			openingServerArrived: new OpeningServerArrivedState(this),
			open: new OpenState(this),
			closing: new ClosingState(this),
			closingWaitingForServerState: new ClosingWaitingForServerState(this),
			closingWaitingForServerStateToOpen:
				new ClosingWaitingForServerStateToOpen(this),
		};
		this.currentState = null;
		this.transitionTo(this.states.closed);

		this.wrapper.addEventListener("open-panel", () => {
			this.processPanelEvent("REQUEST_OPEN");
		});
		this.wrapper.addEventListener("close-panel", () => {
			this.processPanelEvent("REQUEST_CLOSE");
		});
		if (this.config.closeOnEscape) {
			this.escapeKeyListener = (e) => {
				if (
					e.key === "Escape" &&
					this.currentState &&
					(this.currentState.name === "open" ||
						this.currentState.name === "opening")
				) {
					// Execute the on_close event instead of direct panel event
					const onCloseCmd = this.el.dataset.onClose;
					if (onCloseCmd && this.liveSocket) {
						this.liveSocket.execJS(this.el, onCloseCmd);
					}
				}
			};
			document.addEventListener("keydown", this.escapeKeyListener);
		}
		this.el.__optimisticPanelInstance = this;
	},

	transitionTo(newState, ...entryArgs) {
		const panelId = this.panelIdForLog || "UNKNOWN_PANEL_IN_TRANSITION";
		const oldStateName = this.currentState ? this.currentState.name : "initial";
		if (this.currentState)
			try {
				this.currentState.onExit();
			} catch (e) {
				console.error(
					`OptimisticPanel ERROR (${panelId}): Uncaught error in onExit for state ${oldStateName}:`,
					e,
				);
			}
		console.log(
			`OptimisticPanel ${panelId}: Transitioning from '${oldStateName}' to '${newState ? newState.name : "undefined_newState"}'`,
		);
		this.currentState = newState;
		if (this.currentState)
			try {
				this.currentState.onEnter(...entryArgs);
			} catch (e) {
				console.error(
					`OptimisticPanel ERROR (${panelId}): Uncaught error in onEnter for state ${this.currentState.name}:`,
					e,
				);
			}
	},

	processPanelEvent(eventName) {
		const panelId = this.panelIdForLog || "UNKNOWN_PANEL_IN_PROCESSPANEVENT";
		console.log(
			`OptimisticPanel ${this.panelIdForLog}: State '${this.currentState.name}' received event '${eventName}' via processPanelEvent`,
		);
		const camelCaseEventName = eventName
			.toLowerCase()
			.split("_")
			.map((part) => part.charAt(0).toUpperCase() + part.slice(1))
			.join("");
		const handlerMethodName = `on${camelCaseEventName}`;
		try {
			this.currentState[handlerMethodName]();
		} catch (e) {
			console.error(
				`OptimisticPanel ERROR (${this.panelIdForLog}): Error executing handler ${handlerMethodName} in state ${this.currentState.name}:`,
				e,
			);
		}
	},

	_setupGhostElementAnimation() {
		const originalMainContentInner = this.getMainContentInner();
		if (!originalMainContentInner) {
			console.warn(
				`OptimisticPanel ${this.panelIdForLog}: Ghost setup - originalMainContentInner not found.`,
			);
			this.effectiveGhostAnimationDuration = this.config.duration;
			return;
		}

		this.ghostElement = originalMainContentInner.cloneNode(true);
		this.ghostElement.removeAttribute("phx-remove");
		Object.assign(this.ghostElement.style, {
			pointerEvents: "none",
			zIndex: "61",
		});
		this.ghostElement.className = originalMainContentInner.className;

		const mainContentContainer = this.getMainContentContainer();
		if (mainContentContainer) {
			originalMainContentInner.remove();
			mainContentContainer.appendChild(this.ghostElement);
		} else {
			console.error(
				`OptimisticPanel (${this.panelIdForLog}): main_content container not found, cannot append ghost. Appending to panelContent as fallback.`,
			);
			if (this.panelContent) this.panelContent.appendChild(this.ghostElement);
			else if (this.wrapper) this.wrapper.appendChild(this.ghostElement);
			else {
				this.ghostElement = null;
				return;
			}
		}

		if (this.el.dataset.hideModal && this.liveSocket) {
			requestAnimationFrame(() => {
				this.liveSocket.execJS(this.ghostElement, this.el.dataset.hideModal);
			});
		}
	},

	getImpliedServerEvent() {
		const newMainState =
			this.getMainContentContainer().dataset.activeIfOpen == "true";

		if (!this.previousMainState && newMainState) {
			return "SERVER_REQUESTS_OPEN";
		} else if (this.previousMainState && !newMainState) {
			return "SERVER_REQUESTS_CLOSE";
		}
		return null;
	},

	runFlipAnimation(mainInnerEl, loadEl) {
		if (
			!this.currentState ||
			!this._flipPreRect ||
			!this.panelContent ||
			!loadEl
		) {
			this._flipPreRect = null;
			return;
		}
		this.liveSocket.execJS(this.el, this.el.dataset.hideLoading);

		const firstRect = this._flipPreRect;
		const lastRect = this.panelContent.getBoundingClientRect();
		this._flipPreRect = null;

		if (
			Math.abs(firstRect.width - lastRect.width) < 1 &&
			Math.abs(firstRect.height - lastRect.height) < 1
		)
			return;

		const sX = lastRect.width === 0 ? 1 : firstRect.width / lastRect.width;
		const sY = lastRect.height === 0 ? 1 : firstRect.height / lastRect.height;
		const dX =
			firstRect.left - lastRect.left + (firstRect.width - lastRect.width) / 2;
		const dY =
			firstRect.top - lastRect.top + (firstRect.height - lastRect.height) / 2;

		loadEl.style.transition = "none";

		loadEl.style.transform = `scale(${1 / sX},${1 / sY})`;
		loadEl.style.transformOrigin = "top left";
		this.panelContent.style.setProperty("--flip-translate-x", `${dX}px`);
		this.panelContent.style.setProperty("--flip-translate-y", `${dY}px`);
		this.panelContent.style.setProperty("--flip-scale-x", sX);
		this.panelContent.style.setProperty("--flip-scale-y", sY);
		this.panelContent.style.setProperty("--flip-duration", `200ms`);

		this.panelContent.classList.add("transition-none", "origin-center");
		this.panelContent.style.transform = `translate(var(--flip-translate-x), var(--flip-translate-y)) scale(var(--flip-scale-x), var(--flip-scale-y))`;

		this.panelContent.offsetHeight;
		requestAnimationFrame(() => {
			this.panelContent.classList.remove("transition-none");
			this.panelContent.classList.add("transition-all", "ease-in-out");
			this.panelContent.style.transitionDuration = "var(--flip-duration)";
			this.panelContent.style.transform = "";

			this.panelContent.addEventListener(
				"transitionend",
				() => {
					this.panelContent.classList.remove(
						"transition-all",
						"ease-in-out",
						"origin-center",
					);
					this.panelContent.style.removeProperty("transition-duration");
					this.panelContent.style.removeProperty("--flip-translate-x");
					this.panelContent.style.removeProperty("--flip-translate-y");
					this.panelContent.style.removeProperty("--flip-scale-x");
					this.panelContent.style.removeProperty("--flip-scale-y");
					this.panelContent.style.removeProperty("--flip-duration");
				},
				{ once: true },
			);
		});
	},

	beforeUpdate() {
		console.log("Entering before update");
		this.previousMainState =
			this.getMainContentContainer().dataset.activeIfOpen == "true";

		if (
			this.currentState &&
			(this.currentState.name === "open" ||
				this.currentState.name === "opening") &&
			this.getLoadingContent() &&
			this.panelContent
		) {
			this._flipPreRect = this.panelContent.getBoundingClientRect();
		} else {
			this._flipPreRect = null;
		}
	},

	updated() {
		console.log("Entering updated");
		const eventToHandle = this.getImpliedServerEvent();
		if (eventToHandle) {
			this.processPanelEvent(eventToHandle);
		}

		this.currentState.onUpdate();
	},

	destroyed() {
		console.log(
			`OptimisticPanel ${this.panelIdForLog || "UNKNOWN_PANEL_DESTROYED"}: destroyed().`,
		);

		if (this.config && this.config.closeOnEscape && this.escapeKeyListener)
			document.removeEventListener("keydown", this.escapeKeyListener);
		if (this.panelContent && this.onOpenTransitionEndEvent)
			this.panelContent.removeEventListener(
				"transitionend",
				this.onOpenTransitionEndEvent,
			);
		if (this.el) delete this.el.__optimisticPanelInstance;
	},
};

export default OptimisticPanel;
