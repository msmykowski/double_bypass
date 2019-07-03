defmodule DoubleBypass.Assertions do
  @moduledoc """
  Responsible for test assertion logic.
  """
  use ExUnit.CaseTemplate

  def run(conn, params) do
    Enum.each(params, &assert_on(conn, &1))
    send_resp(conn, params)
  end

  defp assert_on(conn, {:path, path}), do: assert(conn.request_path == path)
  defp assert_on(conn, {:query, query}), do: assert(conn.query_string == query)
  defp assert_on(conn, {:method, method}), do: assert(conn.method == method)
  defp assert_on(conn, {:headers, headers}), do: assert_on(conn, {:req_headers, headers})

  defp assert_on(conn, {:req_headers, req_headers}) do
    conn_headers = conn.req_headers |> Enum.into(%{})

    Enum.map(req_headers, fn {k, v} ->
      assert conn_headers[k] == v
    end)
  end

  defp assert_on(conn, {:body, body}) when is_bitstring(body) do
    assert conn
           |> Plug.Conn.read_body()
           |> elem(1) == body
  end

  defp assert_on(conn, {:body, body}) do
    assert conn
           |> Plug.Conn.read_body()
           |> elem(1)
           |> Poison.decode!() == body
  end

  defp assert_on(_conn, _), do: :noop

  defp send_resp(conn, %{resp_headers: resp_headers} = params) do
    params = Map.delete(params, :resp_headers)

    conn
    |> put_resp_headers(resp_headers)
    |> send_resp(params)
  end

  defp send_resp(conn, params) do
    case params do
      %{response: response, status_code: status_code} when is_bitstring(response) ->
        Plug.Conn.resp(conn, status_code, response)

      %{response: response, status_code: status_code} ->
        Plug.Conn.resp(conn, status_code, Poison.encode!(response))

      %{status_code: status_code} ->
        Plug.Conn.resp(conn, status_code, "")

      %{response: response} when is_bitstring(response) ->
        Plug.Conn.resp(conn, 200, response)

      %{response: response} ->
        Plug.Conn.resp(conn, 200, Poison.encode!(response))

      _ ->
        Plug.Conn.resp(conn, 200, "")
    end
  end

  defp put_resp_headers(conn, resp_headers) do
    Enum.reduce(resp_headers, conn, fn {key, value}, conn ->
      conn
      |> Plug.Conn.put_resp_header(key, value)
    end)
  end
end
