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
          field :id, "ID", key: true, parser: &Parser.integer!/1
          field :name, "Name", filter_by: true
          field :fiscal_code, "Fiscal Code", unique: true
          field :birth, "Date of birth", parser: &Parser.date!(&1, "{0D}/{0M}/{0YYYY}")
        end
      end

    At the end of compilation now your module is a Struct and has 3 kind of getters:

    - `by_{key_field_name}` -> returns single records object or nil
    - `filter_by_{field_name}` -> returns list of records matching provided property
    - `get_all` -> returns all records


    Back to the example in the module will be created:


    - `__MODULE__.by_id/1` expecting integer as arg
    - `__MODULE__.filter_by_name/1` expecting string as arg
    - `__MODULE__.by_fiscal_code/1` expecting string as arg
    - `__MODULE__.get_all/0`

    Some example definitions could be found [here](https://github.com/primait/csv_schema/tree/master/examples)
  """

  alias Csv.Schema
  alias Csv.Schema.Parser
  alias Csv.Schema.Field

  @doc """
  It's possible to set a :separator argument to macro to let the macro split csv
    for you using provided separator.
    Moreover, if your csv file does not have headers, it's possible to set headers to false
    and configure fields by index (1..N)
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
  schema macro helps you to build a block of fields. First parameter should be
  the relative path to csv file in your project. Second parameter should be a `field` list
  included in `do`-`end` block
  """
  defmacro schema(file_path, do: block) do
    quote do
      unquote do
        quote do
          @content unquote(file_path) |> Parser.csv!(@headers, @separator)
          @rows_count Enum.count(@content)
          @external_resource unquote(file_path)

          Module.put_attribute(__MODULE__, :in_, true)

          Module.register_attribute(__MODULE__, :fields, accumulate: true)
          Module.register_attribute(__MODULE__, :struct_fields, accumulate: true)
          Module.register_attribute(__MODULE__, :keys, accumulate: true)

          unquote(block)

          Schema.__checks__!(@content, @fields, @headers)

          Module.delete_attribute(__MODULE__, :in_)
          Module.delete_attribute(__MODULE__, :separator)
        end
      end

      unquote do
        quote unquote: false do
          defstruct @struct_fields

          # Functions

          internal_id_fn = fn value, changeset ->
            def unquote(:__id__)(unquote(value)) do
              struct!(__MODULE__, unquote(Macro.escape(changeset)))
            end
          end

          by_fn = fn name, value, id ->
            def unquote(:"by_#{name}")(unquote(value)), do: apply(__MODULE__, :__id__, [unquote(id)])
          end

          filter_by_fn = fn name, value, ids ->
            def unquote(:"filter_by_#{name}")(unquote(value)) do
              unquote(Macro.escape(ids)) |> Enum.map(&apply(__MODULE__, :__id__, [&1]))
            end
          end

          Schema.__gen_functions__(@content, @fields, @headers, internal_id_fn, by_fn, filter_by_fn)

          # Defaults

          def unquote(:__id__)(_), do: nil

          def get_all(), do: 1..@rows_count |> Stream.map(&__MODULE__.__id__/1)
          def get_all(:materialized), do: 1..@rows_count |> Enum.map(&__MODULE__.__id__/1)

          default_by_fn = fn name -> def unquote(:"by_#{name}")(_), do: nil end

          default_filter_by_fn = fn name -> def unquote(:"filter_by_#{name}")(_), do: [] end

          Schema.__gen_defaults__(@fields, default_by_fn, default_filter_by_fn)

          # Cleanup

          Module.delete_attribute(__MODULE__, :struct_fields)
          Module.delete_attribute(__MODULE__, :fields)
          Module.delete_attribute(__MODULE__, :content)
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
    - `key` - boolean; at most one key must be set. It is something similar to a primary key
    - `filter_by` - boolean; do i create a `filter_by_{name}` function for this field for you?
    - `unique` - boolean; creates a function `by_{name}` for you
    - `parser` - function; parser function used to get_changeset data from string to custom type
  """
  defmacro field(name, col, opts \\ []) do
    quote do
      if @in_ do
        @fields Schema.__field__(__MODULE__, unquote(name), unquote(col), unquote(opts))
      else
        raise "Using 'field' macro outside 'schema' macro"
      end
    end
  end

  @doc false
  @spec __field__(module, term, term, []) :: Field.t()
  def __field__(mod, name, col, opts) do
    name = Parser.atom!(name)
    add_field_to_struct(mod, name)
    Field.new(name, col, opts)
  end

  @spec add_field_to_struct(module, atom) :: :ok | no_return
  defp add_field_to_struct(mod, name) do
    if mod |> Module.get_attribute(:struct_fields) |> List.keyfind(name, 0) do
      raise ArgumentError, "Field #{inspect(name)} already set in schema"
    end

    Module.put_attribute(mod, :struct_fields, {name, nil})
  end

  ### Internal method creations

  @doc false
  @spec __gen_functions__(
          %Stream{},
          [Field.t()],
          boolean,
          (String.t(), map -> :ok),
          (atom, term, map -> :ok),
          (atom, term, [] -> :ok)
        ) :: :ok
  def __gen_functions__(content, fields, headers, internal_id_fn, by_fn, filter_by_fn) do
    indexed_changesets = Stream.map(content, &to_changeset(&1, fields, headers))
    gen_by_functions(indexed_changesets, fields, internal_id_fn, by_fn)
    gen_filter_by_functions(indexed_changesets, fields, filter_by_fn)
  end

  @spec gen_by_functions(%Stream{}, [Field.t()], (String.t(), map -> :ok), (atom, term, map -> :ok)) :: :ok
  defp gen_by_functions(content, fields, internal_id_fn, by_fn) do
    Enum.each(content, fn {id, changeset} ->
      internal_id_fn.(id, changeset)

      Enum.each(fields, fn
        %Field{name: name, key: true} ->
          value = Map.get(changeset, name)
          if not is_nil(value), do: by_fn.(name, value, id)

        %Field{name: name, unique: true} ->
          value = Map.get(changeset, name)
          if not is_nil(value), do: by_fn.(name, value, id)

        _ ->
          :ok
      end)
    end)
  end

  @spec gen_filter_by_functions(%Stream{}, [Field.t()], (atom, term, [] -> :ok)) :: :ok
  defp gen_filter_by_functions(indexed_changesets, fields, filter_by_fn) do
    Enum.each(fields, fn
      %Field{name: name, filter_by: true} ->
        indexed_changesets
        |> Enum.group_by(fn {_, changeset} -> Map.get(changeset, name) end)
        |> Enum.each(fn {key, values} ->
          filter_by_fn.(name, key, Enum.map(values, fn {id, _} -> id end))
        end)

      _ ->
        :ok
    end)
  end

  @doc false
  @spec __gen_defaults__([Field.t()], (atom -> :ok), (atom -> :ok)) :: :ok
  def __gen_defaults__(fields, default_by_fn, default_filter_by_fn) do
    Enum.each(fields, fn
      %Field{name: name, key: true} -> default_by_fn.(name)
      %Field{name: name, unique: true} -> default_by_fn.(name)
      %Field{name: name, filter_by: true} -> default_filter_by_fn.(name)
      _ -> :ok
    end)
  end

  @spec to_changeset(map, [Field.t()], boolean) :: {any, map}
  defp to_changeset(row, fields, headers) do
    {
      get_value(row, :__id__, headers),
      Enum.reduce(fields, %{}, fn %Field{name: name, column: column, parser: parser, join: join}, acc ->
        Map.put(acc, name, parser.(get_value(row, column, headers, join)))
      end)
    }
  end

  @spec get_value(map | list, String.t() | atom | number, boolean, String.t()) :: term
  defp get_value(collection, cols, header, join \\ "")

  defp get_value(collection, cols, header, join) when is_list(cols) do
    cols
    |> Enum.map(fn column -> get_value(collection, column, header, join) end)
    |> Enum.join(join)
  end

  defp get_value(collection, elem, true, _), do: Map.get(collection, elem)
  defp get_value(collection, :__id__, _, _), do: Enum.at(collection, 0)
  defp get_value(collection, elem, _, _), do: Enum.at(collection, elem)

  ### Validations

  @spec __checks__!([map | []], [Field.t()], boolean) :: :ok | no_return
  def __checks__!(content, fields, headers) do
    check_csv_has_fields!(content, fields, headers)
    check_key!(content, fields, headers)
    check_unique!(content, fields, headers)
  end

  @doc false
  @spec check_key!([map | list], [Field.t()], boolean) :: :ok | no_return
  defp check_key!(content, fields, headers) do
    case Enum.filter(fields, & &1.key) do
      [] -> :ok
      [field] -> valid_key_field?(content, field, headers)
      fields -> raise "Multiple keys defined (#{fields |> Enum.map(& &1.column) |> Enum.join(", ")})"
    end
  end

  @spec valid_key_field?([map], [Field.t()], boolean) :: :ok | no_return
  defp valid_key_field?(content, field, headers) do
    values = Enum.map(content, &get_value(&1, field.column, headers, field.join))

    unique = values |> Enum.uniq() |> Enum.reject(fn value -> is_nil(value) || value == "" end) |> Enum.count()

    if Enum.count(values) != unique do
      raise "Key field #{field.column} contains empty, nil or not unique values: #{inspect(duplicates(values))}"
    else
      :ok
    end
  end

  @doc false
  @spec check_csv_has_fields!([map | []], [Field.t()], boolean) :: :ok | no_return
  defp check_csv_has_fields!(content, fields, true) do
    content
    |> Enum.take(1)
    |> Enum.each(fn row ->
      if match_all_fields?(row, fields), do: :ok, else: raise("Not all fields are mapped to csv")
    end)
  end

  defp check_csv_has_fields!(content, fields, _) do
    content
    |> Enum.take(1)
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

  @spec match_all_fields?(map, [Field.t()]) :: boolean
  defp match_all_fields?(row, fields) do
    Enum.all?(fields, fn
      %Field{column: column} when is_list(column) -> Enum.all?(column, &Map.has_key?(row, &1))
      %Field{column: column} -> Map.has_key?(row, column)
    end)
  end

  @doc false
  @spec check_unique!([tuple], [Field.t()], boolean) :: :ok | no_return
  def check_unique!(content, fields, headers) do
    Enum.each(fields, fn
      %Field{column: column, key: true, join: join} -> unique_or_raise!(content, column, headers, join)
      %Field{column: column, unique: true, join: join} -> unique_or_raise!(content, column, headers, join)
      _ -> :ok
    end)
  end

  @spec unique_or_raise!([tuple], term, boolean, String.t()) :: :ok | no_return
  defp unique_or_raise!(content, column, headers, join) do
    values =
      content
      |> Enum.map(&get_value(&1, column, headers, join))
      |> Enum.reject(fn value -> is_nil(value) || value == "" end)

    if Enum.count(values) != values |> Enum.uniq() |> Enum.count() do
      raise "Field #{column}, set as unique, contains duplicates: #{inspect(duplicates(values))}"
    else
      :ok
    end
  end

  @spec duplicates([]) :: []
  defp duplicates(list) do
    list
    |> Enum.reduce({%{}, %{}}, fn x, {elems, dupes} ->
      case Map.has_key?(elems, x) do
        true -> {elems, Map.put(dupes, x, nil)}
        false -> {Map.put(elems, x, nil), dupes}
      end
    end)
    |> elem(1)
    |> Map.keys()
  end
end
