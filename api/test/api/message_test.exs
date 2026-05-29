defmodule Api.MessageTest do
  use Api.DataCase

  import Api.Factory

  alias Api.Message

  describe "new/1" do
    test "creates a message" do
      user = insert_user()
      chat = insert_chat(user)

      assert {:ok, msg} =
               Message.new(%{
                 content: "Hello",
                 role: "user",
                 chat_id: chat.id,
                 author_id: user.id
               })

      assert msg.content == "Hello"
      assert msg.role == "user"
      assert msg.deleted_at == nil
    end

    test "requires role" do
      user = insert_user()
      chat = insert_chat(user)
      assert {:error, changeset} = Message.new(%{chat_id: chat.id})
      assert %{role: _} = errors_on(changeset)
    end

    test "requires chat_id" do
      assert {:error, changeset} = Message.new(%{role: "user"})
      assert %{chat_id: _} = errors_on(changeset)
    end

    test "allows nil author_id (system messages)" do
      user = insert_user()
      chat = insert_chat(user)

      assert {:ok, msg} =
               Message.new(%{
                 content: "System response",
                 role: "assistant",
                 chat_id: chat.id
               })

      assert msg.author_id == nil
    end
  end

  describe "get_by_chat_id/2" do
    test "returns messages for own chat" do
      user = insert_user()
      chat = insert_chat(user)
      msg = insert_message(chat, user)

      assert {:ok, messages} = Message.get_by_chat_id(chat.id, user.id)
      ids = Enum.map(messages, & &1.id)
      assert msg.id in ids
    end

    test "returns error for another user's chat" do
      owner = insert_user()
      other = insert_user()
      chat = insert_chat(owner)
      insert_message(chat, owner)

      assert {:error, _} = Message.get_by_chat_id(chat.id, other.id)
    end

    test "excludes soft-deleted messages" do
      user = insert_user()
      chat = insert_chat(user)
      _msg = insert_message(chat, user)
      :ok = Message.delete_by_chat_id(chat.id, user.id)

      assert {:ok, messages} = Message.get_by_chat_id(chat.id, user.id)
      assert messages == []
    end

    test "returns empty list for chat with no messages" do
      user = insert_user()
      chat = insert_chat(user)
      assert {:ok, []} = Message.get_by_chat_id(chat.id, user.id)
    end
  end

  describe "update_by_id/2" do
    test "updates content and metadata" do
      user = insert_user()
      chat = insert_chat(user)
      msg = insert_message(chat, user, %{content: "original"})

      assert {:ok, updated} =
               Message.update_by_id(msg.id, %{
                 content: "updated",
                 role: "user",
                 chat_id: chat.id
               })

      assert updated.content == "updated"
    end

    test "returns error for unknown id" do
      assert {:error, _} = Message.update_by_id(Ecto.UUID.generate(), %{content: "x"})
    end
  end

  describe "delete_by_chat_id/2" do
    test "soft-deletes messages by chat and user" do
      user = insert_user()
      chat = insert_chat(user)
      insert_message(chat, user)
      insert_message(chat, user)

      assert :ok = Message.delete_by_chat_id(chat.id, user.id)
      assert {:ok, []} = Message.get_by_chat_id(chat.id, user.id)
    end
  end

  describe "to_public/1" do
    test "returns a MessagePublic struct with correct fields" do
      user = insert_user()
      chat = insert_chat(user)
      msg = insert_message(chat, user, %{content: "hello"})
      pub = Message.to_public(msg)
      assert %Api.MessagePublic{} = pub
      assert pub.id == msg.id
      assert pub.content == "hello"
      assert pub.role == "user"
      assert pub.chat_id == chat.id
      assert pub.author_id == user.id
    end
  end
end
