defmodule DoubleBypassTest do
  use ExUnit.Case

  @tags %{service_bypass: %{test: "params"}}
  @bypass_tags [service_bypass: "SERVICE_HOST"]

  test "setup_bypass?" do
    assert DoubleBypass.setup_bypass?(@tags, @bypass_tags)
    refute DoubleBypass.setup_bypass?(@tags, [service_two_bypass: "SERVICE_TWO_HOST"])
  end

  test "setup_bypass" do
    DoubleBypass.setup_bypass(@tags, @bypass_tags)

    HTTPoison.start
    HTTPoison.get! System.get_env("SERVICE_HOST")
  end
end
