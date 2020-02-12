defmodule R1_000.KS.U0.F0 do
  @moduledoc false
  use Csv.Schema

  schema "data/dataset_1_000.csv" do
    field :id, "id", key: true
    field :first_name, "first_name"
    field :last_name, "last_name"
    field :email, "email"
    field :gender, "gender"
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth"
  end

  def description, do: ["1_000", true, 0, 0]
end
