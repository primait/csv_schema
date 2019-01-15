defmodule Bro do
  @moduledoc """
    In Bro example i use csv's primary key
  """
  use Csv.Schema

  import Csv.Schema.Parser

  @auto_primary_key false
  schema "data/data.csv" do
    field :bro_id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", parser: &date!(&1, "{0M}/{0D}/{0YYYY}")
  end
end

# [Bro.t()]
# Bro.filter_by_first_name("Ulick")

# [Bro.t()]
# Bro.filter_by_gender("Male")

# [] (empty)
# Bro.filter_by_gender("?")

# Bro.t()
# Bro.by_email("fhardsonq@yahoo.co.jp")

# nil
# Bro.by_email("simone.cottini@prima.it")

# Bro.t()
# Bro.by_bro_id(1)

# nil
# Bro.by_bro_id(0)
