defmodule R1_000.KN.U0.F0 do
  @moduledoc false
  use Csv.Schema

  schema path: "data/dataset_1_000.csv" do
    field :first_name, "first_name"
    field :last_name, "last_name"
    field :email, "email"
    field :gender, "gender"
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth"
  end

  def description, do: ["1_000", false, 0, 0]
end
