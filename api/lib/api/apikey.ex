defmodule Api.APIKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "apikeys" do
    field(:encrypted_key, :binary)
    field(:name, :string)
    belongs_to(:owner, Api.User, foreign_key: :owner_id, type: :binary_id)

    timestamps(type: :utc_datetime)
  end

  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:owner_id, :encrypted_key, :name])
    |> validate_required([:owner_id, :encrypted_key, :name])
    |> prepare_changes(&encrypt_key_if_present/1)
  end

  defp encrypt_key_if_present(changeset) do
    case get_change(changeset, :encrypted_key) do
      nil -> changeset
      plain_key -> put_change(changeset, :encrypted_key, encrypt_key(plain_key))
    end
  end

  def to_public(%__MODULE__{} = api_key) do
    decrypted_key = decrypt_key(api_key.encrypted_key)

    shadowed_key =
      if byte_size(decrypted_key) > 14 do
        String.slice(decrypted_key, 0..10) <> "..." <> String.slice(decrypted_key, -4..-1)
      else
        "..."
      end

    %Api.APIKeyPublic{
      id: api_key.id,
      key: shadowed_key,
      name: api_key.name,
      owner_id: api_key.owner_id,
      timestamp: api_key.inserted_at
    }
  end

  def get_by_id(key_id, user_id) do
    with api_key <- Api.Repo.get_by(__MODULE__, id: key_id, owner_id: user_id),
         false <- is_nil(api_key) do
      {:ok, api_key}
    else
      _ -> {:error, "API key not found"}
    end
  end

  def new(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Api.Repo.insert()
  end

  def delete(key_id, user_id) do
    with {:ok, api_key} <- get_by_id(key_id, user_id) do
      Api.Repo.delete(api_key)
    end
  end

  # TODO - implement real encryption and decryption
  # Stupid little fuck Claude is too retarded to do it by itself and gaslights me about it working
  defp encrypt_key(plain_key) do
    plain_key
  end

  def decrypt_key(encrypted_key) do
    encrypted_key
  end

end
