defmodule Test.Model do
  use Ecto.Schema
  schema "models" do
    field :name, :string
    field :age, :integer

    timestamps()
  end
end

defmodule Test.Noid do
  use Ecto.Schema
  @primary_key {:name, :string, []}
  schema "noids" do
    field :description, :string

    timestamps()
  end
end

defmodule Test.Noprimary do
  use Ecto.Schema
  @primary_key false
  schema "noprimarys" do
    field :index, :integer
    field :name, :string
    field :description, :string

    timestamps()
  end
end

defmodule ExQuebTest do
  use ExUnit.Case
  doctest ExQueb
  import Ecto.Query
  require Logger

  test "no filter" do
    assert_equal ExQueb.filter(Test.Model, %{}), Test.Model
  end

  # %{blog_id_eq: "1", inserted_at_gte: nil, inserted_at_lte: nil, name_contains: nil, updated_at_gte: nil, updated_at_lte: nil}
  test "filters single field" do
    expected = where(Test.Model, [m], like(fragment("LOWER(?)", m.name), ^"%test%"))
    assert_equal ExQueb.filter(Test.Model, %{q: %{name_contains: "Test"}}), expected
  end

  test "filters can be strings" do
    expected = where(Test.Model, [m], like(fragment("LOWER(?)", m.name), ^"%test%"))
    params =  %{q: %{"name_contains" => "Test"}}
    assert_equal ExQueb.filter(Test.Model,params), expected
  end

  test "handles different default primary key" do
    query = from n in Test.Noid, preload: []
    expected = from n in Test.Noid, order_by: [desc: n.name]
    assert_equal ExQueb.build_order_bys(query, %{all: [preload: []]}, :index, [resource: "noids"]), expected
  end

  test "handles no primary key" do
    expected = from n in Test.Noprimary, order_by: [desc: n.index]
    query = from n in Test.Noprimary, preload: []
    opts = %{all: [preload: []]}
    assert_equal ExQueb.build_order_bys(query, opts, :index, [resource: "noprimarys"]), expected
  end

  test "handles default sort defined in opts" do
    expected = from n in Test.Noprimary, order_by: [asc: n.name]
    query = from n in Test.Noprimary, preload: []
    opts = %{all: [preload: []], index: [default_sort: [asc: :name]]}
    assert_equal ExQueb.build_order_bys(query, opts, :index, [resource: "noprimarys"]), expected
  end

  test "handles default_sort_order only for primary key id" do
    opts = %{all: [preload: []], index: [default_sort_order: :asc]}
    query = from n in Test.Model, preload: []
    expected = from n in Test.Model, order_by: [asc: n.id]
    assert_equal ExQueb.build_order_bys(query, opts, :index, [resource: "models"]), expected
  end

  test "handles default_sort_field only for no primary key" do
    opts = %{all: [preload: []], index: [default_sort_field: :name]}
    query = from n in Test.Noprimary, preload: []
    expected = from n in Test.Noprimary, order_by: [desc: n.name]
    assert_equal ExQueb.build_order_bys(query, opts, :index, [resource: "noprimarys"]), expected
  end

  test "string filter contains" do
    expected = where(Test.Model, [m], like(fragment("LOWER(?)", m.name), ^"%test%"))
    assert_equal ExQueb.filter(Test.Model, %{q: %{name_contains: "Test"}}), expected
  end

  test "string filter begins with" do
    expected = where(Test.Model, [m], like(fragment("LOWER(?)", m.name), ^"test%"))
    assert_equal ExQueb.filter(Test.Model, %{q: %{name_begins_with: "Test"}}), expected
  end

  test "string filter ends with" do
    expected = where(Test.Model, [m], like(fragment("LOWER(?)", m.name), ^"%test"))
    assert_equal ExQueb.filter(Test.Model, %{q: %{name_ends_with: "Test"}}), expected
  end

  test "string filter equals" do
    expected = where(Test.Model, [m], fragment("LOWER(?)", m.name) == fragment("LOWER(?)", ^"Test"))
    assert_equal ExQueb.filter(Test.Model, %{q: %{name_equals: "Test"}}), expected
  end

  def assert_equal(a, b) do
    assert inspect(a) == inspect(b)
  end
end
