defmodule DI do
  @moduledoc """
  Dependency injection
  """

  defmacro __using__(_) do
    quote do
      @doc false
      defdelegate di(module), to: DI
    end
  end

  @doc """
  Flag a module as eligible for dependency injection.

  Defaults to `module` unless a new dependency is injected in its place.
  """
  @spec di(module :: module) :: module
  def di(module) do
    ensure_agent_is_running()

    Agent.get(__MODULE__, & &1)
    |> Map.get(module, module)
  end

  @doc """
  Inject a module in place of another one.
  """
  @spec inject(target_module :: module, injected_module :: module) :: any
  def inject(target_module, injected_module) when is_atom(injected_module) do
    ensure_agent_is_running()

    Agent.get_and_update(__MODULE__, fn mappings ->
      new_mappings = Map.put(mappings, target_module, injected_module)
      {new_mappings, new_mappings}
    end)

    :ok
  end

  def inject(target_module, module_body) do
    unique_number = System.unique_integer([:positive])

    {:module, injected_module, _, _} =
      Module.create(:"Mock#{unique_number}", module_body, Macro.Env.location(__ENV__))

    inject(target_module, injected_module)
  end

  defp ensure_agent_is_running do
    case Process.whereis(__MODULE__) do
      nil ->
        start_agent()

      pid ->
        case Process.alive?(pid) do
          false -> start_agent()
          _     -> :noop
        end
    end
  end

  defp start_agent do
    {:ok, _pid} = Agent.start_link(fn -> %{} end, name: __MODULE__)
  end
end
