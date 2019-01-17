defmodule Csv.Schema.Field do
  @moduledoc false

  alias Csv.Schema.Parser

  defstruct name: "",
            header: "",
            parser: &Parser.string!/1,
            key: false,
            unique: false,
            filter_by: false

  @type t :: %__MODULE__{}

  @doc false
  @spec new(atom, String.t(), Keyword.t()) :: t
  def new(name, header, opts) do
    struct!(__MODULE__,
      name: name,
      header: header,
      parser: Keyword.get(opts, :parser, &Parser.string!/1),
      key: Keyword.get(opts, :key, false),
      unique: Keyword.get(opts, :unique, false),
      filter_by: Keyword.get(opts, :filter_by, false)
    )
  end
end
