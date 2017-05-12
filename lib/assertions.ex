defmodule DoubleBypass.Assertions do
  use ExUnit.CaseTemplate

  def run(conn, opts) do
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
