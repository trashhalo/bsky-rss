defmodule BskyRss.Bsky do
  def client() do
    XRPC.Client.new("https://bsky.social")
  end

  def auth(client, user, pass) do
    ATProto.create_session(client, user, pass)
  end

  def get_feed(client, session) do
    {:ok, feed} =
      client
      |> Map.put(:access_token, session.access_jwt)
      |> ATProto.BSky.get_timeline()

    feed.feed
  end

  def get_profile(client, session, user) do
    client
    |> Map.put(:access_token, session.access_jwt)
    |> ATProto.BSky.get_profile(user)
  end
end
