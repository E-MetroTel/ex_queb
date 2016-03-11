defmodule ExQueb do
  import Ecto.Query
  require Logger

  def filter(query, params) do
    q = params[Application.get_env(:ex_queb, :filter_param, :q)] 
    if q do
      filters = Map.to_list(q) |> Enum.filter(&(not elem(&1,1) in ["", nil])) |> Enum.map(&({Atom.to_string(elem(&1, 0)), elem(&1, 1)}))
      string_filters(filters)
      |> integer_filters(filters)
      |> date_filters(filters)
      |> build_filter_query(query)
    else
      query
    end
  end

  defp string_filters(filters) do
    Enum.filter_map(filters, &(String.match?(elem(&1,0), ~r/_contains$/)), &({String.replace(elem(&1, 0), "_contains", ""), elem(&1, 1)}))
    |> Enum.reduce("", fn({k,v}, acc) -> acc <> ~s| and like(c.#{k}, "%#{v}%")| end)
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
    cond_str = condition_to_string condition
    Enum.filter_map(filters, &(String.match?(elem(&1,0), ~r/_#{condition}$/)), &({String.replace(elem(&1, 0), "_#{condition}", ""), elem(&1, 1)}))
    |> Enum.reduce(builder, fn({k,v}, acc) -> acc <> ~s| and c.#{k} #{cond_str} #{v}| end)
  end

  defp build_date_filters(builder, filters, condition) do
    cond_str = condition_to_string condition

    Enum.filter_map(filters, &(String.match?(elem(&1,0), ~r/_#{condition}$/)), &({String.replace(elem(&1, 0), "_#{condition}", ""), elem(&1, 1)}))
    |> Enum.reduce(builder, fn({k,v}, acc) -> 
      acc <> ~s| and fragment("? #{cond_str} ?", c.#{k}, "#{cast_date_time(v)}")| 
    end)
  end

  defp condition_to_string(condition) do
    case condition do
      :gte -> ">="
      :lte -> "<="
      :gt -> ">"
      :eq -> "=="
      :lt -> "<"
    end
  end

  defp cast_date_time(value) do
    {:ok, date} = Ecto.Date.cast(value)
    date
    |> Ecto.DateTime.from_date
    |> Ecto.DateTime.to_string
  end

  defp build_filter_query("", query), do: query
  defp build_filter_query(builder, query) do
    builder = String.replace(builder, ~r/^ and /, "")
    "where(query, [c], #{builder})"
    |> Code.eval_string([query: query], __ENV__)
    |> elem(0)
  end

  def build_order_bys(query, opts, :index, params) do
    case Keyword.get(params, :order, nil) do
      nil -> build_default_order_bys(query, opts, :index, params)
      order -> 
        case get_sort_order(order) do
          nil -> build_default_order_bys(query, opts, :index, params)
          {name, sort_order} -> 
            name_atom = String.to_atom name
            if sort_order == "desc" do
              order_by query, [c], [desc: field(c, ^name_atom)]
            else
              order_by query, [c], [asc: field(c, ^name_atom)]
            end

        end
    end
  end
  def build_order_bys(query, _, _, _), do: query

  defp build_default_order_bys(query, _opts, :index, _params) do
    case query.order_bys do
      [] -> order_by(query, [c], [desc: c.id])
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
end
