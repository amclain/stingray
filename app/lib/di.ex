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
    ensure_ets_is_running()

    case :ets.lookup(:di, module) do
      []                     -> module
      [{_, injected_module}] -> injected_module
    end
  end

  @doc """
  Inject a module in place of another one.
  """
  @spec inject(target_module :: module, injected_module :: module) :: any
  def inject(target_module, injected_module) when is_atom(injected_module) do
    ensure_ets_is_running()

    :ets.insert(:di, {target_module, injected_module})

    :ok
  end

  def inject(target_module, module_body) do
    unique_number = System.unique_integer([:positive])

    {:module, injected_module, _, _} =
      Module.create(:"Mock#{unique_number}", module_body, Macro.Env.location(__ENV__))

    inject(target_module, injected_module)
  end

  defp ensure_ets_is_running do
    case :ets.whereis(:di) do
      :undefined -> :ets.new(:di, [:public, :named_table, read_concurrency: true])
      table_id   -> table_id
    end
  end
end
