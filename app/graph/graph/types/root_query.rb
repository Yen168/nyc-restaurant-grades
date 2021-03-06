require 'graph/enum/restaurant_borough_enum'

module Graph
  module Types
    RootQuery = GraphQL::ObjectType.define do
      name 'RootQuery'
      description 'The query root.'

      field :node, :field => NodeIdentification.field

      field :restaurant do
        type -> { Types::Restaurant }
        description 'Perform a search for one restaurant.'

        argument :name, types.String

        resolve -> (object, arguments, context) do
          ::Restaurant.find_by(name: arguments['name'])
        end
      end

      connection :restaurants, -> { !Types::Restaurant.connection_type } do
        description 'Perform a search across all Restaurants.'
        type -> { Types::Restaurant }

        argument :name, types.String
        argument :borough, Types::RestaurantBoroughEnum

        resolve -> (object, arguments, context) do
          name = arguments['name']
          borough = ::Restaurant.boroughs[arguments['borough']]

          if name && borough
            ::Restaurant.where(name: name, borough: borough)
          elsif name
            ::Restaurant.where(name: name)
          elsif borough
            ::Restaurant.where(borough: borough)
          else
            ::Restaurant.all
          end
        end
      end

      connection :inspections, -> { !Types::Inspection.connection_type } do
        description 'Perform a search across all Inspections.'
        type -> { Types::Inspection }

        argument :grade, types.String

        resolve -> (object, arguments, context) do
          grade = arguments['grade']

          if grade
            ::Inspection.includes(:restaurant).where(grade: grade)
          else
            ::Inspection.includes(:restaurant).all
          end
        end
      end
    end
  end
end
