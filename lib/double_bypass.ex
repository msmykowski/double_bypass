defmodule DoubleBypass do
  use ExUnit.CaseTemplate

  def setup_bypass?(tags, bypass_tags) do
    Enum.any?(bypass_tags, fn({bypass_tag, _host}) ->
      bypass_tag in Map.keys(tags)
    end)
  end

  def setup_bypass(tags, bypass_tags), do: init(%{}, tags, bypass_tags)

  defp init(acc, _tags, []), do: acc
  defp init(acc, tags, _bypass_tags) when tags == %{}, do: acc
  defp init(acc, tags, [{bypass_tag, host} | t]) do
    case tags[bypass_tag] do
      nil -> init(acc, tags, t)
      map ->
        acc
        |> Map.put(bypass_tag, init_server(map, host))
        |> init(tags, t)
    end
  end

  defp init_server(opts, host) do
    bypass = Bypass.open
    url = System.get_env(host)
    System.put_env(host ,"http://localhost:#{bypass.port}")
    Bypass.expect(bypass, &handle_assertions(&1, opts))
    onexit(host, url)
    bypass
  end

  defp onexit(env, nil) do
    on_exit fn ->
      System.put_env(env, "")
      :ok
    end
  end
  defp onexit(env, url) do
    on_exit fn ->
      System.put_env(env, url)
      :ok
    end
  end

  defp handle_assertions(conn, opts) do
    assert_headers(conn, opts)
    assert_path(conn, opts)
    assert_query(conn, opts)
    assert_method(conn, opts)
    assert_body(conn, opts)
    response(conn, opts)
  end

  defp assert_path(conn, %{path: path}), do: assert conn.request_path == path
  defp assert_path(_conn, _params), do: :noop

  defp assert_query(conn, %{query: query}), do: assert conn.query_string == query
  defp assert_query(_conn, _params), do: :noop

  defp assert_method(conn, %{method: method}), do: assert conn.method == method
  defp assert_method(_conn, _params), do: :noop

  defp assert_headers(conn, %{headers: headers}) do
    conn_headers = conn.req_headers |> Enum.into(%{})
    Enum.map(headers, fn({k, v}) ->
      assert conn_headers[k] == v
    end)
  end
  defp assert_headers(_conn, _params), do: :noop

  defp assert_body(conn, %{body: body}) do
    assert conn
      |> Plug.Conn.read_body
      |> elem(1)
      |> Poison.decode! == body
  end
  defp assert_body(_conn, _params), do: :noop

  defp response(conn, %{response: response, status_code: status_code}) when is_bitstring(response) do
    Plug.Conn.resp(conn, status_code, response)
  end
  defp response(conn, %{response: response, status_code: status_code}) do
    Plug.Conn.resp(conn, status_code, Poison.encode!(response))
  end
  defp response(conn, %{status_code: status_code}) do
    Plug.Conn.resp(conn, status_code, "")
  end
  defp response(conn, %{response: response}) when is_bitstring(response) do
    Plug.Conn.resp(conn, 200, response)
  end
  defp response(conn, %{response: response}) do
    Plug.Conn.resp(conn, 200, Poison.encode!(response))
  end
  defp response(conn, _params) do
    Plug.Conn.resp(conn, 200, "")
  end
end
