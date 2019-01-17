defmodule PersonInCrowd do
  @moduledoc """
    In PersonInCrowd example i use larger csv's primary key
  """
  use Csv.Schema

  import Csv.Schema.Parser

  @start_time :os.system_time(:millisecond)

  schema "data/longer_data.csv" do
    field :person_id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", parser: &date!(&1, "{0M}/{0D}/{0YYYY}")
  end

  IO.puts("#{__MODULE__} compilation tooks: #{:os.system_time(:millisecond) - @start_time} milliseconds")
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
