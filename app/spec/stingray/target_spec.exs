defmodule Stringray.Target.Test do
  use ESpec

  alias Stingray.Target

  let :target_number,      do: 1
  let :target_id,          do: :my_target
  let :target_name,        do: "My Target"
  let :target_serial_port, do: "ttyUSB0"

  before do
    {:ok, target} = Target.add(target_number(), target_id(), target_name(), target_serial_port())

    {:shared, target: target}
  end

  describe "add a target" do
    specify do
      expect Target.add(2, :my_new_target, "My New Target", "ttyUSB0") |> to(eq \
        {:ok, %Target{
          number:      2,
          id:          :my_new_target,
          name:        "My New Target",
          serial_port: "ttyUSB0",
        }
      })
    end

    it "returns an error if the target exists" do
      expect Target.add(target_number(), :my_new_target, target_name(), target_serial_port())
      |> to(eq {:error, :target_exists})

      expect Target.add(1000, target_id(), target_name(), target_serial_port())
      |> to(eq {:error, :target_exists})
    end

    it "returns an error when adding a target with invalid params" do
      expect Target.add(-1, :my_new_target, "My Target", "ttyUSB0")
      |> should(eq {:error, :number_not_positive})

      expect Target.add(1000, "invalid id", "My Target", "ttyUSB0")
      |> should(eq {:error, :id_not_atom})

      expect Target.add(1000, :my_new_target, nil, "ttyUSB0")
      |> should(eq {:error, :name_not_string})

      expect Target.add(1000, :my_new_target, "My Target", nil)
      |> should(eq {:error, :serial_port_not_string})
    end
  end

  describe "get a target" do
    specify do
      expect Target.get(target_id()) |> should(eq shared.target)
    end

    it "returns nil if the target isn't found" do
      expect Target.get(:invalid_target) |> should(eq nil)
    end
  end

  it "lists targets in numerical order" do
    Target.add(5, :target_5, "Target 5", "ttyUSB5")
    Target.add(3, :target_3, "Target 3", "ttyUSB3")

    expect Target.list |> to(eq [
      %Target{
        number:      target_number(),
        id:          target_id(),
        name:        target_name(),
        serial_port: target_serial_port(),
      },
      %Target{
        number:      3,
        id:          :target_3,
        name:        "Target 3",
        serial_port: "ttyUSB3",
      },
      %Target{
        number:      5,
        id:          :target_5,
        name:        "Target 5",
        serial_port: "ttyUSB5",
      },
    ])
  end

  describe "remove a target" do
    specify do
      expect Target.remove(target_id()) |> should(eq {:ok, shared.target})
      expect Target.list |> should(eq [])
    end

    it "returns an error if the target doesn't exist" do
      expect Target.remove(:invalid_target) |> should(eq {:error, :not_found})
      expect Target.list |> should(eq [shared.target])
    end
  end
end
