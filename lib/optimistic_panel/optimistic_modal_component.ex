defmodule OptimisticPanel.OptimisticModalComponent do
  @moduledoc """
  A full-screen modal dialog component with optimistic UI behavior.

  This component provides a centered modal dialog that appears over the main content with
  a backdrop overlay. It supports optimistic interactions, meaning the modal responds
  immediately to user actions while waiting for server confirmation.

  ## Features

  - **Optimistic UI**: Modal responds immediately to open/close actions
  - **Focus Management**: Automatic focus trapping using Phoenix LiveView's `focus_wrap`
  - **Loading States**: Separate loading and main content slots
  - **Ghost Animations**: Smooth transitions when content changes
  - **Accessibility**: Full ARIA support, keyboard navigation, and screen reader compatibility
  - **Customizable**: Configurable animations, durations, and close behaviors

  ## Usage

      import OptimisticPanel.OptimisticModalComponent

      <.optimistic_modal
        id="user-modal"
        if={@user_form}
        on_close={JS.push("close_user_form")}
        duration="400"
      >
        <:main :let={on_close}>
          <h2>Edit User</h2>
          <.form for={@user_form}>
            <!-- form fields -->
            <button type="button" phx-click={on_close}>Cancel</button>
            <button type="submit">Save</button>
          </.form>
        </:main>
        <:loading>
          <div class="animate-spin">Loading...</div>
        </:loading>
      </.optimistic_modal>

  ## Optimistic vs Non-Optimistic Behavior

  The modal's behavior depends on whether the `on_close` command dispatches events
  back to the LiveView:

  - **Optimistic**: `on_close` includes `JS.dispatch("close-panel", to: "#modal-id")`
    - Modal closes immediately, then server processes the close
    - Smooth, responsive user experience

  - **Non-Optimistic**: `on_close` only calls server (e.g., `JS.push("close")`)
    - Modal waits for server response before closing
    - More predictable but less responsive

  ## State Management

  The component uses a JavaScript state machine with these states:
  - `closed` - Modal is hidden
  - `opening` - Modal is animating in, waiting for server
  - `openingServerArrived` - Server confirmed while opening
  - `open` - Modal is fully open and interactive
  - `closing` - Modal is closing optimistically
  - `closingWaitingForServer` - Waiting for server close confirmation

  ## Accessibility

  - Uses `role="dialog"` and `aria-modal="true"`
  - Automatic focus management with `focus_wrap`
  - Supports `aria-labelledby` and `aria-describedby`
  - Escape key handling (configurable)
  - Overlay click to close (configurable)

  ## Ghost Animations

  When content changes during the modal's lifecycle, the component creates a "ghost"
  copy of the previous content and animates it out while the new content animates in.
  This provides seamless transitions without jarring content flashes.
  """

  use Phoenix.Component
  import Phoenix.Component

  attr(:id, :string, default: nil, doc: "Unique identifier for the modal")
  attr(:if, :any, default: false, doc: "Condition to show the modal")
  attr(:on_close, :any, default: nil, doc: "JavaScript command to execute when closing")
  attr(:duration, :string, default: "300", doc: "Animation duration in milliseconds")
  attr(:close_on_escape, :string, default: "true", doc: "Whether to close on escape key")

  attr(:close_on_overlay_click, :string,
    default: "true",
    doc: "Whether to close on overlay click"
  )

  slot(:main, required: true)
  slot(:loading, required: false)

  def optimistic_modal(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn ->
        "optimistic-modal-#{System.unique_integer([:monotonic, :positive])}"
      end)
      |> assign_new(:if, fn -> false end)
      |> assign_new(:on_close, fn ->
        Phoenix.LiveView.JS.dispatch("close-panel", to: "##{assigns.id}")
      end)
      # Default duration for panel/overlay wrapper
      |> assign_new(:duration, fn -> "300" end)
      |> assign_new(:close_on_escape, fn -> "true" end)
      |> assign_new(:close_on_overlay_click, fn -> "true" end)

    assigns =
      assigns
      |> assign(:show_main_content?, !!assigns.if)
      |> assign(
        :main_content_inner_phx_remove_js,
        Phoenix.LiveView.JS.remove_class("overflow-hidden", to: "body")
        |> Phoenix.LiveView.JS.set_attribute({"aria-hidden", "true"}, to: "##{assigns.id}")
        |> Phoenix.LiveView.JS.set_attribute({"aria-hidden", "true"},
          to: "##{assigns.id}-panel_content"
        )
        |> Phoenix.LiveView.JS.transition(
          {"transition-all duration-[300ms] ease-out", "opacity-100 scale-100",
           "opacity-0 scale-95"},
          time: assigns.duration,
          to: "##{assigns.id}-panel_content",
          blocking: false
        )
        |> Phoenix.LiveView.JS.transition(
          {"transition-opacity duration-[300ms] ease-out pointer-events-auto", "opacity-50",
           "opacity-0"},
          time: assigns.duration,
          to: "##{assigns.id}-overlay"
        )
      )
      |> assign(
        :main_content_inner_phx_add_js,
        Phoenix.LiveView.JS.add_class("overflow-hidden", to: "body")
        |> Phoenix.LiveView.JS.remove_attribute("aria-hidden", to: "##{assigns.id}")
        |> Phoenix.LiveView.JS.remove_attribute("aria-hidden", to: "##{assigns.id}-panel_content")
        |> Phoenix.LiveView.JS.transition(
          {"transition-all duration-[300ms] ease-out", "opacity-0 scale-95",
           "opacity-100 pointer-events-auto scale-100"},
          time: assigns.duration,
          to: "##{assigns.id}-panel_content",
          blocking: false
        )
        |> Phoenix.LiveView.JS.transition(
          {"transition-opacity duration-[300ms] ease-out", "opacity-0",
           "opacity-50 pointer-events-auto"},
          time: assigns.duration,
          to: "##{assigns.id}-overlay",
          blocking: false
        )
      )
      |> assign(
        :show_loading_js,
        Phoenix.LiveView.JS.remove_class("hidden", to: "##{assigns.id}-loading_content")
        |> Phoenix.LiveView.JS.remove_class("opacity-0", to: "##{assigns.id}-loading_content")
        |> Phoenix.LiveView.JS.add_class("opacity-100", to: "##{assigns.id}-loading_content")
      )
      |> assign(
        :hide_loading_js,
        Phoenix.LiveView.JS.transition(
          {"transition-opacity duration-[200ms]", "opacity-100", "opacity-0"},
          time: 200,
          to: "##{assigns.id}-loading_content",
          blocking: false
        )
        |> Phoenix.LiveView.JS.transition(
          {"transition-opacity duration-[200ms]", "opacity-0", "opacity-100"},
          time: 200,
          to: "##{assigns.id}-main_content",
          blocking: false
        )
      )
      |> assign(
        :focus_first_js,
        Phoenix.LiveView.JS.focus_first(to: "##{assigns.id}-panel_content")
      )

    ~H"""
    <div
      id={@id}
      class="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto pointer-events-none"
      phx-hook="OptimisticPanel"
      role="dialog"
      aria-modal="true"
      aria-hidden="true"
      data-duration={@duration}
      data-close-on-escape={@close_on_escape}
      data-close-on-overlay-click={@close_on_overlay_click}
      data-on-close={@on_close}
      data-show-modal={@main_content_inner_phx_add_js}
      data-show-loading={@show_loading_js}
      data-hide-loading={@hide_loading_js}
      data-hide-modal={@main_content_inner_phx_remove_js}
      data-focus-first={@focus_first_js}
    >
      <div
        id={"#{@id}-overlay"}
        class="absolute inset-0 bg-black opacity-0"
        phx-click={@on_close}
      />

      <.focus_wrap
        id={"#{@id}-panel_content"}
        class="inline-grid z-[60] bg-white rounded-lg shadow-xl overflow-hidden max-w-lg w-full opacity-0"
        role="document"
        aria-hidden="true"
        data-is-modal="true"
        onclick="event.stopPropagation()"
      >
        <div
          id={"#{@id}-loading_content"}
          class="row-start-1 col-start-1 inset-0 z-[70] p-6 hidden"
          data-active-if-open={to_string(!@show_main_content?)}
          aria-live="polite"
          aria-label="Loading"
        >
          {render_slot(@loading, @on_close)}
        </div>

        <div
          id={"#{@id}-main_content"}
          class="row-start-1 col-start-1 inset-0 z-[80] p-6"
          data-active-if-open={to_string(@show_main_content?)}
        >
          <div
            :if={@show_main_content?}
            id={"#{@id}-main_content_inner"}
            class="block"
            data-ghost-duration="600"
            phx-remove={Phoenix.LiveView.JS.exec("data-hide-modal", to: "##{@id}")}
          >
            {render_slot(@main, @on_close)}
          </div>
        </div>
      </.focus_wrap>
    </div>
    """
  end
end
