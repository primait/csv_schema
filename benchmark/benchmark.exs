# Rename file to .ex to let it be compiled

defmodule R1_000.KN.U0.F0 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_1_000.csv" do
    field :first_name, "first_name"
    field :last_name, "last_name"
    field :email, "email"
    field :gender, "gender"
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R1_000.KS.U1.F1 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_1_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R1_000.KS.U2.F2 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_1_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R1_000.KS.U2.F4 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_1_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name", filter_by: true
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth", filter_by: true
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R1_000.KS.U2.F0 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_1_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name"
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender"
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R1_000.KS.U0.F4 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_1_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name", filter_by: true
    field :email, "email"
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", filter_by: true
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R1_000.KN.U2.F0 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_1_000.csv" do
    field :id, "id"
    field :first_name, "first_name"
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender"
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R1_000.KN.U0.F4 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_1_000.csv" do
    field :id, "id"
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name", filter_by: true
    field :email, "email"
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", filter_by: true
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R5_000.KN.U0.F0 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_5_000.csv" do
    field :first_name, "first_name"
    field :last_name, "last_name"
    field :email, "email"
    field :gender, "gender"
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R5_000.KS.U1.F1 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_5_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R5_000.KS.U2.F2 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_5_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R5_000.KS.U2.F4 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_5_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name", filter_by: true
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth", filter_by: true
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R5_000.KS.U2.F0 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_5_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name"
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender"
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R5_000.KS.U0.F4 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_5_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name", filter_by: true
    field :email, "email"
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", filter_by: true
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R5_000.KN.U2.F0 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_5_000.csv" do
    field :id, "id"
    field :first_name, "first_name"
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender"
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R5_000.KN.U0.F4 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_5_000.csv" do
    field :id, "id"
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name", filter_by: true
    field :email, "email"
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", filter_by: true
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R10_000.KN.U0.F0 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_10_000.csv" do
    field :first_name, "first_name"
    field :last_name, "last_name"
    field :email, "email"
    field :gender, "gender"
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R10_000.KS.U1.F1 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_10_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R10_000.KS.U2.F2 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_10_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R10_000.KS.U2.F4 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_10_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name", filter_by: true
    field :email, "email", unique: true
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth", filter_by: true
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R10_000.KS.U2.F0 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_10_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name"
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender"
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R10_000.KS.U0.F4 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_10_000.csv" do
    field :id, "id", key: true, parser: &integer!/1
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name", filter_by: true
    field :email, "email"
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", filter_by: true
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R10_000.KN.U2.F0 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_10_000.csv" do
    field :id, "id"
    field :first_name, "first_name"
    field :last_name, "last_name"
    field :email, "email", unique: true
    field :gender, "gender"
    field :ip_address, "ip_address", unique: true
    field :date_of_birth, "date_of_birth"
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")
end

defmodule R10_000.KN.U0.F4 do
  @moduledoc false
  use Csv.Schema
  import Csv.Schema.Parser
  @start_time :os.system_time(:millisecond)

  schema "data/dataset_10_000.csv" do
    field :id, "id"
    field :first_name, "first_name", filter_by: true
    field :last_name, "last_name", filter_by: true
    field :email, "email"
    field :gender, "gender", filter_by: true
    field :ip_address, "ip_address"
    field :date_of_birth, "date_of_birth", filter_by: true
  end

  IO.puts("#{:os.system_time(:millisecond) - @start_time}")

  IO.puts("----------------------------------------------")
end
