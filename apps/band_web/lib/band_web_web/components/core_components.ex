defmodule BandWebWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.
  """
  use Phoenix.Component

  @doc """
  Renders flash notices.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <div :for={{kind, _} <- @flash} class="fixed top-2 right-2 max-w-sm">
      <div
        :if={msg = Phoenix.Flash.get(@flash, kind)}
        id={"flash-#{kind}"}
        role="alert"
        class={[
          "p-4 rounded-lg shadow-lg",
          kind == :info && "bg-blue-100 border border-blue-400 text-blue-700",
          kind == :error && "bg-red-100 border border-red-400 text-red-700"
        ]}
      >
        <p class="text-sm font-medium">
          <%= msg %>
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages to display"

  def flash(assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    """
  end
end