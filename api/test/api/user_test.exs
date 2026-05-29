defmodule Api.UserTest do
  use Api.DataCase

  import Api.Factory

  alias Api.User

  describe "changeset/2" do
    test "is valid with username and password" do
      changeset = User.changeset(%User{}, %{username: "alice", password: "somehash"})
      assert changeset.valid?
    end

    test "requires username" do
      changeset = User.changeset(%User{}, %{password: "somehash"})
      refute changeset.valid?
      assert %{username: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires password" do
      changeset = User.changeset(%User{}, %{username: "alice"})
      refute changeset.valid?
      assert %{password: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "new/1" do
    test "creates a user" do
      assert {:ok, user} = User.new(%{username: "alice", password: "hash"})
      assert user.username == "alice"
      assert user.id != nil
    end

    test "rejects a duplicate username" do
      insert_user(%{username: "bob"})
      assert {:error, changeset} = User.new(%{username: "bob", password: "hash"})
      assert %{username: _} = errors_on(changeset)
    end
  end

  describe "get_by_id/1" do
    test "returns existing user" do
      user = insert_user()
      assert {:ok, found} = User.get_by_id(user.id)
      assert found.id == user.id
    end

    test "returns error for soft-deleted user" do
      user = insert_user()
      {:ok, _} = User.delete(user.id)
      assert {:error, _} = User.get_by_id(user.id)
    end

    test "returns error for unknown id" do
      assert {:error, _} = User.get_by_id(Ecto.UUID.generate())
    end
  end

  describe "get_by_username/1" do
    test "returns user" do
      user = insert_user(%{username: "charlie"})
      assert {:ok, found} = User.get_by_username("charlie")
      assert found.id == user.id
    end

    test "returns error for soft-deleted user" do
      user = insert_user(%{username: "dave"})
      {:ok, _} = User.delete(user.id)
      assert {:error, _} = User.get_by_username("dave")
    end

    test "returns error for unknown username" do
      assert {:error, _} = User.get_by_username("nobody")
    end
  end

  describe "rename/2" do
    test "updates the username" do
      user = insert_user()
      assert {:ok, updated} = User.rename(user.id, "newname")
      assert updated.username == "newname"
    end

    test "returns changeset error when username is taken" do
      insert_user(%{username: "taken"})
      user = insert_user()
      assert {:error, changeset} = User.rename(user.id, "taken")
      assert %{username: _} = errors_on(changeset)
    end
  end

  describe "change_password/2" do
    test "updates the stored password" do
      user = insert_user()
      assert {:ok, updated} = User.change_password(user.id, "new_hash_value")
      assert updated.password == "new_hash_value"
    end
  end

  describe "delete/1" do
    test "sets deleted_at and hides user from get_by_id" do
      user = insert_user()
      assert {:ok, deleted} = User.delete(user.id)
      assert deleted.deleted_at != nil
      assert {:error, _} = User.get_by_id(user.id)
    end
  end

  describe "set_selected_key/2" do
    test "updates selected_key_id" do
      user = insert_user()
      key = insert_api_key(user)
      assert {:ok, updated} = User.set_selected_key(user.id, key.id)
      assert updated.selected_key_id == key.id
    end

    test "can clear selected_key_id to nil" do
      user = insert_user()
      key = insert_api_key(user)
      {:ok, _} = User.set_selected_key(user.id, key.id)
      assert {:ok, updated} = User.set_selected_key(user.id, nil)
      assert updated.selected_key_id == nil
    end
  end
end
