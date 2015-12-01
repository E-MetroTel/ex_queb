defmodule ExQueb do
  import Ecto.Query

  def filter(query, params) do

    q = params[Application.get_env(:ex_queb, :filter_param, :q)] #Keyword.get(params, :q)
    if q do
    #   filters = Map.to_list(q) |> Enum.filter(&(not elem(&1,1) in ["", nil])) |> Enum.map(&({Atom.to_string(elem(&1, 0)), elem(&1, 1)}))
    #   string_filters(filters)
    #   |> integer_filters(filters)
    #   |> date_filters(filters)
    #   |> build_filter_query(query)
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
    |> Enum.reduce(builder, fn({k,v}, acc) -> acc <> ~s| and fragment("? #{cond_str} '?'", c.#{k}, \"#{cast_date_time(v)}\")| end)
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
    {:ok, dt} = Ecto.Date.cast(value)
    Ecto.Date.to_string dt
  end

  defp build_filter_query("", query), do: query
  defp build_filter_query(builder, query) do
    builder = String.replace(builder, ~r/^ and /, "")
    "where(query, [c], #{builder})"
    |> Code.eval_string([query: query], __ENV__)
    |> elem(0)
  end
end
