defmodule BskyRss.Rss do
  alias ATProto.BSky.{FeedViewPost, PostView, ProfileViewBasic, ProfileViewDetailed}

  require Logger

  def link(text) do
    text
    |> ExAutolink.link()
    |> Floki.parse_fragment!()
    |> Floki.find("a")
    |> Enum.map(fn {"a", attrs, _children} ->
      attrs
      |> Enum.into(%{})
      |> Map.get("href")
    end)
    |> List.first()
  end

  def feed_to_rss(%ProfileViewDetailed{handle: handle}, feed) do
    items =
      feed
      |> Enum.map(&post/1)
      |> Enum.reject(&is_nil/1)

    now =
      Timex.now()
      |> Timex.format!("{RFC1123}")

    RSS.channel(
      "bluesky links for #{handle}",
      "https://bsky.app/",
      "RSS feed of all links found in posts of users you follow",
      now,
      "en-us"
    )
    |> RSS.feed(items)
  end

  def post(%FeedViewPost{
        post: %PostView{
          cid: cid,
          record: %{"text" => text, "createdAt" => created_at},
          author: %ProfileViewBasic{handle: handle, display_name: _display_name}
        }
      }) do
    case link(text) do
      nil ->
        nil

      link ->
        %Readability.Summary{title: title, authors: _authors, article_html: article} =
          Readability.summarize(link)

        RSS.item(title, "@#{handle}: #{text}\n\n#{article}", created_at, link, cid)
    end
  end
end
