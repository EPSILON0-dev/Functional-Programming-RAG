defmodule ApiWeb.Controllers.ArticleController do
  use ApiWeb, :controller

  @default_limit 20
  @max_limit 100

  def get_articles(conn, %{"q" => q} = params) when is_binary(q) and q != "" do
    limit = params["limit"] |> parse_non_neg_integer(@max_limit) |> min(@max_limit)

    articles =
      Api.Article.search(q, limit)
      |> Enum.map(&Api.Article.to_public/1)

    conn
    |> put_status(:ok)
    |> json(%{articles: articles, total: length(articles), limit: limit})
  end

  def get_articles(conn, params) do
    offset = parse_non_neg_integer(params["offset"], 0)
    limit = params["limit"] |> parse_non_neg_integer(@default_limit) |> min(@max_limit)

    articles =
      Api.Article.get_paginated(offset, limit)
      |> Enum.map(&Api.Article.to_public/1)

    total = Api.Article.count()

    conn
    |> put_status(:ok)
    |> json(%{articles: articles, total: total, offset: offset, limit: limit})
  end

  def get_article(conn, %{"article_id" => article_id}) do
    case Api.Article.get_by_id(article_id) do
      {:ok, article} ->
        conn |> put_status(:ok) |> json(Api.Article.to_public(article))

      {:error, _} ->
        conn |> put_status(:not_found) |> json(%{error: "Article not found"})
    end
  end

  defp parse_non_neg_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {n, ""} when n >= 0 -> n
      _ -> default
    end
  end

  defp parse_non_neg_integer(_, default), do: default
end
