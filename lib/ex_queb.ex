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
    q = params[Application.get_env(:ex_queb, :filter_param, :q)]
    if q do
      filters = Map.to_list(q)
      |> Enum.filter(&(not elem(&1,1) in ["", nil]))
      |> Enum.map(&({Atom.to_string(elem(&1, 0)), elem(&1, 1)}))

      query
      |> ExQueb.StringFilters.string_filters(filters)
      |> integer_filters(filters)
      |> date_filters(filters)
    else
      query
    end
  end

  defp integer_filters(builder, filters) do
    builder
    |> build_integer_filters(filters, :eq)
    |> build_integer_filters(filters, :lt)
    |> build_integer_filters(filters, :gt)
  end

  defp date_filters(builder, filters) do
    builder
    |> build_date_filters(filters, :gte)
    |> build_date_filters(filters, :lte)
  end

  defp build_integer_filters(builder, filters, condition) do
    Enum.filter_map(filters, &(String.match?(elem(&1,0), ~r/_#{condition}$/)), &({String.replace(elem(&1, 0), "_#{condition}", ""), elem(&1, 1)}))
    |> Enum.reduce(builder, fn({k,v}, acc) ->
      _build_integer_filter(acc, String.to_atom(k), v, condition)
    end)
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

  defp build_date_filters(builder, filters, condition) do
    Enum.filter_map(filters, &(String.match?(elem(&1,0), ~r/_#{condition}$/)), &({String.replace(elem(&1, 0), "_#{condition}", ""), elem(&1, 1)}))
    |> Enum.reduce(builder, fn({k,v}, acc) ->
      _build_date_filter(acc, String.to_atom(k), cast_date_time(v), condition)
    end)
  end

  defp _build_date_filter(query, fld, value, :gte) do
    where(query, [q], fragment("? >= ?", field(q, ^fld), type(^value, Ecto.DateTime)))
  end
  defp _build_date_filter(query, fld, value, :lte) do
    where(query, [q], fragment("? <= ?", field(q, ^fld), type(^value, Ecto.DateTime)))
  end

  defp cast_date_time(value) do
    {:ok, date} = Ecto.Date.cast(value)
    date
    |> Ecto.DateTime.from_date
    |> Ecto.DateTime.to_string
  end

  def build_order_bys(query, opts, :index, params) do
    case Keyword.get(params, :order, nil) do
      nil ->
        build_default_order_bys(query, opts, :index, params)
      order ->
        case get_sort_order(order) do
          nil ->
            build_default_order_bys(query, opts, :index, params)
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

  defp build_default_order_bys(query, opts, :index, _params) do
    case query.order_bys do
      [] ->
        index_opts = Map.get(opts, :index, []) |> Enum.into(%{})
        {order, primary_key} = get_default_order_by_field(query, index_opts)
        order_by(query, [c], [{^order, field(c, ^primary_key)}])
      _ -> query
    end
  end

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
