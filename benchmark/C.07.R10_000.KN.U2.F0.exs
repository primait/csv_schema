defmodule R10_000.KN.U2.F0 do
  @moduledoc false
  use Csv.Schema

  schema "data/dataset_10_000.csv" do
    field :id, "id"
    field :first_name, "first_name"
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender"
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth"
  end
end
