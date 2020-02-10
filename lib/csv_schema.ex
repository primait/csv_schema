defmodule Csv.Schema do
  @moduledoc """
    Csv schema is a library helping you to build Ecto schema-like files having as source a csv file.

    The idea behind this library is give the possibility to create, at compile-time,
    getters function for a CSV inside codebase.

    APIs related to this macro are similar to Ecto.Schema; Eg.

      defmodule Person do
        use Csv.Schema, headers: true, separator: ?,
        alias Csv.Schema.Parser

        schema "path/to/person.csv" do
          field :id, "id", key: true
          field :first_name, "first_name", filter_by: true
          field :last_name, "last_name", sort: :asc
          field :identifier, ["first_name", "last_name"], key: true, join: " "
          field :email, "email", unique: true
          field :gender, "gender", filter_by: true, sort: :desc
          field :ip_address, "ip_address"
          field :date_of_birth, "date_of_birth", parser: &Parser.date!(&1, "{0M}/{0D}/{0YYYY}")
        end
      end

    At the end of compilation now your module is a Struct and has 3 kind of getters:

    - `by_{key_field_name}` returns single records object or nil
    - `filter_by_{field_name}` returns list of records matching provided property
    - `get_all` returns all records


    Back to the example in the module will be created:


    - `__MODULE__.by_id/1` expecting integer as arg
    - `__MODULE__.filter_by_name/1` expecting string as arg
    - `__MODULE__.by_fiscal_code/1` expecting string as arg
    - `__MODULE__.get_all/0`

    Some example definitions could be found [here](https://github.com/primait/csv_schema/tree/master/examples)
  """

  alias Csv.Schema
  alias Csv.Schema.{Field, Parser}

  @type name :: String.t() | atom
  @type row :: map | list
  @type order :: :asc | :desc

  @doc """
  - `separator` it's possible to set a separator argument to macro to let the macro split csv for you using provided separator.
  - `header`    if your csv file does not have `headers`, it's possible to set headers to false and configure fields by index (1..N)
  """
  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__)
      @type t :: %__MODULE__{}
      @headers Keyword.get(unquote(opts), :headers, true)
      @separator Keyword.get(unquote(opts), :separator, ?,)
    end
  end

  @doc """
  Schema macro helps you to build a block of fields. First parameter should be
  the relative path to csv file in your project. Second parameter should be a `field` list
  included in `do`-`end` block
  """
  defmacro schema(file_path, do: block) do
    quote do
      unquote do
        quote do
          Module.put_attribute(__MODULE__, :external_resource, unquote(file_path))
          Module.put_attribute(__MODULE__, :in_, true)

          Module.register_attribute(__MODULE__, :fields, accumulate: true)
          Module.register_attribute(__MODULE__, :struct_fields, accumulate: true)
          Module.register_attribute(__MODULE__, :keys, accumulate: true)

          unquote(block)

          Module.delete_attribute(__MODULE__, :in_)
        end
      end

      unquote do
        quote bind_quoted: [file_path: file_path] do
          defstruct Module.get_attribute(__MODULE__, :struct_fields)

          fields = Module.get_attribute(__MODULE__, :fields)
          headers? = Module.get_attribute(__MODULE__, :headers)
          separator = Module.get_attribute(__MODULE__, :separator)
          content = Parser.csv!(file_path, headers?, separator)
          num_of_rows = Enum.count(content)

          #
          ## Validation
          #
          Schema.__validate__(content, fields, headers?)

          #
          ## Destination module function generators
          #
          generators = %{
            internal_id: fn id, changeset ->
              changeset = Map.delete(changeset, :__id__)
              def __id__(unquote(id)), do: struct!(__MODULE__, unquote(Macro.escape(changeset)))
            end,
            default_internal_id: fn ->
              def __id__(_), do: nil
            end,
            by: fn translation, name ->
              def unquote(:"by_#{name}")(value) do
                apply(__MODULE__, :__id__, [Map.get(unquote(Macro.escape(translation)), value)])
              end
            end,
            filter_by: fn translation, name ->
              def unquote(:"filter_by_#{name}")(value) do
                unquote(Macro.escape(translation)) |> Map.get(value, []) |> Enum.map(&apply(__MODULE__, :__id__, [&1]))
              end
            end,
            get_all: fn num_of_rows ->
              def get_all(), do: 1..unquote(num_of_rows) |> Stream.map(&apply(__MODULE__, :__id__, [&1]))
              def get_all(:materialized), do: 1..unquote(num_of_rows) |> Enum.map(&apply(__MODULE__, :__id__, [&1]))
            end
          }

          #
          ## Generation
          #
          Schema.__gen__(content, fields, generators)

          #
          ## Cleanup
          #
          Module.delete_attribute(__MODULE__, :separator)
          Module.delete_attribute(__MODULE__, :struct_fields)
          Module.delete_attribute(__MODULE__, :fields)
          Module.delete_attribute(__MODULE__, :headers)
        end
      end
    end
  end

  @doc """
  Configure a new field (csv column). Parameters are
  - `name` - new struct field name
  - `column` - header name or column index (if headers: false) in csv file
  - `opts` - list of configuration values
    - `:key` - boolean; at most one key must be set. It is something similar to a primary key
    - `:unique` - boolean; creates a function `by_{name}` for you
    - `:filter_by` - boolean; do i create a `filter_by_{name}` function for this field for you?
    - `:parser` - function; parser function used to get_changeset data from string to custom type
    - `:sort` - `:asc` or `:desc`; It sorts according to Erlang's term ordering with `nil` exception
    - `:join` - string; if present it joins the given fields into a binary using the separator
  """
  defmacro field(name, col, opts \\ []) do
    quote do
      if Module.get_attribute(__MODULE__, :in_, false) do
        @fields Schema.__field__(__MODULE__, unquote(name), unquote(col), unquote(opts))
      else
        raise "Using 'field' macro outside 'schema' macro"
      end
    end
  end

  @doc false
  @spec __field__(module, term, term, []) :: Field.t()
  def __field__(module, name, column, options) do
    name = Parser.atom!(name)

    if module |> Module.get_attribute(:struct_fields) |> List.keyfind(name, 0) do
      raise ArgumentError, "Field #{inspect(name)} already set in schema"
    end

    Module.put_attribute(module, :struct_fields, {name, nil})

    Field.new(name, column, options)
  end

  #
  ## Entrypoint for function generation
  #
  @doc false
  @spec __gen__(%Stream{}, list(Field.t()), %{atom => function}) :: :ok
  def __gen__(csv_stream, fields, generators) do
    changesets = get_changesets(csv_stream, fields)

    gen_internal_id(changesets, Map.fetch!(generators, :internal_id), Map.fetch!(generators, :default_internal_id))
    gen_by(changesets, fields, Map.fetch!(generators, :by))
    gen_filter_by(changesets, fields, Map.fetch!(generators, :filter_by))
    gen_get_all(changesets, Map.fetch!(generators, :get_all))
  end

  @spec gen_internal_id(list(map), function, function) :: :ok
  defp gen_internal_id(changesets, internal_id, default_internal_id) do
    Enum.each(changesets, &internal_id.(get_id(&1), &1))
    default_internal_id.()
  end

  @spec gen_by(list(map), list(Field.t()), function) :: :ok
  defp gen_by(changesets, fields, by) do
    Enum.each(fields, fn
      %Field{name: name, key: key, unique: unique} when key or unique ->
        changesets
        |> Enum.reduce(%{}, fn value, acc -> Map.put(acc, Map.get(value, name), Map.get(value, :__id__)) end)
        |> by.(name)

      _ ->
        :ok
    end)
  end

  @spec gen_filter_by(list(map), list(Field.t()), function) :: :ok
  defp gen_filter_by(changesets, fields, filter_by) do
    Enum.each(fields, fn
      %Field{name: name, filter_by: true} ->
        changesets
        |> Enum.group_by(fn changeset -> Map.get(changeset, name) end)
        |> Enum.reduce(%{}, fn {key, values}, acc -> Map.put(acc, key, Enum.map(values, &Map.get(&1, :__id__))) end)
        |> filter_by.(name)

      _ ->
        :ok
    end)
  end

  @spec gen_get_all(list(map), function) :: :ok
  defp gen_get_all(changesets, get_all), do: changesets |> Enum.count() |> get_all.()

  #
  ## Changeset
  #
  @spec get_changesets(%Stream{}, list(Field.t())) :: list
  defp get_changesets(content, fields) do
    content |> Enum.map(&to_changeset(&1, fields)) |> sort_changeset(fields) |> set_id()
  end

  @spec to_changeset(map, list(Field.t())) :: map
  defp to_changeset(row, fields) do
    Enum.reduce(fields, %{}, fn %Field{name: name, column: column, parser: parser, join: join}, acc ->
      Map.put(acc, name, parser.(get_value(row, column, join)))
    end)
  end

  @spec set_id(list(map)) :: list(map)
  defp set_id(changesets), do: changesets |> Enum.with_index(1) |> Enum.map(&set_index(&1))

  @spec set_index({row, non_neg_integer}) :: row
  defp set_index({row, index}) when is_map(row), do: Map.put(row, :__id__, index)
  defp set_index({row, index}) when is_list(row), do: [index | row]

  @spec get_id(row) :: term
  defp get_id(collection), do: get_value(collection, :__id__)

  @spec get_value(row, String.t() | atom | number, String.t()) :: term
  defp get_value(collection, columns, join \\ "")

  defp get_value(collection, columns, join) when is_list(columns) do
    columns |> Enum.map(&get_value(collection, &1, join)) |> Enum.join(join)
  end

  defp get_value(collection, elem, _) when is_map(collection), do: Map.get(collection, elem)
  defp get_value(collection, :__id__, _) when is_list(collection), do: Enum.at(collection, 0)
  defp get_value(collection, elem, _) when is_list(collection), do: Enum.at(collection, elem - 1)

  @spec sort_changeset(list(map), list(Field.t())) :: list(map)
  defp sort_changeset(changesets, fields) do
    Enum.reduce(fields, changesets, fn
      %Field{sort: nil}, cs -> cs
      %Field{name: name, sort: sort}, cs -> Enum.sort_by(cs, &Map.get(&1, name), &sorter(&1, &2, sort))
    end)
  end

  @spec sorter(any, any, order) :: boolean
  defp sorter(nil, _, :asc), do: false
  defp sorter(nil, _, :desc), do: true
  defp sorter(_, nil, :asc), do: true
  defp sorter(_, nil, :desc), do: false
  defp sorter(value1, value2, :asc), do: value1 <= value2
  defp sorter(value1, value2, :desc), do: value1 > value2

  #
  ## Validations
  #
  @spec __validate__(%Stream{}, list(Field.t()), boolean) :: :ok | no_return
  def __validate__(content, fields, headers) do
    validate_csv_not_empty(content)
    validate_csv_has_fields(content, fields, headers)
    validate_key(content, fields)
    validate_unique(content, fields)
  end

  @spec validate_csv_not_empty(%Stream{}) :: :ok | no_return
  defp validate_csv_not_empty(content) do
    if content |> Stream.take(1) |> Enum.count() > 0, do: :ok, else: raise("Provided csv is empty")
  end

  @spec validate_csv_has_fields(%Stream{}, list(Field.t()), boolean) :: :ok | no_return
  defp validate_csv_has_fields(content, fields, true) do
    content
    |> Stream.take(1)
    |> Enum.each(fn row ->
      if match_all_fields?(row, fields), do: :ok, else: raise("Not all fields are mapped to csv")
    end)
  end

  defp validate_csv_has_fields(content, fields, _) do
    content
    |> Stream.take(1)
    |> Enum.each(fn row ->
      fields
      |> Enum.map(fn %Field{column: column} -> column end)
      |> Enum.reject(fn
        column when is_list(column) -> Enum.all?(column, fn col -> col in 1..(length(row) - 1) end)
        column -> column in 1..(length(row) - 1)
      end)
      |> case do
        [] -> :ok
        cl -> raise "Indexes #{inspect(cl)} should be between 1 and #{length(row)}"
      end
    end)
  end

  @spec match_all_fields?(row, list(Field.t())) :: boolean
  defp match_all_fields?(row, fields) do
    Enum.all?(fields, fn
      %Field{column: column} when is_list(column) -> Enum.all?(column, &Map.has_key?(row, &1))
      %Field{column: column} -> Map.has_key?(row, column)
    end)
  end

  @spec validate_key(%Stream{}, list(Field.t())) :: :ok | no_return
  defp validate_key(content, fields) do
    case Enum.filter(fields, & &1.key) do
      [] -> :ok
      [field] -> valid_key_field?(content, field)
      fields -> raise "Multiple keys defined (#{fields |> Enum.map(& &1.column) |> Enum.join(", ")})"
    end
  end

  @spec valid_key_field?(%Stream{}, list(Field.t())) :: :ok | no_return
  defp valid_key_field?(content, field) do
    values = Enum.map(content, &get_value(&1, field.column, field.join))
    unique = values |> Enum.uniq() |> Enum.reject(fn value -> is_nil(value) || value == "" end) |> Enum.count()

    if Enum.count(values) != unique do
      raise "Key field #{field.column} contains empty, nil or not unique values: #{inspect(get_duplicates(values))}"
    else
      :ok
    end
  end

  @spec validate_unique(%Stream{}, list(Field.t())) :: :ok | no_return
  defp validate_unique(content, fields) do
    Enum.each(fields, fn
      %Field{column: column, key: true, join: join} -> unique_or_raise(content, column, join)
      %Field{column: column, unique: true, join: join} -> unique_or_raise(content, column, join)
      _ -> :ok
    end)
  end

  @spec unique_or_raise(%Stream{}, term, String.t()) :: :ok | no_return
  defp unique_or_raise(content, column, join) do
    values = content |> Stream.map(&get_value(&1, column, join)) |> Enum.reject(&(is_nil(&1) || &1 == ""))

    if Enum.count(values) != values |> Enum.uniq() |> Enum.count() do
      raise "Field #{column}, set as unique, contains duplicates: #{inspect(get_duplicates(values))}"
    else
      :ok
    end
  end

  @spec get_duplicates(list) :: list
  defp get_duplicates(list) do
    list
    |> Enum.reduce({%{}, %{}}, fn x, {elems, dupes} ->
      if Map.has_key?(elems, x), do: {elems, Map.put(dupes, x, nil)}, else: {Map.put(elems, x, nil), dupes}
    end)
    |> elem(1)
    |> Map.keys()
  end
end
