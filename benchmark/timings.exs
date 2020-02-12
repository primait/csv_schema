defmodule Utils do
  @moduledoc false

  @module_name_pattern "KS.U1.F1"

  @compile_time_headers ["csv rows", "key", "unique", "filter_by", "compile time"]

  @runtime_headers [
    "csv rows",
    "key",
    "unique",
    "filter_by",
    "by avg",
    "by tot",
    "filter_by avg",
    "filter_by tot"
  ]

  # Compilation benchmark utils
  @spec measure_compile_time(list(String.t())) :: list(module)
  def measure_compile_time(benchmark_files) do
    list =
      benchmark_files
      |> Enum.map(fn file -> :timer.tc(fn -> Code.compile_string(load(file)) end) end)
      |> Enum.map(fn {micros, [{module, _}]} -> {module, ["#{format(micros)} µs"]} end)

    print_as_markdown_table(@compile_time_headers, list)
    Enum.map(list, &elem(&1, 0))
  end

  @spec load(String.t()) :: String.t()
  defp load(file) do
    content = File.read!(file)
    [head | tail] = String.split(content, "\n")
    Enum.join([String.replace(head, " do", ".T#{:os.system_time(:millisecond)} do") | tail], "\n")
  end

  @spec measure_runtime(list(module)) :: :ok
  def measure_runtime(modules) do
    modules
    |> Enum.filter(&(&1 |> to_string() |> String.contains?(@module_name_pattern)))
    |> warmup()
    |> Enum.map(fn module ->
      {by_micros, _} = tc(module, "by_")
      {filter_micros, _} = tc(module, "filter_by_")

      by_micros_per_op = if is_binary(by_micros), do: by_micros, else: to_string(Float.floor(by_micros / 100_000, 2))

      filter_micros_per_op =
        if is_binary(filter_micros), do: filter_micros, else: to_string(Float.floor(filter_micros / 100_000, 2))

      {module,
       [
         "#{by_micros_per_op} µs/op",
         "#{format(by_micros)} µs",
         "#{filter_micros_per_op} µs/op",
         "#{format(filter_micros)} µs"
       ]}
    end)
    |> (fn list -> print_as_markdown_table(@runtime_headers, list) end).()
  end

  @spec tc(module, String.t()) :: {non_neg_integer, module}
  defp tc(module, predicate) do
    case prepare(module, predicate) do
      nil ->
        {"-", ""}

      {by_function, by_values} ->
        :timer.tc(fn -> Enum.each(1..1_000, fn _ -> Enum.each(by_values, &apply(module, by_function, [&1])) end) end)
    end
  end

  @spec prepare(module, String.t()) :: nil | {atom, list(any)}
  defp prepare(module, fun_string) do
    case find_function(module, fun_string) do
      nil -> raise("function not found.. #{module}.#{fun_string}")
      {fun, key} -> {String.to_atom("#{fun}#{key}"), fetch_random_values(module, key)}
    end
  end

  @spec find_function(module, String.t()) :: nil | {atom, atom}
  defp find_function(module, fun_string) do
    :functions
    |> module.__info__()
    |> Enum.map(&(&1 |> elem(0) |> to_string()))
    |> Enum.map(fn binary ->
      if String.starts_with?(binary, fun_string) do
        {String.to_atom(fun_string), binary |> String.replace(fun_string, "") |> String.to_atom()}
      end
    end)
    |> Enum.find(&(not is_nil(&1)))
  end

  @spec fetch_random_values(module, atom) :: list(any)
  defp fetch_random_values(module, key) do
    module |> apply(:get_all, []) |> Enum.take_random(100) |> Enum.map(&Map.get(&1, key))
  end

  @spec warmup(list(module)) :: list(module)
  defp warmup(modules) do
    Enum.each(modules, & &1.get_all(:materialized))
    modules
  end

  @spec print_as_markdown_table(list(String.t()), list({module, list(String.t())})) :: :ok
  defp print_as_markdown_table(headers, list) do
    separator = Enum.map(headers, fn _ -> ":" end)
    values = Enum.map(list, fn {module, vals} -> Enum.map(module.description(), &to_string/1) ++ vals end)
    full_list = [headers | [separator | values]]

    lengths =
      Enum.map(0..length(headers), fn id ->
        full_list |> Enum.map(fn row -> row |> Enum.at(id) |> to_string() |> String.length() end) |> Enum.max()
      end)

    header = headers |> Enum.with_index() |> Enum.map(fn {v, i} -> pad(v, lengths, i) end)
    separator = separator |> Enum.with_index() |> Enum.map(fn {v, i} -> pad(v, lengths, i, "-") end)
    list = Enum.map(values, &(&1 |> Enum.with_index() |> Enum.map(fn {v, i} -> pad(v, lengths, i) end)))

    [header | [separator | list]] |> Enum.map(&Enum.join(&1, " | ")) |> Enum.each(fn row -> IO.puts("| #{row} |") end)
  end

  @spec pad(String.t(), list(non_neg_integer), non_neg_integer, String.t()) :: String.t()
  defp pad(values, lengths, index, char \\ " "), do: String.pad_leading(values, Enum.at(lengths, index), [char])

  defp format(number) when is_binary(number) do
    number
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&(&1 |> Enum.reverse() |> Enum.join()))
    |> Enum.reverse()
    |> Enum.join("_")
  end

  defp format(number), do: number |> to_string() |> format()
end

benchmark_files = [
  "benchmark/R1_000.KN.U0.F0.exs",
  "benchmark/R1_000.KN.U2.F0.exs",
  "benchmark/R1_000.KN.U0.F4.exs",
  "benchmark/R1_000.KS.U0.F0.exs",
  "benchmark/R1_000.KS.U1.F1.exs",
  "benchmark/R1_000.KS.U2.F0.exs",
  "benchmark/R1_000.KS.U0.F4.exs",
  "benchmark/R1_000.KS.U2.F2.exs",
  "benchmark/R1_000.KS.U2.F4.exs",
  "benchmark/R5_000.KN.U0.F0.exs",
  "benchmark/R5_000.KN.U2.F0.exs",
  "benchmark/R5_000.KN.U0.F4.exs",
  "benchmark/R5_000.KS.U0.F0.exs",
  "benchmark/R5_000.KS.U1.F1.exs",
  "benchmark/R5_000.KS.U2.F0.exs",
  "benchmark/R5_000.KS.U0.F4.exs",
  "benchmark/R5_000.KS.U2.F2.exs",
  "benchmark/R5_000.KS.U2.F4.exs",
  "benchmark/R10_000.KN.U0.F0.exs",
  "benchmark/R10_000.KN.U2.F0.exs",
  "benchmark/R10_000.KN.U0.F4.exs",
  "benchmark/R10_000.KS.U0.F0.exs",
  "benchmark/R10_000.KS.U1.F1.exs",
  "benchmark/R10_000.KS.U2.F0.exs",
  "benchmark/R10_000.KS.U0.F4.exs",
  "benchmark/R10_000.KS.U2.F2.exs",
  "benchmark/R10_000.KS.U2.F4.exs"
]

# To run it:
#   iex -S mix
#   iex> c "benchmark/timings.exs"

IO.puts("\n### Compilation time\n")

modules = Utils.measure_compile_time(benchmark_files)

IO.puts("\n### Execution time\n")

Utils.measure_runtime(modules)

IO.puts("\n")
