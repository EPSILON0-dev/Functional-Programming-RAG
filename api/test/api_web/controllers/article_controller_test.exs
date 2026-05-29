defmodule ApiWeb.Controllers.ArticleControllerTest do
  use ApiWeb.ConnCase

  describe "GET /api/articles" do
    test "returns paginated articles with total, offset, limit", %{conn: conn} do
      user = insert_user()
      insert_article()
      insert_article()

      conn = conn |> log_in_conn(user) |> get(~p"/api/articles")
      body = json_response(conn, 200)
      assert is_list(body["articles"])
      assert is_integer(body["total"])
      assert Map.has_key?(body, "offset")
      assert Map.has_key?(body, "limit")
    end

    test "respects offset and limit params", %{conn: conn} do
      user = insert_user()
      for _ <- 1..5, do: insert_article()

      conn = conn |> log_in_conn(user) |> get(~p"/api/articles?offset=0&limit=2")
      body = json_response(conn, 200)
      assert length(body["articles"]) <= 2
      assert body["limit"] == 2
      assert body["offset"] == 0
    end

    test "returns empty articles list when offset is beyond total", %{conn: conn} do
      user = insert_user()
      total = Api.Article.count()

      conn =
        conn
        |> log_in_conn(user)
        |> get(~p"/api/articles?offset=#{total + 1000}&limit=10")

      body = json_response(conn, 200)
      assert body["articles"] == []
    end

    test "returns 401 without token", %{conn: conn} do
      conn = get(conn, ~p"/api/articles")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/articles?q=..." do
    test "returns matching articles with total and limit", %{conn: conn} do
      user = insert_user()
      insert_article(%{title: "Elixir Concurrency Model"})

      conn = conn |> log_in_conn(user) |> get(~p"/api/articles?q=Elixir+Concurrency")
      body = json_response(conn, 200)
      assert is_list(body["articles"])
      assert is_integer(body["total"])
      assert Map.has_key?(body, "limit")
      refute Map.has_key?(body, "offset")
      assert Enum.any?(body["articles"], &String.contains?(&1["title"], "Elixir"))
    end

    test "returns empty list for unmatched search term", %{conn: conn} do
      user = insert_user()
      conn = conn |> log_in_conn(user) |> get(~p"/api/articles?q=zzz_no_match_zzz")
      body = json_response(conn, 200)
      assert body["articles"] == []
      assert body["total"] == 0
    end

    test "returns 401 without token", %{conn: conn} do
      conn = get(conn, ~p"/api/articles?q=test")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/articles/:article_id" do
    test "returns article details", %{conn: conn} do
      user = insert_user()
      article = insert_article(%{title: "Detail Test"})

      conn = conn |> log_in_conn(user) |> get(~p"/api/articles/#{article.id}")
      body = json_response(conn, 200)
      assert body["id"] == article.id
      assert body["title"] == "Detail Test"
      assert Map.has_key?(body, "description")
      assert Map.has_key?(body, "content")
    end

    test "returns 404 for unknown article", %{conn: conn} do
      user = insert_user()
      conn = conn |> log_in_conn(user) |> get(~p"/api/articles/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end

    test "returns 401 without token", %{conn: conn} do
      article = insert_article()
      conn = get(conn, ~p"/api/articles/#{article.id}")
      assert json_response(conn, 401)
    end
  end
end
