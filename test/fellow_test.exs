defmodule FellowTest do
  use ExUnit.Case

  test "Get by unique field. When field value exists in csv returns a fellow" do
    assert Fellow.by_email("pscotteru@scribd.com").__struct__ == Fellow
  end

  test "Get by unique field. When field value doesn't exists in csv returns nil" do
    assert is_nil(Fellow.by_email("ajeje.brazorf@prima.it"))
  end

  test "Get by unique field. When called with nil, having a nil field in csv, returns nil" do
    assert is_nil(Fellow.by_email(nil))
  end

  test "Filter by field. When value matches returns array of Fellows" do
    assert "Male" |> Fellow.filter_by_gender() |> Enum.count() == 494
  end

  test "Filter by field. When value doesn't match return empty array" do
    assert Fellow.filter_by_first_name("Ajeje") == []
  end

  test "Get all returns all fellows" do
    assert Enum.count(Fellow.get_all()) == 1000
  end
end
