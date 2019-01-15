defmodule Csv.Schema do
  @moduledoc """
    Csv schema is a library helping you to build Ecto schema-like files having as source a csv file.

    The idea behind this library is give the possibility to create, at compile-time,
    getters function for a CSV inside codebase.

    APIs related to this macro are similar to Ecto.Schema; Eg.

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

    In order to let the plugin create automatically a unique primary key for you
    just set `@auto_primary_key` module attribute to true.
    By default is set to false

    At the end of compilation now your module is a Struct and has 3 kind of getters:

    - by_{key_field_name} -> returns single records object or nil
    - filter_by_{field_name} -> returns list of records matching provided property
    - get_all -> returns all records

    Back to the example in the module will be created:

      __MODULE__.by_id/1 expecting integer as arg
      __MODULE__.filter_by_name/1 expecting string as arg
      __MODULE__.by_fiscal_code/1 expecting string as arg
      __MODULE__.get_all/0
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

          Module.put_attribute(__MODULE__, :in_, true)

          Module.register_attribute(__MODULE__, :fields, accumulate: true)
          Module.register_attribute(__MODULE__, :struct_fields, accumulate: true)
          Module.register_attribute(__MODULE__, :keys, accumulate: true)

          unquote(block)

          Schema.__check_csv_has_fields__!(@content, @fields)
          Schema.__check_unique__!(@content, @fields)

          if @auto_primary_key do
            @fields Schema.__field__(__MODULE__, :id, "id",
                      key: true,
                      parser: &Parser.integer!/1
                    )

            @content @content
                     |> Stream.with_index(1)
                     |> Stream.map(fn {map, id} -> Map.put(map, "id", "#{id}") end)
          end

          Schema.__check_has_key_field__!(@fields)

          Module.delete_attribute(__MODULE__, :in_)
        end
      end

      unquote do
        quote unquote: false do
          defstruct @struct_fields

          # Creation of:
          #   - by_{field} functions
          #   - filter_by_{field} functions
          changesets = Schema.__changesets__(@content, @fields)

          by_key_function = fn name, changeset ->
            if not is_nil(Map.get(changeset, name)) do
              @keys Map.get(changeset, name)
              def unquote(:"by_#{name}")(unquote(Map.get(changeset, name))) do
                struct!(__MODULE__, unquote(Macro.escape(changeset)))
              end
            end
          end

          by_field_function = fn name, changeset ->
            if not is_nil(Map.get(changeset, name)) do
              def unquote(:"by_#{name}")(unquote(Map.get(changeset, name))) do
                struct!(__MODULE__, unquote(Macro.escape(changeset)))
              end
            end
          end

          filter_by_function = fn name, {key, value} ->
            if not is_nil(value) do
              def unquote(:"filter_by_#{name}")(unquote(key)) do
                Enum.map(unquote(Macro.escape(value)), &struct!(__MODULE__, &1))
              end
            end
          end

          Schema.__getters__(@fields, changesets, by_key_function, by_field_function, filter_by_function)

          # Creation of:
          #   - default functions for key and unique fields returning nil
          #   - default functions for filter_by fields returning empty list
          #   - get_all function returning all csv rows as struct
          Enum.each(@fields, fn
            %Field{name: name, key: true} ->
              def unquote(:"by_#{name}")(_), do: nil
              def get_all, do: Enum.map(@keys, &apply(__MODULE__, :"by_#{unquote(name)}", [&1]))

            %Field{name: name, unique: true} ->
              def unquote(:"by_#{name}")(_), do: nil

            %Field{name: name, filter_by: true} ->
              def unquote(:"filter_by_#{name}")(_), do: []

            _ ->
              :ok
          end)

          # Cleaning up
          Module.delete_attribute(__MODULE__, :auto_primary_key)
          Module.delete_attribute(__MODULE__, :struct_fields)
          Module.delete_attribute(__MODULE__, :fields)
          Module.delete_attribute(__MODULE__, :content)
        end
      end
    end
  end

  @doc """
  Configure a new field (csv column). Parameters are
  - name: new struct field name
  - header: header name in csv file
  - opts: list of configuration values
    - key: boolean; only one key could be set. It is something similar to a primary key
    - filter_by: boolean; do i create a filter_by_{name} function for this field for you?
    - unique: boolean; creates a function by_{name} for you
    - parser: function; parser function used to transform data from string to custom type
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

  @doc false
  @spec __changesets__([map], [Field.t()]) :: [map]
  def __changesets__(content, fields) do
    Enum.map(content, fn row -> get_changeset(row, fields) end)
  end

  @doc false
  @spec get_changeset(map, [Field.t()]) :: map
  defp get_changeset(row, fields) do
    Enum.reduce(fields, %{}, fn %Field{name: name, header: header, parser: parser}, acc ->
      Map.put(acc, name, parser.(Map.get(row, header)))
    end)
  end

  @doc false
  @spec add_field_to_struct(module, atom) :: :ok | no_return
  defp add_field_to_struct(mod, name) do
    if mod |> Module.get_attribute(:struct_fields) |> List.keyfind(name, 0) do
      raise ArgumentError, "Field #{inspect(name)} is already set on schema"
    end

    Module.put_attribute(mod, :struct_fields, {name, nil})
  end

  @doc false
  @spec __check_csv_has_fields__!([tuple], [Field.t()]) :: :ok | no_return
  def __check_csv_has_fields__!(csv, fields) do
    Enum.each(csv, fn row ->
      if match_all_fields?(row, fields), do: :ok, else: raise("Not all fields are mapped to csv")
    end)
  end

  @doc false
  @spec match_all_fields?(map, [Field.t()]) :: boolean
  defp match_all_fields?(row, fields) do
    Enum.all?(fields, fn %Field{header: header} -> Map.has_key?(row, header) end)
  end

  @doc false
  @spec __check_unique__!([tuple], [Field.t()]) :: :ok | no_return
  def __check_unique__!(csv, fields) do
    Enum.each(fields, fn
      %Field{header: header, key: true} ->
        unique_or_raise!(csv, header)

      %Field{header: header, unique: true} ->
        unique_or_raise!(csv, header)

      _ ->
        :ok
    end)
  end

  @doc false
  @spec unique_or_raise!([tuple], term) :: :ok | no_return
  defp unique_or_raise!(csv, header) do
    values =
      csv
      |> Enum.map(&Map.get(&1, header))
      |> Enum.reject(fn value -> is_nil(value) || value == "" end)

    if Enum.count(values) != values |> Enum.uniq() |> Enum.count() do
      raise "Field #{header}, set as unique, contains duplicates"
    else
      :ok
    end
  end

  @doc false
  @spec __check_has_key_field__!([Field.t()]) :: :ok | no_return
  def __check_has_key_field__!(fields) do
    case Enum.filter(fields, fn %Field{key: key} -> key end) do
      [] -> raise "No key defined"
      [_] -> :ok
      _ -> raise "Multiple keys defined"
    end
  end

  @doc false
  @spec __getters__([Field.t()], [map], (atom, map -> :ok), (atom, tuple -> :ok), (atom, tuple -> :ok)) :: :ok
  def __getters__(fields, changesets, by_key_fun, by_field_fun, filter_by_fun) do
    Enum.each(fields, fn
      # by_{key} function creation
      %Field{name: name, key: true} ->
        Enum.each(changesets, &by_key_fun.(name, &1))

      # by_{field} function creation for unique nonkey fields
      %Field{name: name, unique: true} ->
        Enum.each(changesets, &by_field_fun.(name, &1))

      # filter_by_{key} function creation
      %Field{name: name, filter_by: true} ->
        changesets
        |> Enum.group_by(fn changeset -> Map.get(changeset, name) end)
        |> Enum.each(&filter_by_fun.(name, &1))

      _ ->
        :ok
    end)
  end
end
