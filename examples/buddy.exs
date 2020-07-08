defmodule Buddy do
  @moduledoc """
  In Buddy example i use csv's primary key
  """
  use Csv.Schema, separator: ?,

  import Csv.Schema.Parser

  @content File.read!("data/dataset_1_000.csv")

  schema string: @content do
    field :buddy_id, ["first_name", "last_name"], key: true, join: " "
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", parser: &date!(&1, "{0M}/{0D}/{0YYYY}")
  end
end

# iex> Buddy.filter_by_first_name("Ulick")
# [Buddy.t()]

# iex> Buddy.filter_by_gender("Male")
# [Buddy.t()]

# iex> Buddy.filter_by_gender("?")
# [] (empty)

# iex> Buddy.by_email("fhardsonq@yahoo.co.jp")
# Buddy.t()

# iex> Buddy.by_email("simone.cottini@prima.it")
# nil

# iex> Buddy.by_buddy_id(1)
# Buddy.t()

# iex> Buddy.by_buddy_id(0)
# nil
