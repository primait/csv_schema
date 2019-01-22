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

  schema "path/to/person.csv" do
    field :id, "id", key: true
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", parser: &Parser.date!(&1, "{0M}/{0D}/{0YYYY}")
  end
end
```

Note that it's not a requirement to map all fields, but every field mapped must
have a column in csv file.
For example the following field configuration will result in a compilation error

```elixir
field :id, "non_existing_id", ....
```

Now Person module is a struct, defined like this:

```elixir
defmodule Person do
  defstruct id: nil,
            first_name: nil,
            last_name: nil,
            email: nil,
            gender: nil,
            ip_address: nil,
            date_of_birth: nil
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
- `:key`: boolean. At most one key could be set. If set to true creates the `by_{name}` function for you.
- `:unique`: boolean. If set to true creates the `by_{name}` function for you. All csv values must be unique or an exception is raised
- `:filter_by`: boolean. If set to true creates the `filter_by_{name}` function
- `:parser`: function. An arity 1 function used to map values from string to a custom type

Note that every configuration is optional

## Keep in mind

Compilation time increase in a linear manner if csv contains lots of lines and you
configure multiple fields candidate for method creation (flags `key`, `unique` and/or `filter_by` set to true)
Because "without data you're just another person with an opinion" here some data

csv rows | key | unique | filter_by | compile time ms
--------:|:---:|:------:|:---------:|----------------:
1_000    | no  | 0      | 0         | 22 ms
1_000    | yes | 1      | 1         | 19 ms
1_000    | yes | 2      | 2         | 21 ms
1_000    | yes | 2      | 4         | 29 ms
1_000    | yes | 2      | 0         | 15 ms
1_000    | yes | 0      | 4         | 26 ms
1_000    | no  | 2      | 0         | 12 ms
1_000    | no  | 0      | 4         | 22 ms
5_000    | no  | 0      | 0         | 555 ms
5_000    | yes | 1      | 1         | 1_695 ms
5_000    | yes | 2      | 2         | 2_341 ms
5_000    | yes | 2      | 4         | 3_273 ms
5_000    | yes | 2      | 0         | 1_976 ms
5_000    | yes | 0      | 4         | 2_698 ms
5_000    | no  | 2      | 0         | 1_559 ms
5_000    | no  | 0      | 4         | 2_146 ms
10_000   | no  | 0      | 0         | 1_701 ms
10_000   | yes | 1      | 1         | 3_624 ms
10_000   | yes | 2      | 2         | 5_169 ms
10_000   | yes | 2      | 4         | 6_988 ms
10_000   | yes | 2      | 0         | 4_279 ms
10_000   | yes | 0      | 4         | 5_638 ms
10_000   | no  | 2      | 0         | 3_278 ms
10_000   | no  | 0      | 4         | 4_846 ms

5 compilations average time.

Executed on my machine:

    Lenovo Thinkpad T480
    CPU: Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
    RAM: 32GB
