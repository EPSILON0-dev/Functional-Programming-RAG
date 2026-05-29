defmodule Api.Factory do
  @moduledoc """
  In-process test factory. All `insert_*` functions persist the record and
  return the struct (not a tuple) so callers can use the result directly.

  Default plaintext password for users is "password".
  """

  alias Api.{Article, APIKey, Chat, Message, User}

  @default_password "password"

  def insert_user(attrs \\ %{}) do
    params = %{
      username: Map.get(attrs, :username, "user_#{System.unique_integer([:positive])}"),
      password: Bcrypt.hash_pwd_salt(Map.get(attrs, :password, @default_password))
    }

    {:ok, user} = User.new(params)
    user
  end

  def insert_chat(user, attrs \\ %{}) do
    params = %{
      name: Map.get(attrs, :name, "Test Chat"),
      author_id: user.id
    }

    {:ok, chat} = Chat.new(params)
    chat
  end

  def insert_message(chat, user, attrs \\ %{}) do
    params = %{
      content: Map.get(attrs, :content, "Test message"),
      role: Map.get(attrs, :role, "user"),
      chat_id: chat.id,
      author_id: user.id
    }

    {:ok, message} = Message.new(params)
    message
  end

  def insert_article(attrs \\ %{}) do
    params = %{
      title: Map.get(attrs, :title, "Article #{System.unique_integer([:positive])}"),
      description: Map.get(attrs, :description, "A test description"),
      content: Map.get(attrs, :content, "Test article content"),
      generation_cost: Map.get(attrs, :generation_cost, 0.001),
      embedding_model: Map.get(attrs, :embedding_model, "text-embedding-3-small")
    }

    {:ok, article} = Article.new(params)
    article
  end

  def insert_api_key(user, attrs \\ %{}) do
    params = %{
      name: Map.get(attrs, :name, "Test Key"),
      encrypted_key: Map.get(attrs, :encrypted_key, "sk-test-key-1234567890"),
      owner_id: user.id
    }

    {:ok, key} = APIKey.new(params)
    key
  end
end
