defmodule ManTest do
  use ExUnit.Case

  # Now primary key is man_id
  test "Get by id. When id exists in csv returns a man" do
    assert Man.Asc.by_man_id(1).__struct__ == Man.Asc
    assert Man.Desc.by_man_id(1).__struct__ == Man.Desc
  end

  test "Get by id. When id doesn't exists in csv returns nil" do
    assert is_nil(Man.Asc.by_man_id(0))
    assert is_nil(Man.Desc.by_man_id(0))
  end

  test "Get by unique field. When field value exists in csv returns a man" do
    assert Man.Asc.by_email("ahavick1b@discovery.com").__struct__ == Man.Asc
    assert Man.Desc.by_email("ahavick1b@discovery.com").__struct__ == Man.Desc
  end

  test "Get by unique field. When field value doesn't exists in csv returns nil" do
    assert is_nil(Man.Asc.by_email("ajeje.brazorf@prima.it"))
    assert is_nil(Man.Desc.by_email("ajeje.brazorf@prima.it"))
  end

  test "Filter by field. When value matches returns array of men. The sort depends" do
    assert "Male" |> Man.Asc.filter_by_gender() |> Enum.count() == 26
    assert "Male" |> Man.Desc.filter_by_gender() |> Enum.count() == 26

    assert "Male" |> Man.Asc.filter_by_gender() |> Enum.map(& &1.man_id) ==
             "Male" |> Man.Asc.filter_by_gender() |> Enum.sort_by(& &1.first_name) |> Enum.map(& &1.man_id)

    assert "Male" |> Man.Asc.filter_by_gender() |> Enum.map(& &1.man_id) ==
             "Male" |> Man.Desc.filter_by_gender() |> Enum.map(& &1.man_id) |> Enum.reverse()
  end

  test "Filter by field. When value doesn't match return empty array" do
    assert "Ajeje" |> Man.Asc.filter_by_first_name() == []
    assert "Ajeje" |> Man.Desc.filter_by_first_name() == []
  end

  test "Get all returns all men" do
    assert Man.Asc.get_all() |> Enum.count() == 50
    assert Man.Desc.get_all() |> Enum.count() == 50

    assert Man.Asc.get_all(:materialized) |> Enum.map(& &1.man_id) ==
             :materialized |> Man.Desc.get_all() |> Enum.reverse() |> Enum.map(& &1.man_id)
  end
end
