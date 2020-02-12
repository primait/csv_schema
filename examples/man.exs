defmodule Man do
  @moduledoc false

  defmodule Asc do
    @moduledoc """
    In Man example i use csv's primary key, a different separator and index for fields
    """
    use Csv.Schema, headers: false, separator: ?;

    import Csv.Schema.Parser

    schema "data/dataset_50_no_header_semicolon.csv" do
      field :man_id, 1, key: true, parser: &integer!/1
      field :first_name, 2, filter_by: true, sort: :asc
      field :last_name, 3
      field :email, 4, unique: true
      field :gender, 5, filter_by: true
      field :ip_address, 6
      field :date_of_birth, 7, parser: &date!(&1, "{0M}/{0D}/{0YYYY}")
    end
  end

  defmodule Desc do
    @moduledoc """
    In Man example i use csv's primary key, a different separator and index for fields
    """
    use Csv.Schema, headers: false, separator: ?;

    import Csv.Schema.Parser

    schema "data/dataset_50_no_header_semicolon.csv" do
      field :man_id, 1, key: true, parser: &integer!/1
      field :first_name, 2, filter_by: true, sort: :desc
      field :last_name, 3
      field :email, 4, unique: true
      field :gender, 5, filter_by: true
      field :ip_address, 6
      field :date_of_birth, 7, parser: &date!(&1, "{0M}/{0D}/{0YYYY}")
    end
  end
end
