defmodule RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import KeyMaps.TestHelpers

  alias KeyMaps.{Models}

  @user_default %{ email: "default@email.com", password: "test-default", username: "default" }
  @user_auth %{ email: "auth@email.com", password: "test-auth", username: "auth" }


  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(KeyMaps.Repo)

    # setup db
    Ecto.Adapters.SQL.Sandbox.mode(KeyMaps.Repo, { :shared, self() })

    # create test user
    { :ok, user } = Models.User.create(@user_default)
    { :ok, token, _ } = Guardian.encode_and_sign(user)
    params = %{ user_id: user.id }

    # prebuild map
    map_attributes = %{ name: "Quotes", attributes: ["quote", "author"] }
    map = Models.Map.create(params, map_attributes, nil)

    # --> share data with tests
    { :ok, %{ token: token, map: map } }
  end



  #
  # USERS / AUTHENTICATION
  #

  @tag :users
  test "users -- sign up and in" do
    conn = request_with_json_body(:post, "/sign-up", @user_auth)
    token = data_response(conn)["token"]

    # assert
    assert conn.status == 201
    assert token
    assert String.length(token) > 0

    # --- sign in
    conn = request_with_json_body(:post, "/sign-in", @user_auth)
    token = data_response(conn)["token"]

    # assert
    assert conn.status == 200
    assert token
    assert String.length(token) > 0
  end


  @tag :users
  test "users -- should have a unique email" do
    attr = Map.put(@user_default, :username, "something")
    conn = request_with_json_body(:post, "/sign-up", attr)

    # assert
    assert conn.status == 400
  end


  @tag :users
  test "users -- should have a unique username" do
    attr = Map.put(@user_default, :email, "other-email@example.com")
    conn = request_with_json_body(:post, "/sign-up", attr)

    # assert
    assert conn.status == 400
  end


  @tag :users
  test "users -- should be authenticated for graphql queries (ie. /api)" do
    conn = graphql_request(:query, :maps, ~w(name))
    message = error_response(conn)["message"]

    # assert
    assert conn.status == 403
    assert message == "Forbidden"
  end



  #
  # MAPS
  #

  @tag :maps
  test "maps -- create", context do
    conn = graphql_request(
      :mutation,
      :createMap,
      %{ name: "Test", attributes: ["example"] },
      ~w(name),
      context.token
    )

    # assert
    assert conn.status == 200
  end


  @tag :maps
  test "maps -- create -- name should be unique (case insensitive)", context do
    try do
      graphql_request(
        :mutation,
        :createMap,
        %{ name: "quotes", attributes: ["something"] },
        ~w(name),
        context.token
      )
    rescue
      err -> assert err.status == 422
    end
  end


  @tag :maps
  test "maps -- create -- name should only be unique per user" do
    user_attr = %{
      email: "maps-create-unique@email.com",
      password: "test-maps-create",
      username: "mcu"
    }

    { :ok, user } = Models.User.create(user_attr)
    { :ok, token, _ } = Guardian.encode_and_sign(user)

    # make map
    conn = graphql_request(
      :mutation,
      :createMap,
      %{ name: "Quotes", attributes: ["something"] },
      ~w(name),
      token
    )

    # assert
    assert conn.status == 200
  end


  @tag :maps
  test "maps -- create -- should have attributes", context do
    conn = graphql_request(
      :mutation,
      :createMap,
      %{ name: "Test - MHA", attributes: [] },
      ~w(name),
      context.token
    )

    # assert
    assert conn.status == 400
    assert error_response(conn)["message"] =~ "at least 1 item"
  end


  @tag :maps
  test "maps -- create -- should have valid attributes", context do
    conn = graphql_request(
      :mutation,
      :createMap,
      %{ name: "Test - MHVA", attributes: [0, 1, 2] },
      ~w(attributes),
      context.token
    )

    # assert
    assert conn.status == 400
    assert error_response(conn)["message"] =~ "can't be blank"
  end


  @tag :maps
  test "maps -- create -- should sluggify attributes", context do
    conn = graphql_request(
      :mutation,
      :createMap,
      %{ name: "Test - MHVA", attributes: ["must be slugged"] },
      ~w(attributes),
      context.token
    )

    # assert
    assert conn.status == 200
    assert List.first(data_response(conn)["createMap"]["attributes"]) != "must be slugged"
  end


  @tag :maps
  test "maps -- get", context do
     conn = graphql_request(:query, :map, %{ name: "Quotes" }, ~w(name), context.token)

     # assert
     assert data_response(conn)["map"]["name"] == "Quotes"
  end


  @tag :maps
  test "maps -- all", context do
     conn = graphql_request(:query, :maps, ~w(name), context.token)

     # response
     map_item = data_response(conn)["maps"] |> List.first

     # assert
     assert map_item["name"] == "Quotes"
  end



  #
  # MAP ITEMS
  #

  @tag :map_items
  test "map items -- create", context do
    conn = graphql_request(
      :mutation,
      :createMapItem,
      %{ map: "Quotes", quote: "A", author: "B" },
      ~w(attributes),
      context.token
    )

    # response
    map_item = data_response(conn)["createMapItem"]

    # assert
    assert conn.status == 200
    assert map_item["attributes"]["quote"] == "A"
    assert map_item["attributes"]["author"] == "B"
  end


  @tag :map_items
  test "map items -- create -- should filter other attributes", context do
    conn = graphql_request(
      :mutation,
      :createMapItem,
      %{ map: "Quotes", quote: "A", shouldNotBeHere: true },
      ~w(attributes),
      context.token
    )

    # response
    map_item = data_response(conn)["createMapItem"]

    # assert
    assert conn.status == 200
    assert map_item["attributes"]["quote"] == "A"
    assert map_item["attributes"]["shouldNotBeHere"] == nil
  end



  #
  # PUBLIC
  #

  @tag :public
  test "public" do
    assert true
  end

end