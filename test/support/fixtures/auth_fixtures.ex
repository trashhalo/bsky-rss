defmodule BskyRss.AuthFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BskyRss.Auth` context.
  """

  @doc """
  Generate a credential.
  """
  def credential_fixture(attrs \\ %{}) do
    {:ok, credential} =
      attrs
      |> Enum.into(%{})
      |> BskyRss.Auth.create_credential()

    credential
  end
end
