defmodule R10_000.KS.U2.F2 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser

  schema path: "data/dataset_10_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth"
  end

  def description, do: ["10_000", true, 2, 2]
end
