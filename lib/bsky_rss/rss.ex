defmodule BskyRss.Rss do
  alias ATProto.BSky.{FeedViewPost, PostView, ProfileViewBasic, ProfileViewDetailed}

  require Logger

  @blocked_domains ["bsky.app"]

  def find_link(text) do
    text
    |> ExAutolink.link()
    |> Floki.parse_fragment!()
    |> Floki.find("a")
    |> Enum.map(fn {"a", attrs, _children} ->
      attrs
      |> Enum.into(%{})
      |> Map.get("href")
    end)
    |> Enum.reject(fn link ->
      host = link
      |> URI.parse()
      |> Map.get(:host)

      Enum.member?(@blocked_domains, host)
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
          uri: uri,
          record: %{"text" => text, "createdAt" => created_at},
          author: %ProfileViewBasic{handle: handle, display_name: display_name}
        }
      }) do
    case find_link(text) do
      nil ->
        nil

      link ->
        Logger.metadata(link: link)

        %Readability.Summary{title: title, authors: _authors, article_html: article} =
          Readability.summarize(link)

        description =
          desc(
            handle: handle,
            display_name: display_name,
            text: text,
            article: article,
            post_id:
              uri
              |> String.split("/")
              |> Enum.at(-1)
          )

        RSS.item(title, description, created_at, link, cid)
    end
  rescue
    e ->
      Logger.error(
        "Error summarizing post #{cid}: #{Exception.format(:error, e, Map.get(e, :stacktrace))}"
      )

      nil
  after
    Logger.metadata(link: nil)
  end

  def desc(assigns) do
    """
      <p>
        <a href="https://https://bsky.app/profile/<%= handle %>"><%= display_name %></a>
        <a href="https://bsky.app/profile/<%= handle %>/post/<%= post_id %>">post</a>
      </p>
      <p>
        <%= text %>
      </p>
      <hr/>
      <p>
        <%= article %>
      </p>
    """
    |> EEx.eval_string(assigns)
  end
end
