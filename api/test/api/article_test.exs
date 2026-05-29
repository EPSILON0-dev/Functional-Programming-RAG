defmodule Api.ArticleTest do
  use Api.DataCase

  import Api.Factory

  alias Api.Article

  describe "changeset/2" do
    test "is valid with all required fields" do
      changeset =
        Article.changeset(%Article{}, %{
          title: "T",
          description: "D",
          content: "C",
          generation_cost: 0.001,
          embedding_model: "text-embedding-3-small"
        })

      assert changeset.valid?
    end

    test "requires title" do
      changeset =
        Article.changeset(%Article{}, %{
          description: "D",
          content: "C",
          generation_cost: 0.001,
          embedding_model: "m"
        })

      assert %{title: _} = errors_on(changeset)
    end

    test "requires description" do
      changeset =
        Article.changeset(%Article{}, %{
          title: "T",
          content: "C",
          generation_cost: 0.001,
          embedding_model: "m"
        })

      assert %{description: _} = errors_on(changeset)
    end

    test "requires content" do
      changeset =
        Article.changeset(%Article{}, %{
          title: "T",
          description: "D",
          generation_cost: 0.001,
          embedding_model: "m"
        })

      assert %{content: _} = errors_on(changeset)
    end

    test "is valid without embeddings" do
      changeset =
        Article.changeset(%Article{}, %{
          title: "T",
          description: "D",
          content: "C",
          generation_cost: 0.0,
          embedding_model: "m"
        })

      assert changeset.valid?
    end
  end

  describe "new/1 and get_by_id/1" do
    test "creates and retrieves an article" do
      article = insert_article(%{title: "Unique Title"})
      assert {:ok, found} = Article.get_by_id(article.id)
      assert found.title == "Unique Title"
    end

    test "get_by_id returns error for unknown id" do
      assert {:error, _} = Article.get_by_id(Ecto.UUID.generate())
    end
  end

  describe "get_all/0" do
    test "returns all articles" do
      insert_article()
      insert_article()
      all = Article.get_all()
      assert length(all) >= 2
    end
  end

  describe "get_paginated/2" do
    test "returns up to limit articles" do
      for _ <- 1..5, do: insert_article()
      results = Article.get_paginated(0, 3)
      assert length(results) == 3
    end

    test "returns empty list when offset is beyond total" do
      total = Article.count()
      results = Article.get_paginated(total + 100, 10)
      assert results == []
    end
  end

  describe "count/0" do
    test "returns integer count" do
      before = Article.count()
      insert_article()
      insert_article()
      assert Article.count() == before + 2
    end
  end

  describe "search/2" do
    test "returns articles matching title" do
      insert_article(%{title: "Elixir Programming Guide"})
      results = Article.search("Elixir Programming", 10)
      assert Enum.any?(results, &String.contains?(&1.title, "Elixir"))
    end

    test "returns articles matching description" do
      insert_article(%{
        title: "Some Article",
        description: "Contains a very unique_xyz_term here"
      })

      results = Article.search("unique_xyz_term", 10)
      assert length(results) >= 1
    end

    test "returns empty list for unmatched term" do
      results = Article.search("zzz_no_match_zzz_abc123", 10)
      assert results == []
    end

    test "title matches rank higher than description matches" do
      insert_article(%{title: "Phoenix Framework", description: "A web framework"})
      insert_article(%{title: "Web Frameworks Overview", description: "Phoenix is great"})

      [first | _] = Article.search("Phoenix", 10)
      assert String.contains?(first.title, "Phoenix")
    end
  end

  describe "to_public/1" do
    test "returns ArticlePublic with correct fields" do
      article = insert_article(%{title: "Public Test"})
      pub = Article.to_public(article)
      assert %Api.ArticlePublic{} = pub
      assert pub.id == article.id
      assert pub.title == "Public Test"
      assert pub.description == article.description
      assert pub.content == article.content
      assert pub.generation_cost == article.generation_cost
      assert pub.embedding_model == article.embedding_model
    end
  end
end
