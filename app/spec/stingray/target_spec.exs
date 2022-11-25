defmodule Stringray.Target.Test do
  use ESpec

  alias Stingray.Target

  let :target_number,      do: 1
  let :target_id,          do: :my_target
  let :target_name,        do: "My Target"
  let :target_serial_port, do: "ttyUSB0"
  let :target_baud,        do: 115200

  before do
    {:ok, target} = Target.add(
      target_number(),
      target_id(),
      target_name(),
      target_serial_port(),
      target_baud()
    )

    {:shared, target: target}
  end

  describe "add a target" do
    specify do
      expect Target.add(2, :my_new_target, "My New Target", "ttyUSB0", 115200)|> to(eq \
        {:ok, %Target{
          number:      2,
          id:          :my_new_target,
          name:        "My New Target",
          serial_port: "ttyUSB0",
          baud:        115200,
        }
      })
    end

    it "returns an error if the target exists" do
      expect Target.add(target_number(), :my_new_target, target_name(), target_serial_port(), target_baud())
      |> to(eq {:error, :target_exists})

      expect Target.add(1000, target_id(), target_name(), target_serial_port(), target_baud())
      |> to(eq {:error, :target_exists})
    end

    it "returns an error when adding a target with invalid params" do
      expect Target.add(-1, :my_new_target, "My Target", "ttyUSB0", 115200)
      |> should(eq {:error, :number_not_positive})

      expect Target.add(1000, "invalid id", "My Target", "ttyUSB0", 115200)
      |> should(eq {:error, :id_not_atom})

      expect Target.add(1000, :my_new_target, nil, "ttyUSB0", 115200)
      |> should(eq {:error, :name_not_string})

      expect Target.add(1000, :my_new_target, "My Target", nil, 115200)
      |> should(eq {:error, :serial_port_not_string})

      expect Target.add(1000, :my_new_target, "My Target", "ttyUSB0", nil)
      |> should(eq {:error, :invalid_baud})
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
    Target.add(5, :target_5, "Target 5", "ttyUSB5", 9600)
    Target.add(3, :target_3, "Target 3", "ttyUSB3", 115200)

    expect Target.list |> to(eq [
      %Target{
        number:      target_number(),
        id:          target_id(),
        name:        target_name(),
        serial_port: target_serial_port(),
        baud:        target_baud(),
      },
      %Target{
        number:      3,
        id:          :target_3,
        name:        "Target 3",
        serial_port: "ttyUSB3",
        baud:        115200,
      },
      %Target{
        number:      5,
        id:          :target_5,
        name:        "Target 5",
        serial_port: "ttyUSB5",
        baud:        9600,
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

  describe "set properties of a target" do
    specify "by target id" do
      changed_target = %Target{
        number:      1,
        id:          :changed_target,
        name:        "New name",
        serial_port: "ttyNew0",
        baud:        115200,
      }

      expect Target.set(
        target_id(),
        id:          :changed_target,
        name:        "New name",
        serial_port: "ttyNew0",
        baud:        115200
      )
      |> to(eq {:ok, changed_target})

      expect Target.list() |> to(eq [changed_target])
    end

    specify "by target handle" do
      changed_target = %Target{
        number:      1,
        id:          :changed_target,
        name:        "New name",
        serial_port: "ttyNew0",
        baud:        115200,
      }

      expect Target.set(
        target_id(),
        id:          :changed_target,
        name:        "New name",
        serial_port: "ttyNew0",
        baud:        115200
      )
      |> to(eq {:ok, changed_target})

      expect Target.list() |> to(eq [changed_target])
    end

    it "returns an error if the target ID doesn't exist" do
      expect Target.set(:invalid_target, name: "New name")
      |> to(eq {:error, :target_not_found})
    end

    it "returns an error if the target handle doesn't exist" do
      expect Target.set(%Target{}, name: "New name")
      |> to(eq {:error, :target_not_found})
    end

    it "ignores target properties that don't exist" do
      expect Target.set(shared.target, invalid: "Can't set this")
      |> to(eq {:ok, shared.target})
    end
  end
end
