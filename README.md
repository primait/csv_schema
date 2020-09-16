# Csv Schema

[![Hex pm](https://img.shields.io/hexpm/v/csv_schema.svg?style=flat)](https://hex.pm/packages/csv_schema)
[![Build Status](https://travis-ci.org/primait/csv_schema.svg?branch=master)](https://travis-ci.org/primait/csv_schema)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Csv schema is a library helping you to build Ecto.Schema-like modules having a csv file as source.

The idea behind this library is give the possibility to create, at compile-time, a self-contained module exposing functions to retrieve data starting from a CSV.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `csv_schema` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:csv_schema, "~> 0.2.0"}
  ]
end
```

## Usage

Supposing you have a CSV file looking like this:

  id | first_name | last_name  | email                         | gender | ip_address      | date_of_birth |
:----|:-----------|:-----------|:------------------------------|:-------|:----------------|:--------------|
1    | Ivory      | Overstreet | ioverstreet0@businessweek.com | Female | 30.138.91.62    | 10/22/2018    |
2    | Ulick      | Vasnev     | uvasnev1@vkontakte.ru         | Male   | 35.15.164.70    | 01/19/2018    |
3    | Chloe      | Freemantle | cfreemantle2@parallels.com    | Female | 133.133.113.255 | 08/13/2018    |
...  | ...        | ...        | ...                           | ...    | ...             | ...           |


It is possible to create an Ecto.Schema-like repository using `Csv.Schema` macro:

```elixir
defmodule Person do
  use Csv.Schema
  alias Csv.Schema.Parser

  schema path: "path/to/person.csv" do
    field :id, "id"
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name", sort: :asc
    field :identifier, ["first_name", "last_name"], key: true, join: " "
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true, sort: :desc
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", parser: &Parser.date!(&1, "{0M}/{0D}/{0YYYY}")
  end
end
```

It is possible to define the schema with `string: ` param in order to directly use a string to generate content
```elixir
@data """
id,first_name,last_name,email,gender,ip_address,date_of_birth
1,Ivory,Overstreet,ioverstreet0@businessweek.com,Female,30.138.91.62,10/22/2018
2,Ulick,Vasnev,uvasnev1@vkontakte.ru,Male,35.15.164.70,01/19/2018
3,Chloe,Freemantle,cfreemantle2@parallels.com,Female,133.133.113.255,08/13/2018
"""

schema data: @data do
...
end
```

Note that it's not a requirement to map all fields, but every field mapped must
have a column in csv file.
For example the following field configuration will result in a compilation error:

```elixir
field :id, "non_existing_id", ...
```

Schema could be configured using a custom separator (default is ?,)
```elixir
use Csv.Schema, separator: ?,
```

Moreover it's possible to configure if csv file has or has not an header. Depending on header param value field config changes:
```elixir
# Default header value is `true`
use Csv.Schema
# Csv with header
schema path: "path/to/person.csv" do
  field :id, "id", key: true
  ...
end

# Csv without header. Note that field 1 is binded with the first csv column.
use Csv.Schema, header: false
# Index goes from 1 to N
schema path: "path/to/person.csv" do
  field :id, 1, key: true
  ...
end
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
- `get_all` return all csv rows as a Stream

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
- `:key` : boolean. At most one key could be set. If set to true creates the `by_{name}` function for you.
- `:unique` : boolean. If set to true creates the `by_{name}` function for you. All csv values must be unique or an exception is raised
- `:filter_by` : boolean. If set to true creates the `filter_by_{name}` function
- `:parser` : function. An arity 1 function used to map values from string to a custom type
- `:sort` : `:asc` or `:desc`. It sorts according to Erlang's term ordering with `nil` exception (`number < atom < reference < fun < port < pid < tuple < list < bit-string < nil`)
- `:join` : string. If present it joins the given fields into a binary using the separator


Note that every configuration is optional

## Keep in mind

Compilation time increase in an exponential manner if csv contains lots of lines and you
configure multiple fields candidate for method creation (flags `key`, `unique` and/or `filter_by` set to true).

Because "without data you're just another person with an opinion" here some data:

### Compilation time

| csv rows |   key | unique | filter_by |  compile time |
| -------: | ----: | -----: | --------: | ------------: |
|    1_000 | false |      0 |         0 |    301_727 µs |
|    1_000 | false |      2 |         0 |    352_522 µs |
|    1_000 | false |      0 |         4 |    318_225 µs |
|    1_000 |  true |      0 |         0 |    334_240 µs |
|    1_000 |  true |      1 |         1 |    348_697 µs |
|    1_000 |  true |      2 |         0 |    406_367 µs |
|    1_000 |  true |      0 |         4 |    385_850 µs |
|    1_000 |  true |      2 |         2 |    414_617 µs |
|    1_000 |  true |      2 |         4 |    446_155 µs |
|    5_000 | false |      0 |         0 |  2_734_565 µs |
|    5_000 | false |      2 |         0 |  3_450_438 µs |
|    5_000 | false |      0 |         4 |  3_464_593 µs |
|    5_000 |  true |      0 |         0 |  3_084_923 µs |
|    5_000 |  true |      1 |         1 |  3_795_718 µs |
|    5_000 |  true |      2 |         0 |  3_752_112 µs |
|    5_000 |  true |      0 |         4 |  3_387_067 µs |
|    5_000 |  true |      2 |         2 |  3_839_068 µs |
|    5_000 |  true |      2 |         4 |  4_113_228 µs |
|   10_000 | false |      0 |         0 |  6_889_505 µs |
|   10_000 | false |      2 |         0 |  8_667_683 µs |
|   10_000 | false |      0 |         4 |  8_606_961 µs |
|   10_000 |  true |      0 |         0 |  7_892_421 µs |
|   10_000 |  true |      1 |         1 |  8_449_838 µs |
|   10_000 |  true |      2 |         0 |  9_507_693 µs |
|   10_000 |  true |      0 |         4 | 10_339_080 µs |
|   10_000 |  true |      2 |         2 | 10_518_744 µs |
|   10_000 |  true |      2 |         4 | 10_480_884 µs |

### Execution time

| csv rows |  key | unique | filter_by |     by avg |    by tot | filter_by avg | filter_by tot |
| -------: | ---: | -----: | --------: | ---------: | --------: | ------------: | ------------: |
|    1_000 | true |      1 |         1 | 0.74 µs/op | 74_412 µs |    0.89 µs/op |     89_275 µs |
|    5_000 | true |      1 |         1 | 0.79 µs/op | 79_776 µs |    1.18 µs/op |    118_786 µs |
|   10_000 | true |      1 |         1 | 0.78 µs/op | 78_908 µs |    1.83 µs/op |    183_642 µs |

### Execution details
Executed on my machine:

    Lenovo Thinkpad T480
    CPU: Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
    RAM: 32GB

### Try yourself

If you like to run compilation benchmarks yourself:

```sh
iex -S mix
```
```elixir
c "benchmark/timings.exs"
```

