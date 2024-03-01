defmodule Ash.Test.Type.StringTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Ash.Test.Domain, as: Domain

  defmodule Post do
    @moduledoc false
    use Ash.Resource, domain: Domain, data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    actions do
      defaults [:create, :read, :update, :destroy]
    end

    attributes do
      uuid_primary_key :id

      # Possible constraint combinations:
      #
      # a. [allow_empty?: false, trim?: true] (default)
      # b. [allow_empty?: false, trim?: false]
      # c. [allow_empty?: true, trim?: true]
      # d. [allow_empty?: true, trim?: false]
      #
      attribute :string_a, :string
      attribute :string_b, :string, constraints: [trim?: false]
      attribute :string_c, :string, constraints: [allow_empty?: true]
      attribute :string_d, :string, constraints: [allow_empty?: true, trim?: false]

      attribute :string_e, :string, constraints: [min_length: 3, max_length: 6]
      attribute :string_f, :string, constraints: [min_length: 3, max_length: 6, trim?: false]
    end
  end

  test "it handles non-empty values" do
    post =
      Post
      |> Ash.Changeset.for_create(:create, %{
        string_a: "  foo  ",
        string_b: "  foo  ",
        string_c: "  bar  ",
        string_d: "  bar  "
      })
      |> Domain.create!()

    assert post.string_a == "foo"
    assert post.string_b == "  foo  "
    assert post.string_c == "bar"
    assert post.string_d == "  bar  "
  end

  test "it handles empty values" do
    post =
      Post
      |> Ash.Changeset.for_create(:create, %{
        string_a: " ",
        string_b: " ",
        string_c: " ",
        string_d: " "
      })
      |> Domain.create!()

    assert post.string_a == nil
    assert post.string_b == nil
    assert post.string_c == ""
    assert post.string_d == " "
  end

  test "it handles values with length constraints" do
    e_allowed_values = ["123", "123456", " 123456 "]
    f_allowed_values = [" 2 ", "123456", "  34  "]

    allowed_values = Enum.zip(e_allowed_values, f_allowed_values)

    Enum.each(allowed_values, fn {e_val, f_val} ->
      Post
      |> Ash.Changeset.for_create(:create, %{string_e: e_val, string_f: f_val})
      |> Domain.create!()
    end)
  end

  test "it handles too short values with length constraints" do
    assert_raise(Ash.Error.Invalid, ~r/string_e: length must be greater/, fn ->
      Post
      |> Ash.Changeset.for_create(:create, %{string_e: "   45   "})
      |> Domain.create!()
    end)

    assert_raise(Ash.Error.Invalid, ~r/string_f: length must be greater/, fn ->
      Post
      |> Ash.Changeset.for_create(:create, %{string_f: "12"})
      |> Domain.create!()
    end)
  end

  test "it handles too long values with length constraints" do
    assert_raise(Ash.Error.Invalid, ~r/string_e: length must be less/, fn ->
      Post
      |> Ash.Changeset.for_create(:create, %{string_e: "1234567"})
      |> Domain.create!()
    end)

    assert_raise(Ash.Error.Invalid, ~r/string_f: length must be less/, fn ->
      Post
      |> Ash.Changeset.for_create(:create, %{string_f: "   45   "})
      |> Domain.create!()
    end)
  end
end
