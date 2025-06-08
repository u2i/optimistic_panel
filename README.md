# OptimisticPanel

OptimisticPanel provides optimistic UI components for Phoenix LiveView applications, featuring modal dialogs and sliding panels with smooth animations, focus management, and accessibility support.

## Features

- 🚀 **Optimistic UI**: Instant responsiveness while waiting for server confirmation
- 🎯 **Focus Management**: Built-in focus trapping using Phoenix LiveView's `focus_wrap`
- ♿ **Accessibility**: Full ARIA support, keyboard navigation, and screen reader compatibility
- 🎨 **Smooth Animations**: CSS transitions with configurable durations and ghost animations
- 🏗️ **State Management**: Robust JavaScript state machine handling complex interaction scenarios
- 📱 **Responsive**: Works seamlessly across different screen sizes and devices

## Installation

Add `optimistic_panel` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:optimistic_panel, "~> 0.1.0"}
  ]
end
```

## Setup

### 1. Install the JavaScript Hook

Add the OptimisticPanel hook to your Phoenix LiveView application:

```javascript
// assets/js/app.js
import OptimisticPanel from "optimistic_panel/assets/js/hooks/optimistic_panel.js"

let Hooks = {
  OptimisticPanel: OptimisticPanel,
  // ... your other hooks
}

let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})
```

### 2. Import Components

In your LiveView modules, import the components you need:

```elixir
defmodule MyAppWeb.SomePageLive do
  use MyAppWeb, :live_view
  
  # Import the components
  import OptimisticPanel.OptimisticModalComponent
  import OptimisticPanel.OptimisticSlideoverComponent
  
  # ... rest of your LiveView
end
```

## Usage

### Modal Component

```elixir
<.optimistic_modal
  id="user-modal"
  if={@user_form}
  on_close={JS.dispatch("close-panel", to: "#user-modal") |> JS.push("close_user_form")}
  duration="300"
  close_on_escape="true"
>
  <:main :let={on_close}>
    <div class="bg-white p-6 rounded-lg">
      <h2 class="text-xl font-bold mb-4">Edit User</h2>
      <.form for={@user_form} phx-submit="save_user">
        <input type="text" name="name" placeholder="Name" class="w-full p-2 border rounded mb-4" />
        <div class="flex gap-2">
          <button type="button" phx-click={on_close} class="px-4 py-2 bg-gray-200 rounded">
            Cancel
          </button>
          <button type="submit" class="px-4 py-2 bg-blue-500 text-white rounded">
            Save
          </button>
        </div>
      </.form>
    </div>
  </:main>
  <:loading>
    <div class="bg-white p-6 rounded-lg">
      <div class="animate-spin h-8 w-8 border-4 border-blue-500 border-t-transparent rounded-full mx-auto"></div>
      <p class="text-center mt-2">Loading...</p>
    </div>
  </:loading>
</.optimistic_modal>
```

### Slideover Component

```elixir
<.optimistic_slideover
  id="nav-panel"
  if={@show_navigation}
  slide_from="left"
  on_close={JS.dispatch("close-panel", to: "#nav-panel") |> JS.push("close_nav")}
  overlay_opacity="40"
  duration="250"
>
  <:main :let={on_close}>
    <div class="h-full bg-white shadow-xl">
      <div class="p-4 border-b">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-semibold">Navigation</h2>
          <button phx-click={on_close} class="p-2 hover:bg-gray-100 rounded">×</button>
        </div>
      </div>
      <nav class="p-4">
        <ul class="space-y-2">
          <li><a href="/" class="block p-2 hover:bg-gray-100 rounded">Home</a></li>
          <li><a href="/about" class="block p-2 hover:bg-gray-100 rounded">About</a></li>
          <li><a href="/contact" class="block p-2 hover:bg-gray-100 rounded">Contact</a></li>
        </ul>
      </nav>
    </div>
  </:main>
  <:loading>
    <div class="h-full bg-white shadow-xl p-4">
      <div class="animate-pulse">Loading navigation...</div>
    </div>
  </:loading>
</.optimistic_slideover>
```

## Component Attributes

### Shared Attributes

Both components support these common attributes:

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | `string` | auto-generated | Unique identifier for the panel |
| `if` | `any` | `false` | Condition to show the panel |
| `on_close` | `JS` | auto-generated | JavaScript command to execute when closing |
| `duration` | `string` | `"300"` | Animation duration in milliseconds |
| `close_on_escape` | `string` | `"true"` | Whether to close on escape key press |
| `close_on_overlay_click` | `string` | `"true"` | Whether to close when clicking the overlay |

### Slideover-Specific Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `slide_from` | `string` | `"left"` | Direction to slide from: `"left"`, `"right"`, `"top"`, `"bottom"` |
| `overlay_opacity` | `string` | `"50"` | Overlay opacity percentage (0-100) |
| `lock_body_scroll` | `string` | `"true"` | Whether to prevent body scrolling when open |
| `respect_reduced_motion` | `string` | `"true"` | Whether to respect user's reduced motion preferences |

## Optimistic vs Non-Optimistic Behavior

The behavior of the panels depends on how you configure the `on_close` attribute:

### Optimistic Mode (Recommended)

Include `JS.dispatch("close-panel", to: "#panel-id")` in your `on_close` command:

```elixir
on_close={
  JS.dispatch("close-panel", to: "#my-modal") 
  |> JS.push("handle_close")
}
```

**Benefits:**
- Panel closes immediately for responsive feel
- Server processes the close action afterward
- Smooth, app-like user experience

### Non-Optimistic Mode

Use only server calls without the dispatch:

```elixir
on_close={JS.push("handle_close")}
```

**Characteristics:**
- Panel waits for server response before closing
- More predictable but less responsive
- Useful when server validation is critical

## State Management

The components use a sophisticated JavaScript state machine with these states:

- **`closed`** - Panel is hidden
- **`opening`** - Panel is animating in, waiting for server
- **`openingServerArrived`** - Server confirmed while opening  
- **`open`** - Panel is fully open and interactive
- **`closing`** - Panel is closing optimistically
- **`closingWaitingForServer`** - Waiting for server close confirmation
- **`closingWaitingForServerStateToOpen`** - Server confirmed close, but new open requested

This state machine handles complex scenarios like:
- User closes panel before server responds to open
- User opens panel again while close is pending
- Network delays and race conditions
- Seamless transitions between states

## Accessibility Features

OptimisticPanel components are built with accessibility in mind:

### Focus Management
- Automatic focus trapping using Phoenix LiveView's `focus_wrap`
- Focus moves to first interactive element when opened
- Focus returns to trigger element when closed
- Tab navigation stays within the panel

### ARIA Support
- `role="dialog"` and `aria-modal="true"`
- `aria-labelledby` and `aria-describedby` support
- `aria-hidden` management during animations
- `aria-live` regions for loading states

### Keyboard Navigation
- Escape key closes the panel (configurable)
- Tab and Shift+Tab cycle through interactive elements
- Enter and Space activate buttons and links

### Screen Reader Compatibility
- Semantic HTML structure
- Descriptive labels and roles
- Status announcements for state changes

## Advanced Usage

### Custom Animations

You can customize the animation duration and timing:

```elixir
<.optimistic_modal
  id="slow-modal"
  if={@show_modal}
  duration="600"  # Slower animation
>
  <!-- content -->
</.optimistic_modal>
```

### Multiple Panels

You can have multiple panels open simultaneously:

```elixir
<.optimistic_modal id="modal-1" if={@modal_1}>
  <!-- modal content -->
</.optimistic_modal>

<.optimistic_slideover id="panel-1" if={@panel_1} slide_from="left">
  <!-- slideover content -->
</.optimistic_slideover>

<.optimistic_slideover id="panel-2" if={@panel_2} slide_from="right">
  <!-- another slideover -->
</.optimistic_slideover>
```

### Conditional Behavior

Disable certain behaviors based on conditions:

```elixir
<.optimistic_modal
  id="important-modal"
  if={@critical_action}
  close_on_escape="false"     # Prevent accidental closure
  close_on_overlay_click="false"
>
  <!-- critical content that shouldn't be accidentally closed -->
</.optimistic_modal>
```

## LiveView Integration

### Basic Event Handling

In your LiveView module:

```elixir
defmodule MyAppWeb.PageLive do
  use MyAppWeb, :live_view
  import OptimisticPanel.OptimisticModalComponent

  def mount(_params, _session, socket) do
    {:ok, assign(socket, user_form: nil)}
  end

  def handle_event("open_user_form", %{"user_id" => user_id}, socket) do
    user = Users.get_user!(user_id)
    form = to_form(Users.change_user(user))
    {:noreply, assign(socket, user_form: form)}
  end

  def handle_event("close_user_form", _params, socket) do
    {:noreply, assign(socket, user_form: nil)}
  end

  def handle_event("save_user", %{"user" => user_params}, socket) do
    case Users.update_user(socket.assigns.user_form.data, user_params) do
      {:ok, _user} ->
        {:noreply, assign(socket, user_form: nil)}
      {:error, changeset} ->
        {:noreply, assign(socket, user_form: to_form(changeset))}
    end
  end
end
```

### Using with Nested LiveComponents

A common pattern is to use OptimisticPanel with nested LiveComponents. The key is passing the `on_close` callback:

```elixir
<.optimistic_modal
  id="user-modal"
  if={@user_form}
  on_close={JS.dispatch("close-panel", to: "#user-modal") |> JS.push("close_form")}
>
  <:main :let={on_close}>
    <.live_component
      module={MyAppWeb.UserFormComponent}
      id="user-form"
      on_close={on_close}
      user={@user}
    />
  </:main>
</.optimistic_modal>
```

In your LiveComponent, use the `on_close` callback:

```elixir
def render(assigns) do
  ~H"""
  <div class="bg-white p-6 rounded-lg">
    <h2>Edit User</h2>
    <.form phx-target={@myself} phx-submit="save">
      <!-- form fields -->
      <button type="button" phx-click={@on_close}>Cancel</button>
      <button type="submit">Save</button>
    </.form>
  </div>
  """
end
```


### Loading States

The `:loading` slot is displayed when `if` is truthy but `:main` content is not yet ready:

```elixir
def handle_event("open_user_form", %{"user_id" => user_id}, socket) do
  # Show loading immediately
  socket = assign(socket, user_form: :loading)
  
  # Fetch data asynchronously
  send(self(), {:load_user, user_id})
  
  {:noreply, socket}
end

def handle_info({:load_user, user_id}, socket) do
  user = Users.get_user!(user_id)
  form = to_form(Users.change_user(user))
  {:noreply, assign(socket, user_form: form)}
end
```

## Troubleshooting

### Panel Not Appearing

1. **Check the `if` condition**: Ensure the condition evaluates to a truthy value
2. **Verify JavaScript hook**: Make sure OptimisticPanel hook is registered
3. **Check for CSS conflicts**: Ensure no CSS is hiding the panel
4. **Inspect element**: Use browser dev tools to see if the panel exists in DOM

### Focus Issues

1. **No focusable elements**: Ensure your panel content has interactive elements
2. **CSS interference**: Check that focusable elements aren't hidden or disabled
3. **Tab order**: Verify tabindex values don't interfere with natural tab flow

### Animation Problems

1. **Check duration format**: Use string values like `"300"`, not integers
2. **CSS transitions**: Ensure your CSS doesn't override the component's transitions
3. **Reduced motion**: Component respects `prefers-reduced-motion` settings

### State Machine Issues

1. **Network delays**: Long server responses can cause state conflicts
2. **Rapid interactions**: Very fast user interactions might cause race conditions
3. **Check browser console**: The hook logs state transitions for debugging

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

