defmodule ManTest do
  use ExUnit.Case

  # Now primary key is man_id
  test "Get by id. When id exists in csv returns a man" do
    assert Man.by_man_id(1).__struct__ == Man
  end

  test "Get by id. When id doesn't exists in csv returns nil" do
    assert is_nil(Man.by_man_id(0))
  end

  test "Get by unique field. When field value exists in csv returns a man" do
    assert Man.by_email("ahavick1b@discovery.com").__struct__ == Man
  end

  test "Get by unique field. When field value doesn't exists in csv returns nil" do
    assert is_nil(Man.by_email("ajeje.brazorf@prima.it"))
  end

  test "Filter by field. When value matches returns array of men" do
    assert "Male" |> Man.filter_by_gender() |> Enum.count() == 26
  end

  test "Filter by field. When value doesn't match return empty array" do
    assert "Ajeje" |> Man.filter_by_first_name() == []
  end

  test "Get all returns all men" do
    assert Man.get_all() |> Enum.count() == 50
  end
end
