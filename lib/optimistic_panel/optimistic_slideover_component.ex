defmodule OptimisticPanel.OptimisticSlideoverComponent do
  @moduledoc """
  A sliding panel component that slides in from the edge of the screen.

  This component provides a panel that slides in from any edge of the screen (left, right, top, bottom)
  with optimistic UI behavior. It's ideal for navigation drawers, forms, settings panels, or any content
  that should appear alongside the main application without fully covering it.

  ## Features

  - **Optimistic UI**: Panel responds immediately to open/close actions
  - **Multi-directional**: Slides from left, right, top, or bottom
  - **Focus Management**: Automatic focus trapping using Phoenix LiveView's `focus_wrap`
  - **Loading States**: Separate loading and main content slots
  - **Ghost Animations**: Smooth transitions when content changes
  - **Accessibility**: Full ARIA support and keyboard navigation
  - **Customizable**: Configurable animations, overlay opacity, and behaviors

  ## Usage

      import OptimisticPanel.OptimisticSlideoverComponent

      <.optimistic_slideover
        id="nav-panel"
        if={@show_nav}
        slide_from="left"
        on_close={JS.push("close_nav")}
        overlay_opacity="30"
      >
        <:main :let={on_close}>
          <nav>
            <h2>Navigation</h2>
            <ul>
              <li><a href="/">Home</a></li>
              <li><a href="/about">About</a></li>
            </ul>
            <button phx-click={on_close}>Close</button>
          </nav>
        </:main>
        <:loading>
          <div class="p-4">Loading navigation...</div>
        </:loading>
      </.optimistic_slideover>

  ## Slide Directions

  The panel can slide from any edge:

  - `"left"` (default) - Slides in from the left edge
  - `"right"` - Slides in from the right edge  
  - `"top"` - Slides in from the top edge
  - `"bottom"` - Slides in from the bottom edge

  The panel automatically positions itself at the specified edge and applies
  the appropriate transform animations.

  ## Optimistic Behavior

  Like the modal component, the slideover supports both optimistic and non-optimistic modes:

  - **Optimistic**: Include `JS.dispatch("close-panel", to: "#panel-id")` in `on_close`
  - **Non-Optimistic**: Use only server calls like `JS.push("close")`

  ## Accessibility

  - Uses `role="dialog"` and `aria-modal="true"`
  - Automatic focus management with `focus_wrap`
  - Configurable ARIA labels and descriptions
  - Escape key and overlay click handling
  - Proper focus restoration when closed

  ## Configuration Options

  - `overlay_opacity` - Controls backdrop opacity (0-100)
  - `duration` - Animation duration in milliseconds
  - `close_on_escape` - Enable/disable escape key closing
  - `close_on_overlay_click` - Enable/disable click-outside-to-close
  - `lock_body_scroll` - Prevent body scrolling when open
  - `respect_reduced_motion` - Honor user's motion preferences
  """

  use Phoenix.Component
  import Phoenix.Component

  attr :id, :string, default: nil, doc: "Unique identifier for the slideover"
  attr :if, :any, default: false, doc: "Condition to show the slideover"
  attr :on_close, :any, default: nil, doc: "JavaScript command to execute when closing"
  attr :duration, :string, default: "300", doc: "Animation duration in milliseconds"
  attr :overlay_opacity, :string, default: "50", doc: "Overlay opacity percentage"
  attr :close_on_escape, :string, default: "true", doc: "Whether to close on escape key"
  attr :close_on_overlay_click, :string, default: "true", doc: "Whether to close on overlay click"
  attr :lock_body_scroll, :string, default: "true", doc: "Whether to lock body scroll"
  attr :respect_reduced_motion, :string, default: "true", doc: "Whether to respect reduced motion preference"
  attr :slide_from, :string, default: "left", doc: "Direction to slide from (left, right, top, bottom)"

  slot :main, required: true
  slot :loading, required: false

  def optimistic_slideover(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn ->
        "optimistic-slideover-#{System.unique_integer([:monotonic, :positive])}"
      end)
      |> assign_new(:if, fn -> false end)
      |> assign_new(:on_close, fn ->
        Phoenix.LiveView.JS.dispatch("close-panel", to: "##{assigns.id}")
      end)
      |> assign_new(:duration, fn -> "300" end)
      |> assign_new(:overlay_opacity, fn -> "50" end)
      |> assign_new(:close_on_escape, fn -> "true" end)
      |> assign_new(:close_on_overlay_click, fn -> "true" end)
      |> assign_new(:lock_body_scroll, fn -> "true" end)
      |> assign_new(:respect_reduced_motion, fn -> "true" end)
      |> assign_new(:slide_from, fn -> "left" end)

    assigns = assign(assigns, :show_main_content?, !!assigns.if)

    initial_transform_class =
      case assigns.slide_from do
        "right" -> "translate-x-full"
        "top" -> "-translate-y-full"
        "bottom" -> "translate-y-full"
        _ -> "-translate-x-full"
      end

    open_transform_class =
      case assigns.slide_from do
        "right" -> "translate-x-0"
        "top" -> "translate-y-0"
        "bottom" -> "translate-y-0"
        _ -> "translate-x-0"
      end

    panel_content_position_class =
      case assigns.slide_from do
        "right" -> "inset-y-0 right-0"
        "top" -> "inset-x-0 top-0 h-auto"
        "bottom" -> "inset-x-0 bottom-0 h-auto"
        _ -> "inset-y-0 left-0"
      end

    panel_content_base_classes =
      "fixed z-[60] bg-base-200 text-base-content transition-all ease-in-out min-w-40 w-fit max-w-md"

    content_base_classes = "p-4 transition-opacity duration-200"

    main_slot_transition_classes = "transition-opacity duration-200 ease-out"
    main_slot_start_classes = "opacity-100"
    main_slot_end_classes = "opacity-0"
    main_slot_duration_ms = 200

    main_slot_phx_remove_js =
      Phoenix.LiveView.JS.hide(
        transition:
          {main_slot_transition_classes, main_slot_start_classes, main_slot_end_classes},
        time: main_slot_duration_ms
      )

    assigns =
      assigns
      |> assign(
        :panel_content_classes,
        "#{panel_content_base_classes} #{panel_content_position_class} #{initial_transform_class}"
      )
      |> assign(:data_open_classes, "opacity-100 #{open_transform_class}")
      |> assign(:data_closed_classes, "opacity-0 #{initial_transform_class}")
      |> assign(
        :focus_first_js,
        Phoenix.LiveView.JS.focus_first(to: "##{assigns.id}-panel_content")
      )

    ~H"""
    <div
      id={@id}
      class="fixed inset-0 z-50 opacity-0 pointer-events-none"
      phx-hook="OptimisticPanel"
      phx-remove={
        Phoenix.LiveView.JS.hide(
          transition: {"transition-opacity ease-in-out", "opacity-100", "opacity-0"},
          time: String.to_integer(@duration)
        )
      }
      data-duration={@duration}
      data-overlay-opacity={@overlay_opacity}
      data-close-on-escape={@close_on_escape}
      data-close-on-overlay-click={@close_on_overlay_click}
      data-lock-body-scroll={@lock_body_scroll}
      data-respect-reduced-motion={@respect_reduced_motion}
      data-slide-from={@slide_from}
      data-focus-first={@focus_first_js}
    >
      <div
        id={"#{@id}-overlay"}
        class="absolute inset-0 bg-black transition-opacity"
        phx-click={@on_close}
        aria-hidden="true"
      />
      <.focus_wrap
        id={"#{@id}-panel_content"}
        class={@panel_content_classes}
        role="dialog"
        aria-modal="true"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        aria-hidden="true"
        tabindex="-1"
        data-open-classes={@data_open_classes}
        data-closed-classes={@data_closed_classes}
        data-is-modal="false"
      >
        <div class="overflow-auto p-4" role="document">
          <div
            id={"#{@id}-loading_content"}
            class={content_base_classes}
            data-active-if-open={to_string(!@show_main_content?)}
            aria-live="polite"
          >
            {render_slot(@loading, @on_close)}
          </div>
          <div
            id={"#{@id}-main_content"}
            class={content_base_classes}
            data-active-if-open={to_string(@show_main_content?)}
            aria-live="polite"
          >
            <div
              :if={@show_main_content?}
              id={"#{@id}-main_content_inner"}
              class="contents"
              data-ghost-duration={to_string(main_slot_duration_ms)}
              phx-remove={main_slot_phx_remove_js}
            >
              {render_slot(@main, @on_close)}
            </div>
          </div>
        </div>
      </.focus_wrap>
    </div>
    """
  end
end
