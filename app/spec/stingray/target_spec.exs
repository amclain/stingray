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

  it "can list targets"

  it "can remove a target"
end
