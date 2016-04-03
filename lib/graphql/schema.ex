defmodule KeyMaps.GraphQL.Schema do
  alias KeyMaps.GraphQL.{Definitions}
  alias KeyMaps.{Models.Map, Models.MapItem}

  def schema do
    %GraphQL.Schema{

      query: %GraphQL.Type.ObjectType{
        name: "Queries",
        description: "Key Maps API Queries",
        fields: %{
          map:        Definitions.build(Map,      :get, ~w(name)a   ),
          maps:       Definitions.build(Map,      :all, ~w()a       ),
          mapItems:   Definitions.build(MapItem,  :all, ~w(map)a    ),
        }
      },

      mutation: %GraphQL.Type.ObjectType{
        name: "Mutations",
        description: "Key Maps API Mutations",
        fields: %{
          createMap:      Definitions.build(Map,      :create, ~w(name attributes)a   ),
          createMapItem:  Definitions.build(MapItem,  :create, ~w(map attributes)a    ),
        },
      }

    }
  end

end