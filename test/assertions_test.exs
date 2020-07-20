defmodule DoubleBypass.AssertionsTest do
  use ExUnit.Case
  use Plug.Test
  import Plug.Conn

  @path "/path"
  @query "query=query"
  @method "POST"
  @headers [{"content-type", "application/json"}, {"keep-alive", "timeout=5"}]
  @json_resp_body %{"body" => "body"}
  @string_resp_body "body"
  @status_code 204
  @resp_headers [{"location", "http://localhost"}]

  setup_all do
    body = @json_resp_body |> Jason.encode!()

    conn =
      conn(:post, @path <> "?query=query", body)
      |> put_req_header("content-type", "application/json")
      |> put_req_header("keep-alive", "timeout=5")

    %{conn: conn}
  end

  test "test path", %{conn: conn} do
    DoubleBypass.Assertions.run(conn, %{path: @path})
  end

  test "test query", %{conn: conn} do
    DoubleBypass.Assertions.run(conn, %{query: @query})
  end

  test "test method", %{conn: conn} do
    DoubleBypass.Assertions.run(conn, %{method: @method})
  end

  test "test headers", %{conn: conn} do
    DoubleBypass.Assertions.run(conn, %{headers: @headers})
  end

  test "test json body", %{conn: conn} do
    DoubleBypass.Assertions.run(conn, %{body: @json_resp_body})
  end

  test "test string body" do
    conn = conn(:post, "/", @string_resp_body)
    DoubleBypass.Assertions.run(conn, %{body: @string_resp_body})
  end

  test "test multiple params", %{conn: conn} do
    DoubleBypass.Assertions.run(conn, %{
      path: @path,
      query: @query,
      method: @method,
      headers: @headers,
      body: @json_resp_body
    })
  end

  test "test json response", %{conn: conn} do
    resp = DoubleBypass.Assertions.run(conn, %{response: @json_resp_body})
    assert resp.resp_body |> Jason.decode!() == @json_resp_body
  end

  test "test string response", %{conn: conn} do
    resp = DoubleBypass.Assertions.run(conn, %{response: @string_resp_body})
    assert resp.resp_body == @string_resp_body
  end

  test "test status code", %{conn: conn} do
    resp = DoubleBypass.Assertions.run(conn, %{status_code: @status_code})
    assert resp.status == @status_code
  end

  test "test response headers code", %{conn: conn} do
    [header] = @resp_headers
    resp = DoubleBypass.Assertions.run(conn, %{resp_headers: @resp_headers})
    assert Enum.member?(resp.resp_headers, header)
  end

  test "test status code and json response", %{conn: conn} do
    resp =
      DoubleBypass.Assertions.run(conn, %{
        response: @json_resp_body,
        status_code: @status_code
      })

    assert resp.status == @status_code
    assert resp.resp_body |> Jason.decode!() == @json_resp_body
  end
end
