defmodule Api.ChatTest do
  use Api.DataCase

  import Api.Factory

  alias Api.Chat

  describe "new/1" do
    test "creates a chat" do
      user = insert_user()
      assert {:ok, chat} = Chat.new(%{name: "My Chat", author_id: user.id})
      assert chat.name == "My Chat"
      assert chat.author_id == user.id
      assert chat.deleted_at == nil
    end

    test "requires author_id" do
      assert {:error, changeset} = Chat.new(%{name: "My Chat"})
      assert %{author_id: _} = errors_on(changeset)
    end

    test "requires name" do
      user = insert_user()
      assert {:error, changeset} = Chat.new(%{author_id: user.id})
      assert %{name: _} = errors_on(changeset)
    end
  end

  describe "get_by_id/2" do
    test "returns own chat" do
      user = insert_user()
      chat = insert_chat(user)
      assert {:ok, found} = Chat.get_by_id(chat.id, user.id)
      assert found.id == chat.id
    end

    test "returns error for another user's chat" do
      owner = insert_user()
      other = insert_user()
      chat = insert_chat(owner)
      assert {:error, _} = Chat.get_by_id(chat.id, other.id)
    end

    test "returns error for soft-deleted chat" do
      user = insert_user()
      chat = insert_chat(user)
      {:ok, _} = Chat.delete_by_id(chat.id, user.id)
      assert {:error, _} = Chat.get_by_id(chat.id, user.id)
    end

    test "returns error for unknown id" do
      user = insert_user()
      assert {:error, _} = Chat.get_by_id(Ecto.UUID.generate(), user.id)
    end
  end

  describe "get_by_user_id/1" do
    test "returns only own non-deleted chats" do
      user = insert_user()
      other = insert_user()
      chat_a = insert_chat(user, %{name: "Chat A"})
      chat_b = insert_chat(user, %{name: "Chat B"})
      _other_chat = insert_chat(other)
      # soft-delete one
      Chat.delete_by_id(chat_b.id, user.id)

      chats = Chat.get_by_user_id(user.id)
      ids = Enum.map(chats, & &1.id)
      assert chat_a.id in ids
      refute chat_b.id in ids
    end

    test "returns empty list when user has no chats" do
      user = insert_user()
      assert Chat.get_by_user_id(user.id) == []
    end
  end

  describe "rename_by_id/3" do
    test "renames own chat" do
      user = insert_user()
      chat = insert_chat(user)
      assert {:ok, updated} = Chat.rename_by_id(chat.id, user.id, "Renamed")
      assert updated.name == "Renamed"
    end

    test "returns error for another user's chat" do
      owner = insert_user()
      other = insert_user()
      chat = insert_chat(owner)
      assert {:error, _} = Chat.rename_by_id(chat.id, other.id, "Hack")
    end

    test "returns error for soft-deleted chat" do
      user = insert_user()
      chat = insert_chat(user)
      {:ok, _} = Chat.delete_by_id(chat.id, user.id)
      assert {:error, _} = Chat.rename_by_id(chat.id, user.id, "Ghost")
    end
  end

  describe "delete_by_id/2" do
    test "soft-deletes own chat" do
      user = insert_user()
      chat = insert_chat(user)
      assert {:ok, deleted} = Chat.delete_by_id(chat.id, user.id)
      assert deleted.deleted_at != nil
      assert {:error, _} = Chat.get_by_id(chat.id, user.id)
    end

    test "returns error for another user's chat" do
      owner = insert_user()
      other = insert_user()
      chat = insert_chat(owner)
      assert {:error, _} = Chat.delete_by_id(chat.id, other.id)
    end

    test "returns error when already deleted" do
      user = insert_user()
      chat = insert_chat(user)
      {:ok, _} = Chat.delete_by_id(chat.id, user.id)
      assert {:error, _} = Chat.delete_by_id(chat.id, user.id)
    end
  end

  describe "to_public/1" do
    test "returns a ChatPublic struct with correct fields" do
      user = insert_user()
      chat = insert_chat(user, %{name: "Public Test"})
      pub = Chat.to_public(chat)
      assert %Api.ChatPublic{} = pub
      assert pub.id == chat.id
      assert pub.name == "Public Test"
      assert pub.author_id == user.id
      assert pub.timestamp == chat.inserted_at
    end
  end
end
