defmodule Bro do
  @moduledoc """
  In Bro example i use csv's primary key
  """
  use Csv.Schema, separator: ?,

  import Csv.Schema.Parser

  schema path: "data/dataset_1_000.csv" do
    field :bro_id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true, filter_by: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", parser: &date!(&1, "{0M}/{0D}/{0YYYY}")
  end
end

# iex> Bro.filter_by_first_name("Ulick")
# [Bro.t()]

# iex> Bro.filter_by_gender("Male")
# [Bro.t()]

# iex> Bro.filter_by_gender("?")
# [] (empty)

# iex> Bro.by_email("fhardsonq@yahoo.co.jp")
# Bro.t()

# iex> Bro.by_email("simone.cottini@prima.it")
# nil

# iex> Bro.by_bro_id(1)
# Bro.t()

# iex> Bro.by_bro_id(0)
# nil
