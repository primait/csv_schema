[![Build Status](https://travis-ci.org/primait/csv_schema.svg?branch=master)](https://travis-ci.org/primait/csv_schema)

# Csv Schema

Csv schema is a library helping you to build Ecto.Schema-like modules having a csv file as source.

The idea behind this library is give the possibility to create, at compile-time, a self-contained module exposing functions to retrieve data starting from a CSV.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `csv_schema` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:csv_schema, "~> 0.1.0"}
  ]
end
```

## Usage

Supposing you have a CSV file looking like this:

id  | first_name | last_name  | email                         | gender | ip_address      | date_of_birth
:--:|:----------:|:----------:|:-----------------------------:|:------:|:---------------:|:------------:
1   | Ivory      | Overstreet | ioverstreet0@businessweek.com | Female | 30.138.91.62    | 10/22/2018
2   | Ulick      | Vasnev     | uvasnev1@vkontakte.ru         | Male   | 35.15.164.70    | 01/19/2018
3   | Chloe      | Freemantle | cfreemantle2@parallels.com    | Female | 133.133.113.255 | 08/13/2018
... | ...        | ...        | ...                           | ...    | ...             | ...

Is possible to create an Ecto.Schema-like repository using `Csv.Schema` macro

```elixir
defmodule Person do
  use Csv.Schema
  alias Csv.Schema.Parser

  @auto_primary_key true
  schema "path/to/person.csv" do
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", parser: &date!(&1, "{0M}/{0D}/{0YYYY}")
  end
end
```

Now Person module is a struct, defined like this:
```elixir
defmodule Person do
  defstruct id: nil, first_name: nil, last_name: nil, email: nil, gender: nil, ip_address: nil, date_of_birth: nil
end
```

This macro creates for you inside Person module those functions:

```elixir
def by_id(integer_key), do: ...

def filter_by_first_name(string_value), do: ...

def by_email(string_value), do: ...

def filter_by_gender(string_value), do: ...

def get_all, do: ...
```

Where:
- `by_id` returns a `%Person{}` or `nil` if key is not mapped in csv
- `filter_by_first_name` returns a `[%Person{}, %Person{}, ...]` or `[]` if input predicate does not match any person
- `by_email` returns a `%Person{}` or `nil` if no person have provided email in csv
- `filter_by_gender` returns a `[%Person{}, %Person{}, ...]` or `[]` if input predicate does not match any person gender
- `get_all` return all csv rows

Note: if @auto_primary_key is set to `true` this macro creates automatically a new column called `id`
(and new `by_id` method). Its value is a progressive integer; otherwise you have to set a key opt
to the field that should be key

## Field configuration

Every field should be formed like this:

```
field {struct_field}, {csv_header}, {opts}
```

where:
- `{struct_field}` will be the struct field name. Could be configured as `string` or as `atom`
- `{csv_header}` is the csv column name from where get values. Must be configured using string only
- `{opts}` is a keyword list containing special configurations

opts:
- `:key`: boolean. Only one key could be (and must be) set. If set to true creates the `by_{name}` function for you.
- `:unique`: boolean. If set to true creates the `by_{name}` function for you. All csv values must be unique or an exception is raised
- `:filter_by`: boolean. If set to true creates the `filter_by_{name}` function
- `:parser`: function. An arity 1 function used to map values from string to a custom type
