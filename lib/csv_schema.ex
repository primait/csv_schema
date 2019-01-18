defmodule Csv.Schema do
  @moduledoc """
    Csv schema is a library helping you to build Ecto schema-like files having as source a csv file.

    The idea behind this library is give the possibility to create, at compile-time,
    getters function for a CSV inside codebase.

    APIs related to this macro are similar to Ecto.Schema; Eg.

      defmodule Person do
        use Csv.Schema
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
  """

  alias Csv.Schema
  alias Csv.Schema.Parser
  alias Csv.Schema.Field

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      @type t :: %__MODULE__{}
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
          @content unquote(file_path) |> Parser.csv!()
          @rows_count Enum.count(@content)

          Module.put_attribute(__MODULE__, :in_, true)

          Module.register_attribute(__MODULE__, :fields, accumulate: true)
          Module.register_attribute(__MODULE__, :struct_fields, accumulate: true)
          Module.register_attribute(__MODULE__, :keys, accumulate: true)

          unquote(block)

          Schema.__check_csv_has_fields__!(@content, @fields)
          Schema.__check_key__!(@content, @fields)
          Schema.__check_unique__!(@content, @fields)

          Module.delete_attribute(__MODULE__, :in_)
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

          Schema.__gen_functions__(@content, @fields, internal_id_fn, by_fn, filter_by_fn)

          # Defaults

          def unquote(:__id__)(_), do: nil

          def get_all, do: 1..@rows_count |> Stream.map(&__MODULE__.__id__/1)

          default_by_fn = fn name -> def unquote(:"by_#{name}")(_), do: nil end

          default_filter_by_fn = fn name -> def unquote(:"filter_by_#{name}")(_), do: [] end

          Schema.__gen_defaults__(@fields, default_by_fn, default_filter_by_fn)

          # Cleanup

          Module.delete_attribute(__MODULE__, :struct_fields)
          Module.delete_attribute(__MODULE__, :fields)
          Module.delete_attribute(__MODULE__, :content)
        end
      end
    end
  end

  @doc """
  Configure a new field (csv column). Parameters are
  - `name`: new struct field name
  - `header`: header name in csv file
  - `opts`: list of configuration values
    - `key`: boolean; at most one key must be set. It is something similar to a primary key
    - `filter_by`: boolean; do i create a `filter_by_{name}` function for this field for you?
    - `unique`: boolean; creates a function `by_{name}` for you
    - `parser`: function; parser function used to transform data from string to custom type
  """
  defmacro field(name, header, opts \\ []) do
    quote do
      if @in_ do
        @fields Schema.__field__(__MODULE__, unquote(name), unquote(header), unquote(opts))
      else
        raise "Using 'field' macro outside 'schema' macro"
      end
    end
  end

  @doc false
  @spec __field__(module, term, term, []) :: Field.t()
  def __field__(mod, name, header, opts) do
    name = Parser.atom!(name)
    add_field_to_struct(mod, name)
    Field.new(name, header, opts)
  end

  @spec add_field_to_struct(module, atom) :: :ok | no_return
  defp add_field_to_struct(mod, name) do
    if mod |> Module.get_attribute(:struct_fields) |> List.keyfind(name, 0) do
      raise ArgumentError, "Field #{inspect(name)} is already set on schema"
    end

    Module.put_attribute(mod, :struct_fields, {name, nil})
  end

  ### Internal method creations

  @doc false
  @spec __gen_functions__(
          [map],
          [Field.t()],
          (String.t(), map -> :ok),
          (atom, term, map -> :ok),
          (atom, term, [] -> :ok)
        ) :: :ok
  def __gen_functions__(content, fields, internal_id_fn, by_fn, filter_by_fn) do
    gen_by_functions(content, fields, internal_id_fn, by_fn)
    gen_filter_by_functions(content, fields, filter_by_fn)
  end

  @spec gen_by_functions([map], [Field.t()], (String.t(), map -> :ok), (atom, term, map -> :ok)) :: :ok
  defp gen_by_functions(content, fields, internal_id_fn, by_fn) do
    Enum.each(content, fn row ->
      id = Map.get(row, :__id__)
      changeset = transform(row, fields)
      internal_id_fn.(id, changeset)
    end)

    Enum.each(content, fn row ->
      id = Map.get(row, :__id__)
      changeset = transform(row, fields)

      Enum.each(fields, fn
        %Field{name: name, key: true} -> by_fn.(name, Map.get(changeset, name), id)
        %Field{name: name, unique: true} -> by_fn.(name, Map.get(changeset, name), id)
        _ -> :ok
      end)
    end)
  end

  @spec gen_filter_by_functions([map], [Field.t()], (atom, term, [] -> :ok)) :: :ok
  defp gen_filter_by_functions(content, fields, filter_by_fn) do
    Enum.each(fields, fn
      %Field{name: name, filter_by: true} ->
        content
        |> Enum.group_by(&Map.get(transform(&1, fields), name))
        |> Enum.each(fn {key, value} -> filter_by_fn.(name, key, Enum.map(value, & &1.__id__)) end)

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

  @spec transform(map, [Field.t()]) :: map
  defp transform(row, fields) do
    Enum.reduce(fields, %{}, fn %Field{name: name, header: header, parser: parser}, acc ->
      Map.put(acc, name, parser.(Map.get(row, header)))
    end)
  end

  ### Validations

  @doc false
  @spec __check_key__!([map], [Field.t()]) :: :ok | no_return
  def __check_key__!(content, fields) do
    case Enum.filter(fields, & &1.key) do
      [] -> :ok
      [field] -> valid_key_field?(content, field)
      _ -> raise "Multiple keys defined"
    end
  end

  @spec valid_key_field?([map], [Field.t()]) :: :ok | no_return
  defp valid_key_field?(content, field) do
    values = Enum.map(content, &Map.get(&1, field.header))

    if Enum.count(values) != values |> Enum.uniq() |> Enum.count() do
      raise "Key field contains record where is empty, nil or not unique"
    else
      :ok
    end
  end

  @doc false
  @spec __check_csv_has_fields__!([map], [Field.t()]) :: :ok | no_return
  def __check_csv_has_fields__!(content, fields) do
    content
    |> Enum.take(1)
    |> Enum.each(fn row ->
      if match_all_fields?(row, fields), do: :ok, else: raise("Not all fields are mapped to csv")
    end)
  end

  @spec match_all_fields?(map, [Field.t()]) :: boolean
  defp match_all_fields?(row, fields) do
    Enum.all?(fields, fn %Field{header: header} -> Map.has_key?(row, header) end)
  end

  @doc false
  @spec __check_unique__!([tuple], [Field.t()]) :: :ok | no_return
  def __check_unique__!(content, fields) do
    Enum.each(fields, fn
      %Field{header: header, key: true} -> unique_or_raise!(content, header)
      %Field{header: header, unique: true} -> unique_or_raise!(content, header)
      _ -> :ok
    end)
  end

  @spec unique_or_raise!([tuple], term) :: :ok | no_return
  defp unique_or_raise!(content, header) do
    values =
      content
      |> Enum.map(&Map.get(&1, header))
      |> Enum.reject(fn value -> is_nil(value) || value == "" end)

    if Enum.count(values) != values |> Enum.uniq() |> Enum.count() do
      raise "Field #{header}, set as unique, contains duplicates"
    else
      :ok
    end
  end
end
