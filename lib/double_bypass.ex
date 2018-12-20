defmodule DoubleBypass do
  @moduledoc """
  Responsible for initializing and configuring the Bypass servers.
  """
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
    url = System.get_env(host) || ""
    System.put_env(host, "http://localhost:#{bypass.port}")
    Bypass.expect(bypass, &DoubleBypass.Assertions.run(&1, opts))
    onexit(host, url)
    bypass
  end

  defp onexit(env, url) do
    on_exit fn ->
      System.put_env(env, url)
      :ok
    end
  end
end
