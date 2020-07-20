# Double Bypass

Double Bypass is a simple wrapper for Bypass.  Double Bypass makes configuring and using Bypass simple.  It takes advantage of ExUnit tags to remove redundant Bypass expectation code, and allow you to test your external requests in a self documenting manner.

## Installation

Add Double Bypass to your list of dependencies in mix.exs:

```elixir
def deps do
  [{:double_bypass, "~> 0.0.5", only: :test}]
end
```

## Usage

In your test setup file (eg: `test/support/conn_case.exs`) define the services to be bypassed by local bypass services.

```elixir
  @bypass_tags [
    service_bypass: %{getter: fn -> System.get_env("SERVICE_HOST") end, setter: & System.put_env("SERVICE_HOST", &1)},
    service_two_bypass: %{key: "SERVICE_TWO_HOST"},
  ]
 ```

The keys are the ExUnit tag (to be used when initializing the bypass server for specific tests), and the values are setter and getter functions used to update the configuration to point to the local Bypass server. Alternatively, you can define a global getter and setter function passed as options to the DoubleBypass.setup_bypass/3 and specify a key to be passed as the first argument to the global setter and getter.

In your test setup, setup bypass:

```elixir
   defp setup_test(tags) do
    {:ok,
      DoubleBypass.setup_bypass(tags, @bypass_tags, %{setter: &System.put_env/2, getter: &System.get_env/1})
      |> Map.put(:conn, Phoenix.ConnTest.build_conn())
    }
   end
```

To use Double Bypass in a test case, tag the test with the bypass tag (defined in the test setup) of the service you want to be mocked. The presence of the tag initializes the Bypass server for that service for that one test. If the tag is not present, then the service will not be mocked.

The tag values are the assertions to be made for that test. Double Bypass supports assertions on `headers`, `path`, `query`, `method` and `body` for the request made to the local Bypass server. The presence of any of these values will trigger Double Bypass to assert on the specified value compared to that of the conn object received by the Bypass server.

`response`, `status_code` and `resp_headers` can be defined as well.  The presence of these values set the response coming from the Bypass server. By default Double Bypass will return status: 200, response: "".

```elixir
@tag service_bypass: %{
    headers: [{"content-type", "application/json"}],
    path: "/path/one",
    method: "POST",
    body: %{request: "body"},
    response: %{response: "body"}
    status_code: 201,
    resp_headers: [{"content-type", "application/json"}]
  }
  test "POST /path", %{conn: conn} do
    resp = post(conn, "/path", %{request: "body"})
    assert resp.status == 201
    assert resp.resp_body == %{response: "body"}
  end
end
```

Double Bypass supports setting up multiple Bypass servers for a single test.  Simply include all bypass tags for the services to be mocked in the ExUnit tags of the test.

```elixir
@tag service_bypass: %{
    headers: [{"content-type", "application/json"}],
    path: "/path/one",
    method: "POST",
    body: %{request: "body"},
    response: %{response: "body"}
    status_code: 201,
    resp_headers: [{"content-type", "application/json"}]
  }, service_two_bypass: %{
    path: "/path/two",
    method: "GET",
    response: %{response: "body two"}
    status_code: 200
  }
  test "POST /path", %{conn: conn} do
    resp = post(conn, "/path", %{request: "body"})
    assert resp.status == 201
    assert resp.resp_body == %{response: "body"}
  end
end
```

Double Bypass returns the Bypass object, so it can be used when performing more complicated Bypass operations.

```elixir
@tag service_bypass: %{
    headers: [{"content-type", "application/json"}],
    path: "/path/one",
    method: "POST",
    body: %{request: "body"},
    response: %{response: "body"}
    status_code: 201,
    resp_headers: [{"content-type", "application/json"}]
  }, service_two_bypass: %{
    path: "/path/two",
    method: "GET",
    response: %{response: "body two"}
    status_code: 200
  }
  test "POST /path", %{conn: conn, service_bypass: service_bypass, service_two_bypass: service_two_bypass} do
    Bypass.expect service_bypass, fn conn ->
      Plug.Conn.halt(conn)
    end
    Bypass.expect service_two_bypass, fn conn ->
      Plug.Conn.halt(conn)
    end
  end
end
```
