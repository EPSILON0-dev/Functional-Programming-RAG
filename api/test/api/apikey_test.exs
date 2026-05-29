defmodule Api.APIKeyTest do
  use Api.DataCase

  import Api.Factory

  alias Api.{APIKey, Repo}

  describe "new/1" do
    test "creates an API key" do
      user = insert_user()

      assert {:ok, key} =
               APIKey.new(%{
                 owner_id: user.id,
                 name: "My Key",
                 encrypted_key: "sk-test-abc123"
               })

      assert key.name == "My Key"
      assert key.owner_id == user.id
    end

    test "requires owner_id" do
      assert {:error, changeset} = APIKey.new(%{name: "k", encrypted_key: "v"})
      assert %{owner_id: _} = errors_on(changeset)
    end

    test "requires name" do
      user = insert_user()
      assert {:error, changeset} = APIKey.new(%{owner_id: user.id, encrypted_key: "v"})
      assert %{name: _} = errors_on(changeset)
    end

    test "requires encrypted_key" do
      user = insert_user()
      assert {:error, changeset} = APIKey.new(%{owner_id: user.id, name: "k"})
      assert %{encrypted_key: _} = errors_on(changeset)
    end
  end

  describe "get_by_id/2" do
    test "returns own key" do
      user = insert_user()
      key = insert_api_key(user)
      assert {:ok, found} = APIKey.get_by_id(key.id, user.id)
      assert found.id == key.id
    end

    test "returns error for another user's key" do
      owner = insert_user()
      other = insert_user()
      key = insert_api_key(owner)
      assert {:error, _} = APIKey.get_by_id(key.id, other.id)
    end

    test "returns error for unknown id" do
      user = insert_user()
      assert {:error, _} = APIKey.get_by_id(Ecto.UUID.generate(), user.id)
    end
  end

  describe "delete/2" do
    test "hard-deletes own key" do
      user = insert_user()
      key = insert_api_key(user)
      assert {:ok, _} = APIKey.delete(key.id, user.id)
      assert Repo.get(APIKey, key.id) == nil
    end

    test "returns error for another user's key" do
      owner = insert_user()
      other = insert_user()
      key = insert_api_key(owner)
      assert {:error, _} = APIKey.delete(key.id, other.id)
      assert Repo.get(APIKey, key.id) != nil
    end
  end

  describe "to_public/1" do
    test "returns APIKeyPublic with masked key" do
      user = insert_user()
      # key > 14 chars so masking applies
      key = insert_api_key(user, %{encrypted_key: "sk-test-key-1234567890", name: "My Key"})
      pub = APIKey.to_public(key)
      assert %Api.APIKeyPublic{} = pub
      assert pub.id == key.id
      assert pub.name == "My Key"
      assert pub.owner_id == user.id
      assert String.contains?(pub.key, "...")
      refute pub.key == "sk-test-key-1234567890"
    end

    test "masks a short key with just ellipsis" do
      user = insert_user()
      key = insert_api_key(user, %{encrypted_key: "short"})
      pub = APIKey.to_public(key)
      assert pub.key == "..."
    end
  end
end
