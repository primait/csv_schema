defmodule R5_000.KS.U0.F4 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser

  schema "data/dataset_5_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name", filter_by: true
    field :email, "email"
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", filter_by: true
  end

  def description, do: ["5_000", true, 0, 4]
end
