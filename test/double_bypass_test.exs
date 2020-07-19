defmodule DoubleBypass.Config do
  @moduledoc false

  @config %{
    service_two_host: "www.test-url.com",
    service_three_host: "www.test-url.com"
  }

  use Agent

  def start_link do
    Agent.start_link(fn -> @config end, name: __MODULE__)
  end

  def put(config, value) when is_atom(config) do
    Agent.update(__MODULE__, & Map.put(&1, config, value))
  end

  def get(key) when is_atom(key) do
    get([key])
  end

  def get(keys) when is_list(keys) do
    get_in(Agent.get(__MODULE__, & &1), keys)
  end

  def stop do
    Agent.stop(__MODULE__)
  end
end

defmodule DoubleBypassTest do
  use ExUnit.Case

  @tags %{
    service_one_bypass: %{test: "params"}, 
    service_two_bypass: %{test: "params"}, 
    service_three_bypass: %{test: "params"}
  }

  defp bypass_tags do
    [
      service_one_bypass: "SERVICE_HOST", 
      service_two_bypass: %{
        setter: & DoubleBypass.Config.put(:service_two_host, &1), 
        getter: fn -> DoubleBypass.Config.get(:service_two_host) end
      },
      service_three_bypass: %{key: :service_three_host}
    ]
  end

  setup_all do
    {:ok, _pid} = DoubleBypass.Config.start_link()
    :ok
  end

  test "setup_bypass?" do
    assert DoubleBypass.setup_bypass?(@tags, bypass_tags())
    refute DoubleBypass.setup_bypass?(@tags, [service_four_bypass: "SERVICE_FOUR_HOST"])
  end

  test "setup_bypass" do
    DoubleBypass.setup_bypass(@tags, bypass_tags(), %{setter: &DoubleBypass.Config.put/2, getter: &DoubleBypass.Config.get/1})

    HTTPoison.start
    HTTPoison.get! System.get_env("SERVICE_HOST")
    HTTPoison.get! DoubleBypass.Config.get(:service_two_host)
    HTTPoison.get! DoubleBypass.Config.get(:service_three_host)
  end
end
