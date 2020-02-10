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


Is possible to create an Ecto.Schema-like repository using `Csv.Schema` macro:

```elixir
defmodule Person do
  use Csv.Schema
  alias Csv.Schema.Parser

  schema "path/to/person.csv" do
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

Note that it's not a requirement to map all fields, but every field mapped must
have a column in csv file.
For example the following field configuration will result in a compilation error:

```elixir
field :id, "non_existing_id", ...
```

Schema could be configured using a custom separator
```elixir
use Csv.Schema, separator: ?,
```

Moreover it's possible to configure if csv file has or has not an header. Depending on header param value field config changes:
```elixir
# Default header value is `true`
use Csv.Schema
# Csv with header
schema "path/to/person.csv" do
  field :id, "id", key: true
  ...
end

# Csv without header. Note that field 1 is binded with the first csv column.
use Csv.Schema, header: false
# Index goes from 1 to N
schema "path/to/person.csv" do
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

csv rows | key | unique | filter_by | compile time µs |
--------:|:---:|:------:|:---------:|----------------:|
1_000    | no  | 0      | 0         |      271_678 µs |
1_000    | yes | 1      | 1         |      374_888 µs |
1_000    | yes | 2      | 2         |      434_318 µs |
1_000    | yes | 2      | 4         |      495_503 µs |
1_000    | yes | 2      | 0         |      448_331 µs |
1_000    | yes | 0      | 4         |      402_463 µs |
1_000    | no  | 2      | 0         |      358_757 µs |
1_000    | no  | 0      | 4         |      330_966 µs |
5_000    | no  | 0      | 0         |    2_866_684 µs |
5_000    | yes | 1      | 1         |    3_692_311 µs |
5_000    | yes | 2      | 2         |    4_163_759 µs |
5_000    | yes | 2      | 4         |    4_346_686 µs |
5_000    | yes | 2      | 0         |    4_257_895 µs |
5_000    | yes | 0      | 4         |    3_709_629 µs |
5_000    | no  | 2      | 0         |    3_738_874 µs |
5_000    | no  | 0      | 4         |    3_320_761 µs |
10_000   | no  | 0      | 0         |    7_072_046 µs |
10_000   | yes | 1      | 1         |    9_101_119 µs |
10_000   | yes | 2      | 2         |   10_747_743 µs |
10_000   | yes | 2      | 4         |   11_581_694 µs |
10_000   | yes | 2      | 0         |   10_424_745 µs |
10_000   | yes | 0      | 4         |   10_294_739 µs |
10_000   | no  | 2      | 0         |    9_602_672 µs |
10_000   | no  | 0      | 4         |    8_943_906 µs |

### Execution time
csv rows | key | unique | filter_by | iterations | by average    | by total  | filter_by average | filter_by total |  
--------:|:---:|:------:|:---------:|:----------:|--------------:|----------:|------------------:|----------------:|
1_000    | no  | 0      | 0         |   100_000  |       - µs/op |      - µs |           - µs/op |            - µs | 
1_000    | yes | 1      | 1         |   100_000  | 0.80432 µs/op | 80_432 µs |     0.83547 µs/op |       83_547 µs | 
1_000    | yes | 2      | 2         |   100_000  | 0.84903 µs/op | 84_903 µs |     0.95210 µs/op |       95_210 µs | 
1_000    | yes | 2      | 4         |   100_000  | 0.86213 µs/op | 86_213 µs |     2.90434 µs/op |      290_434 µs | 
1_000    | yes | 2      | 0         |   100_000  | 0.87511 µs/op | 87_511 µs |           - µs/op |            - µs | 
1_000    | yes | 0      | 4         |   100_000  | 0.81143 µs/op | 81_143 µs |     2.86496 µs/op |      286_496 µs | 
1_000    | no  | 2      | 0         |   100_000  | 0.89268 µs/op | 89_268 µs |           - µs/op |            - µs | 
1_000    | no  | 0      | 4         |   100_000  |       - µs/op |      - µs |     2.85413 µs/op |      285_413 µs | 
5_000    | no  | 0      | 0         |   100_000  |       - µs/op |      - µs |           - µs/op |            - µs | 
5_000    | yes | 1      | 1         |   100_000  | 0.83897 µs/op | 83_897 µs |     1.18096 µs/op |      118_096 µs | 
5_000    | yes | 2      | 2         |   100_000  | 0.88148 µs/op | 88_148 µs |     1.45204 µs/op |      145_204 µs | 
5_000    | yes | 2      | 4         |   100_000  | 0.87794 µs/op | 87_794 µs |    10.66272 µs/op |    1_066_272 µs | 
5_000    | yes | 2      | 0         |   100_000  | 0.89623 µs/op | 89_623 µs |           - µs/op |            - µs | 
5_000    | yes | 0      | 4         |   100_000  | 0.83727 µs/op | 83_727 µs |    10.98493 µs/op |    1_098_493 µs | 
5_000    | no  | 2      | 0         |   100_000  | 0.90878 µs/op | 90_878 µs |           - µs/op |            - µs | 
5_000    | no  | 0      | 4         |   100_000  |       - µs/op |      - µs |    11.23213 µs/op |    1_123_213 µs | 
10_000   | no  | 0      | 0         |   100_000  |       - µs/op |      - µs |           - µs/op |            - µs | 
10_000   | yes | 1      | 1         |   100_000  | 0.81363 µs/op | 81_363 µs |     1.71314 µs/op |      171_314 µs | 
10_000   | yes | 2      | 2         |   100_000  | 0.89351 µs/op | 89_351 µs |     1.91236 µs/op |      191_236 µs | 
10_000   | yes | 2      | 4         |   100_000  | 0.89657 µs/op | 89_657 µs |    21.67663 µs/op |    2_167_663 µs | 
10_000   | yes | 2      | 0         |   100_000  | 0.92473 µs/op | 92_473 µs |           - µs/op |            - µs | 
10_000   | yes | 0      | 4         |   100_000  | 0.85811 µs/op | 85_811 µs |    21.72721 µs/op |    2_172_721 µs | 
10_000   | no  | 2      | 0         |   100_000  | 0.91188 µs/op | 91_188 µs |           - µs/op |            - µs | 
10_000   | no  | 0      | 4         |   100_000  |       - µs/op |      - µs |    22.04203 µs/op |    2_204_203 µs | 

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

