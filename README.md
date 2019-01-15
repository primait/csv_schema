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

  @auto_primary_key false
  schema "path/to/person.csv" do
    field :id, "ID", key: true, parser: &Parser.integer!/1
    field :name, "Name", filter_by: true
    field :fiscal_code, "Fiscal Code", unique: true
    field :birth, "Date of birth", parser: &Parser.date!(&1, "{0D}/{0M}/{0YYYY}")
  end
end
```

Now Person module is a struct, defined like this:
```elixir
defmodule Person do
  defstruct id: nil, name: nil, fiscal_code: nil, birth: nil
end
```

This macro creates for you inside Person module those functions:

```elixir
def by_id(integer_key), do: ...

def filter_by_name(string_value), do: ...

def by_fiscal_code(string_value), do: ...

def get_all, do: ...
```

Where:
- `by_id` returns a `%Person{}` or `nil` if key is not mapped in csv
- `filter_by_name` returns a `[%Person{}, %Person{}, ...]` or `[]` if input predicate does not match any person
- `by_fiscal_code` returns a `%Person{}` or `nil` if no person have that fiscal code in csv

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
- `key`: boolean. Only one key could be (and must be) set. If set to true creates the `by_{name}` function for you.
- `unique`: boolean. If set to true creates the `by_{name}` function for you. All csv values must be unique or an exception is raised
- `filter_by`: boolean. If set to true creates the `filter_by_{name}` function
- `parser`: function. An arity 1 function used to map values from string to a custom type
