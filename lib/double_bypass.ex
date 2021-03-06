defmodule DoubleBypass do
  @moduledoc """
  Responsible for initializing and configuring the Bypass servers.
  """
  use ExUnit.CaseTemplate

  def setup_bypass?(tags, bypass_tags) do
    Enum.any?(bypass_tags, fn {bypass_tag, _host} ->
      bypass_tag in Map.keys(tags)
    end)
  end

  def setup_bypass(tags, bypass_tags, options \\ %{}) do
    {:ok, _} = Application.ensure_all_started(:bypass)
    init(%{}, tags, bypass_tags, options)
  end

  defp init(acc, _tags, [], _options), do: acc

  defp init(acc, tags, _bypass_tags, _options) when tags == %{}, do: acc

  defp init(acc, tags, [{bypass_tag, environment_variable} | t], options)
       when is_bitstring(environment_variable) do
    case tags[bypass_tag] do
      nil ->
        init(acc, tags, t, options)

      map ->
        acc
        |> Map.put(
          bypass_tag,
          init_server(map, %{
            getter: fn -> System.get_env(environment_variable) end,
            setter: &System.put_env(environment_variable, &1)
          })
        )
        |> init(tags, t, options)
    end
  end

  defp init(acc, tags, [{bypass_tag, host_opts} | t], options) do
    case tags[bypass_tag] do
      nil ->
        init(acc, tags, t, options)

      map ->
        getter = getter(host_opts, options)
        setter = setter(host_opts, options)

        opts =
          host_opts
          |> Map.put(:getter, getter)
          |> Map.put(:setter, setter)

        acc
        |> Map.put(bypass_tag, init_server(map, opts))
        |> init(tags, t, options)
    end
  end

  defp init_server(opts, %{getter: getter, setter: setter}) do
    bypass = Bypass.open()
    original_config = getter.()
    setter.("http://localhost:#{bypass.port}")

    if map_size(opts) > 0 do
      Bypass.expect(bypass, &DoubleBypass.Assertions.run(&1, opts))
    end

    onexit(setter, original_config)
    bypass
  end

  defp onexit(setter, original_config) do
    on_exit(fn ->
      if original_config, do: setter.(original_config)
      :ok
    end)
  end

  defp getter(%{getter: getter}, _options), do: getter

  defp getter(%{key: key}, %{getter: getter}), do: fn -> getter.(key) end

  defp setter(%{setter: setter}, _options), do: setter

  defp setter(%{key: key}, %{setter: setter}), do: fn bypass_url -> setter.(key, bypass_url) end
end
