defmodule KeyMaps.Utils do

  def render_data(conn, status, map) do
    render_json(conn, status, %{ data: map })
  end


  def render_error(conn, status, message) do
    render_json(conn, status, %{ errors: [%{ message: message }] })
  end


  def render_token(conn, status, user, auth0_id_token) do
    case KeyMaps.Auth.generate_token(user, auth0_id_token) do
      { :ok, token, _ } -> render_data(conn, status, %{ token: token })
      { :error, reason } -> render_error(conn, 500, reason)
    end
  end


  def render_empty(conn, status) do
    render_json(conn, status, %{})
  end


  def get_error_from_changeset(changeset) do
    cond do
      # errors
      length(changeset.errors) > 0 ->
        field = Keyword.keys(changeset.errors) |> List.first |> Atom.to_string
        field = String.replace(field, "_", " ")

        fieldError = Keyword.values(changeset.errors) |> List.first
        fieldError = if is_tuple(fieldError) do
          String.replace(
            elem(fieldError, 0),
            "%{count}",
            to_string(elem(fieldError, 1)[:count])
          )
        else
          fieldError
        end

        String.capitalize(field) <> " " <> fieldError

      # constraints
      length(changeset.constraints) > 0 ->
        changeset.constraints[0].message

      # fallback
      true ->
        model = changeset.model.__struct__ |> Module.split |> List.last
        action = to_string(changeset.action)

        "Could not " <> action <> " " <> model
    end
  end


  def extract_other_arguments(internal) do
    if length(Map.keys(internal.variable_values)) > 0,
      do: extract_other_arguments(:var, internal),
    else: extract_other_arguments(:ast, internal)
  end


  #
  # Private
  #
  defp render_json(conn, status, map) do
    content = Poison.encode!(map, escape: :unicode)

    Plug.Conn.put_resp_content_type(conn, "application/json")
    Plug.Conn.send_resp(conn, status, content)
  end


  defp extract_other_arguments(:var, internal) do
    m = Map.delete(internal.variable_values, "map")
    m = for { key, val } <- m, into: %{}, do: { String.to_atom(key), val }
    m
  end


  defp extract_other_arguments(:ast, internal) do
    try do
      inn = internal.field_asts |> List.first

      if Map.has_key?(inn, :arguments) do
        Enum.reduce inn.arguments, %{}, fn(arg, acc) ->
          k = String.to_atom(arg.name.value)
          v = arg.value.value
          Map.put(acc, k, v)
        end
      end

    rescue
      KeyError -> %{}

    end
  end

end
