defmodule Stingray.Target do
  @moduledoc """
  A hardware target connected to the Stingray controller.
  """

  @type t :: %__MODULE__{}
  
  defstruct [
    :id,
    :name,
    :number,
    :serial_port,
  ]

  @doc """
  Add a target to be managed by Stingray.

  ## Args
  - `number`      - The numerical identifier of the set of physical connections \
                    on the Stingray device that the target is connected to.
  - `id`          - A short identifier that is easy to use as a reference.
  - `name`        - A human-readable name.
  - `serial_port` - File name of the serial port the target is connected to \
                    (`ttyUSB0`).
  """
  @spec add(
    number :: pos_integer,
    id :: atom,
    name :: String.t,
    serial_port :: String.t
  ) ::
      {:ok, t}
    | {:error, :id_not_atom}
    | {:error, :name_not_string}
    | {:error, :number_not_positive}
    | {:error, :serial_port_not_string}
    | {:error, :target_exists}
  def add(number, id, name, serial_port) do
    cond do
      !is_integer(number) || number < 1 ->
        {:error, :number_not_positive}

      !is_atom(id) ->
        {:error, :id_not_atom}

      !is_binary(name) ->
        {:error, :name_not_string}

      !is_binary(serial_port) ->
        {:error, :serial_port_not_string}

      true ->
        target = %__MODULE__{
          id: id,
          name: name,
          number: number,
          serial_port: serial_port,
        }

        targets = CubDB.get(:settings, :targets, [])

        target_exists? =
          !!Enum.find(targets, fn t ->
            t.id == target.id ||
            t.number == target.number
          end)

        case target_exists? do
          true ->
            {:error, :target_exists}

          _ ->
            targets = [target | targets] |> Enum.sort(& &1.number < &2.number)
            CubDB.put(:settings, :targets, targets)

            {:ok, target}
        end
    end
  end

  @doc """
  Get a target by id.
  """
  @spec get(id :: atom) :: t | nil
  def get(id) do
    CubDB.get(:settings, :targets, [])
    |> Enum.find(& id == &1.id)
  end

  @doc """
  List targets managed by Stingray.

  This list is ordered by ascending target number.
  """
  @spec list() :: [t]
  def list do
    CubDB.get(:settings, :targets, [])
  end

  @doc """
  Remove a target from being managed by Stingray.

  This target's configuration and data will be lost.
  """
  @spec remove(id :: atom) :: {:ok, t} | {:error, :not_found}
  def remove(id) do
    CubDB.get_and_update(:settings, :targets, fn targets ->
      targets = targets || []

      case Enum.find(targets, & id == &1.id) do
        nil ->
          {{:error, :not_found}, targets}

        target ->
          new_targets = List.delete(targets, target)
          {{:ok, target}, new_targets}
      end        
    end)
  end
end
