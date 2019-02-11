defmodule R5_000.KS.U1.F1 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser

  schema "data/dataset_5_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth"
  end
end
