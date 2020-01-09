defmodule ExQueb do
  @moduledoc """
  Build Ecto filter Queries.
  """
  import Ecto.Query

  @doc """
  Create the filter

  Uses the :q query parameter to build the filter.
  """
  def filter(query, params) do
    filters =
      params[Application.get_env(:ex_queb, :filter_param, :q)]
      |> params_to_filters()
      if filters do
      query
      |> ExQueb.StringFilters.string_filters(filters)
      |> integer_filters(filters)
      |> date_filters(filters)
      |> boolean_filters(filters)
    else
      query
    end
  end

  def params_to_filters(nil), do: nil
  def params_to_filters(q) do
    Map.to_list(q)
    |> Enum.filter(fn {_k, v} -> v not in ["", nil, []] end)
    |> Enum.map(&({Atom.to_string(elem(&1, 0)), elem(&1, 1)}))
  end

  defp integer_filters(builder, filters) do
    builder
    |> build_integer_filters(filters, :eq)
    |> build_integer_filters(filters, :lt)
    |> build_integer_filters(filters, :gt)
    |> build_integer_filters(filters, :in)
  end

  defp date_filters(builder, filters) do
    builder
    |> build_date_filters(filters, :gte)
    |> build_date_filters(filters, :lte)
  end

  defp boolean_filters(builder, filters) do
    builder
    |> build_boolean_filters(filters, :is)
  end

  defp build_integer_filters(builder, filters, condition) do
    map_filters(builder, filters, condition, &_build_integer_filter/4)
  end

  defp _build_integer_filter(query, fld, value, :eq) do
    where(query, [q], field(q, ^fld) == ^value)
  end
  defp _build_integer_filter(query, fld, value, :lt) do
    where(query, [q], field(q, ^fld) < ^value)
  end
  defp _build_integer_filter(query, fld, value, :gte) do
    where(query, [q], field(q, ^fld) >= ^value)
  end
  defp _build_integer_filter(query, fld, value, :lte) do
    where(query, [q], field(q, ^fld) <= ^value)
  end
  defp _build_integer_filter(query, fld, value, :gt) do
    where(query, [q], field(q, ^fld) > ^value)
  end
  defp _build_integer_filter(query, fld, value, :in) do
    where(query, [q], field(q, ^fld) in ^value)
  end

  defp build_date_filters(builder, filters, condition) do
    map_filters(builder, filters, condition, &_build_date_filter/4, &cast_date_time/1)
  end

  defp _build_date_filter(query, fld, value, :gte) do
    where(query, [q], fragment("? >= ?", field(q, ^fld), type(^value, Ecto.DateTime)))
  end
  defp _build_date_filter(query, fld, value, :lte) do
    where(query, [q], fragment("? <= ?", field(q, ^fld), type(^value, Ecto.DateTime)))
  end

  defp build_boolean_filters(builder, filters, condition) do
    map_filters(builder, filters, condition, &_build_boolean_filter/4)
  end

  defp _build_boolean_filter(query, fld, "not_null", :is) do
    where(query, [q], not is_nil(field(q, ^fld)))
  end

  defp _build_boolean_filter(query, fld, "null", :is) do
    where(query, [q], is_nil(field(q, ^fld)))
  end

  defp cast_date_time(value) do
    {:ok, date} = Ecto.Date.cast(value)
    date
    |> Ecto.DateTime.from_date
    |> Ecto.DateTime.to_string
  end

  defp map_filters(builder, filters, condition, reduce_fn, map_value_fn\\fn v -> v end) do
    filters
    |> Enum.filter(& String.match?(elem(&1,0), ~r/_#{condition}$/))
    |> Enum.map(& {String.replace(elem(&1, 0), "_#{condition}", ""), elem(&1, 1)})
    |> Enum.reduce(builder, fn({k,v}, acc) ->
      reduce_fn.(acc, String.to_atom(k), map_value_fn.(v), condition)
    end)
  end

  @doc """
  Build order for a given query.
  """
  def build_order_bys(query, opts, action, params) when action in ~w(index csv)a do
    case Keyword.get(params, :order, nil) do
      nil ->
        build_default_order_bys(query, opts, action, params)
      order ->
        case get_sort_order(order) do
          nil ->
            build_default_order_bys(query, opts, action, params)
          {name, sort_order} ->
            name_atom = String.to_existing_atom name
            if sort_order == "desc" do
              order_by query, [c], [desc: field(c, ^name_atom)]
            else
              order_by query, [c], [asc: field(c, ^name_atom)]
            end

        end
    end
  end
  def build_order_bys(query, _, _, _), do: query

  defp build_default_order_bys(query, opts, action, _params) when action in ~w(index csv)a do
    case query.order_bys do
      [] ->
        index_opts = Map.get(opts, action, []) |> Enum.into(%{})
        {order, primary_key} = get_default_order_by_field(query, index_opts)
        order_by(query, [c], [{^order, field(c, ^primary_key)}])
      _ -> query
    end
  end
  defp build_default_order_bys(query, _opts, _action, _params), do: query

  @doc """
  Get the sort order for a params entry.
  """
  def get_sort_order(nil), do: nil
  def get_sort_order(order) do
    case Regex.scan ~r/(.+)_(desc|asc)$/, order do
      [] -> nil
      [[_, name, sort_order]] -> {name, sort_order}
    end
  end

  defp get_default_order_by_field(_query, %{default_sort: [{order, field}]}) do
    {order, field}
  end
  defp get_default_order_by_field(query, %{default_sort_order: order}) do
    {order, get_default_order_by_field(query)}
  end
  defp get_default_order_by_field(_query, %{default_sort_field: field}) do
    {:desc, field}
  end
  defp get_default_order_by_field(query, _) do
    {:desc, get_default_order_by_field(query)}
  end

  defp get_default_order_by_field(query) do
    case query do
      %{from: {_, mod}} ->
        case mod.__schema__(:primary_key) do
          [name |_] -> name
          _ -> mod.__schema__(:fields) |> List.first
        end
      _ -> :id
    end
  end
end
