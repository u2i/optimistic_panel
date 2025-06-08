defmodule OptimisticPanel do
  @moduledoc """
  OptimisticPanel provides optimistic UI components for Phoenix LiveView applications.

  This library offers modal and slideover panel components that implement optimistic UI patterns,
  allowing for smooth user interactions with proper focus management and accessibility features.

  ## Features

  - **Optimistic UI**: Panels respond immediately to user actions while waiting for server confirmation
  - **Focus Management**: Built-in focus trapping using Phoenix LiveView's `focus_wrap` component
  - **Accessibility**: Full ARIA support and keyboard navigation
  - **Smooth Animations**: CSS transitions with configurable durations
  - **State Management**: Robust JavaScript state machine handling various interaction scenarios
  - **Ghost Animations**: Seamless transitions when content changes during panel lifecycle

  ## Components

  - `OptimisticPanel.OptimisticModalComponent` - Full-screen modal dialogs
  - `OptimisticPanel.OptimisticSlideoverComponent` - Side-sliding panels

  ## Quick Start

      # In your LiveView module
      import OptimisticPanel.OptimisticModalComponent

      # In your template
      <.optimistic_modal id="my-modal" if={@show_modal}>
        <:main :let={on_close}>
          <h2>Modal Content</h2>
          <button phx-click={on_close}>Close</button>
        </:main>
        <:loading>
          <p>Loading...</p>
        </:loading>
      </.optimistic_modal>

  ## JavaScript Hook

  The library includes a JavaScript hook (`OptimisticPanel`) that must be registered
  in your application. See the README for setup instructions.

  ## Dependencies

  - Phoenix LiveView 0.20.0+
  - Phoenix 1.7.0+
  - Phoenix HTML 4.0+
  """

  @doc """
  Returns the version of OptimisticPanel.
  
  ## Examples
  
      iex> OptimisticPanel.version()
      "0.1.0"
  """
  def version do
    Application.spec(:optimistic_panel, :vsn) |> to_string()
  end
end
