defmodule Thonk.Commands.Basic do
  @moduledoc false
  use Alchemy.Cogs
  alias Thonk.Utils
  alias Alchemy.{Client, Voice}
  require Logger
  require Alchemy.Embed, as: Embed

  @yellow 0xfac84b

  Cogs.def help do
    commands = Cogs.all_commands()
    |> Map.keys()
    |> Enum.join("\n")

    %Embed{color: @yellow, title: "All available commands", description: commands}
    |> Embed.send()
  end

  @doc """
  Information about the bot.
  """
  Cogs.def info do
    {:ok, app_version} = :application.get_key(:thonk, :vsn)
    {:ok, lib_version} = :application.get_key(:alchemy, :vsn)
    {:ok, guilds} = Client.get_current_guilds()

    infos = [
      {"Prefix", Application.get_env(:thonk, :prefix)},
      {"Version", "#{app_version}"},
      {"Elixir Version", System.version()},
      {"Library", "[Alchemy #{lib_version}](https://github.com/cronokirby/alchemy)"},
      {"Owner", "[appositum#7545](https://github.com/appositum)"},
      {"Guilds", "#{length(guilds)}"},
      {"Processes", "#{length :erlang.processes()}"},
      {"Memory Usage", "#{div :erlang.memory(:total), 1_000_000} MB"}
    ]

    Enum.reduce(infos, %Embed{color: @yellow, title: "Thonk"}, fn {name, value}, embed ->
      Embed.field(embed, name, value, inline: true)
    end)
    |> Embed.thumbnail("http://i.imgur.com/6YToyEF.png")
    |> Embed.url("https://github.com/appositum/thonk")
    |> Embed.footer(text: "Uptime: #{Utils.uptime()}")
    |> Embed.send()
  end

  Cogs.def xkcd do
    Cogs.say("https://xkcd.com/#{Enum.random(1..1964)}")
  end

  Cogs.set_parser(:roll, &List.wrap/1)
  Cogs.def roll(times) do
    times =
      case Integer.parse(times) do
        {n, _} -> n
        :error -> 1
      end

    cond do
      times == 1 ->
        Cogs.say(":game_die: You rolled **#{Enum.random(1..6)}**!")
      true ->
        numbers = Stream.repeatedly(fn -> Enum.random(1..6) end)
        |> Enum.take(times)
        |> Enum.join(", ")

        ":game_die: You rolled **#{times}** times!\n**#{numbers}**"
        |> Utils.message_exceed()
        |> Cogs.say()
    end
  end

  @doc """
  Plays a gemidao do zap in a voice channel.
  """
  Cogs.def gemidao do
    case Cogs.guild() do
      {:ok, guild} ->
        voice_channel = Enum.find(guild.channels, &match?(%{type: :voice}, &1))
        Voice.join(guild.id, voice_channel.id)
        Voice.play_file(guild.id, "lib/assets/gemidao.mp3")

      {:error, reason} ->
        Logger.error(reason)
        Cogs.say(":exclamation: **#{reason}**")
    end
  end

  @doc """
  Gets a random comment from brazilian porn on xvideos.

  Inspired by `https://github.com/ihavenonickname/bot-telegram-comentarios-xvideos`.
  """
  Cogs.def xvideos do
    {title, %{"c" => content, "n" => author}} = Utils.get_comment()
    title   = Utils.escape(title)
    author  = Utils.escape(author)
    content = Utils.escape(content)

    %Embed{color: 0xe80000, title: "XVideos"}
    |> Embed.field("Título:", "**`#{title}`**")
    |> Embed.field("#{author} comentou:", "**`#{content}`**")
    |> Embed.send()
  end

  @doc """
  Get info about a specific color.
  """
  Cogs.def color(hex \\ "") do
    pattern1 = ~r/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/
    pattern2 = ~r/^([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/

    color =
      cond do
        Regex.match?(pattern1, hex) -> hex
        Regex.match?(pattern2, hex) -> "#" <> hex
        true ->
          # named colors
          case CssColors.parse(hex) do
            {:ok, _} -> hex
            {:error, _} -> :error
          end
      end

    case color do
      :error ->
        Cogs.say(":exclamation: **Invalid color**")
      color ->
        Utils.color_embed(color)
        |> Embed.send("", file: "lib/assets/color.jpg")

        File.rm("lib/assets/color.jpg")
    end
  end

  @doc """
  Get the contents of a pastebin link from a key.
  """
  Cogs.def pastebin(id) do
    {:ok, res} = HTTPoison.get("https://pastebin.com/raw/#{id}")

    case res.status_code do
      200 ->
        msg = "```#{res.body}```"
        if Utils.message_exceed?(msg) do
          Cogs.say(":exclamation: **That pastebin content exceeds the characters limit!**")
        else
          Cogs.say(msg)
        end
      404 ->
        Cogs.say(":exclamation: **Pastebin link not found**")
      status ->
        Logger.info("Unexpected status code: #{status}")
        Cogs.say("**An unexpected error has occurred.**")
    end
  end

  @doc """
  Get the contents of a hastebin link from a key.
  """
  Cogs.def hastebin(id) do
    {:ok, res} = HTTPoison.get("https://hastebin.com/raw/#{id}")

    case res.status_code do
      200 ->
        msg = "```#{res.body}```"
        if Utils.message_exceed?(msg) do
          Cogs.say(":exclamation: **That hastebin content exceeds the characters limit!**")
        else
          Cogs.say(msg)
        end
      404 ->
        Cogs.say(":exclamation: **Hastebin link not found**")
      status ->
        Logger.info("Unexpected status code: #{status}")
        Cogs.say("**An unexpected error has occurred.**")
    end
  end
end
