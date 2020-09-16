defmodule R1_000.KN.U0.F4 do
  @moduledoc false
  use Csv.Schema

  schema path: "data/dataset_1_000.csv" do
    field :id, "id"
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name", filter_by: true
    field :email, "email"
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", filter_by: true
  end

  def description, do: ["1_000", false, 0, 4]
end
