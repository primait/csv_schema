defmodule Fellow do
  @moduledoc """
  In Fellow example i use auto primary key, ignoring id column in csv
  """
  use Csv.Schema

  import Csv.Schema.Parser

  schema "data/data.csv" do
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", parser: &date!(&1, "{0M}/{0D}/{0YYYY}")
  end
end

# iex> Fellow.filter_by_first_name("Ulick")
# [Fellow.t()]

# iex> Fellow.filter_by_gender("Male")
# [Fellow.t()]

# iex> Fellow.filter_by_gender("?")
# [] (empty)

# iex> Fellow.by_email("fhardsonq@yahoo.co.jp")
# Fellow.t()

# iex> Fellow.by_email("simone.cottini@prima.it")
# nil
