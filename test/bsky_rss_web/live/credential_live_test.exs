defmodule BskyRssWeb.CredentialLiveTest do
  use BskyRssWeb.ConnCase

  import Phoenix.LiveViewTest
  import BskyRss.AuthFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_credential(_) do
    credential = credential_fixture()
    %{credential: credential}
  end

  describe "Index" do
    setup [:create_credential]

    test "lists all credentials", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/credentials")

      assert html =~ "Listing Credentials"
    end

    test "saves new credential", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/credentials")

      assert index_live |> element("a", "New Credential") |> render_click() =~
               "New Credential"

      assert_patch(index_live, ~p"/credentials/new")

      assert index_live
             |> form("#credential-form", credential: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#credential-form", credential: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/credentials")

      html = render(index_live)
      assert html =~ "Credential created successfully"
    end

    test "updates credential in listing", %{conn: conn, credential: credential} do
      {:ok, index_live, _html} = live(conn, ~p"/credentials")

      assert index_live |> element("#credentials-#{credential.id} a", "Edit") |> render_click() =~
               "Edit Credential"

      assert_patch(index_live, ~p"/credentials/#{credential}/edit")

      assert index_live
             |> form("#credential-form", credential: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#credential-form", credential: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/credentials")

      html = render(index_live)
      assert html =~ "Credential updated successfully"
    end

    test "deletes credential in listing", %{conn: conn, credential: credential} do
      {:ok, index_live, _html} = live(conn, ~p"/credentials")

      assert index_live |> element("#credentials-#{credential.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#credentials-#{credential.id}")
    end
  end

  describe "Show" do
    setup [:create_credential]

    test "displays credential", %{conn: conn, credential: credential} do
      {:ok, _show_live, html} = live(conn, ~p"/credentials/#{credential}")

      assert html =~ "Show Credential"
    end

    test "updates credential within modal", %{conn: conn, credential: credential} do
      {:ok, show_live, _html} = live(conn, ~p"/credentials/#{credential}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Credential"

      assert_patch(show_live, ~p"/credentials/#{credential}/show/edit")

      assert show_live
             |> form("#credential-form", credential: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#credential-form", credential: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/credentials/#{credential}")

      html = render(show_live)
      assert html =~ "Credential updated successfully"
    end
  end
end
