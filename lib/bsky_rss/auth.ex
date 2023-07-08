defmodule BskyRss.Auth do
  @moduledoc """
  The Auth context.
  """

  alias BskyRss.Bsky

  def session(client, user, pass) do
    {:ok, session} = Bsky.auth(client, user, pass)
    session
  end
end
