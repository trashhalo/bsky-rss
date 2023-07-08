defmodule BskyRssWeb.RssController do
  use BskyRssWeb, :controller

  alias BskyRss.Bsky
  alias BskyRss.Rss

  def index(conn, _params) do
    {:ok, profile} =
      Bsky.get_profile(conn.assigns.client, conn.assigns.session, conn.assigns.user)

    feed = Bsky.get_feed(conn.assigns.client, conn.assigns.session)
    rss = Rss.feed_to_rss(profile, feed)

    conn
    |> put_resp_content_type("application/rss+xml")
    |> send_resp(200, rss)
  end
end
