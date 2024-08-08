class Geozone < ApplicationRecord
  include Graphqlable

  has_many :proposals
  has_many :debates
  has_many :users
  has_many :headings, class_name: "Budget::Heading", dependent: :nullify
  validates :name, presence: true
  validates :geojson, geojson_format: true

  scope :public_for_api, -> { all }

  def self.names
    Geozone.pluck(:name)
  end

  def safe_to_destroy?
    Geozone.reflect_on_all_associations(:has_many).all? do |association|
      association.klass.where(geozone: self).empty?
    end
  end

  def outline_points
    return [] unless geojson.present? && coordinates.present?

    normalized_coordinates.map { |longlat| [longlat.last, longlat.first] }
  end

  private

    def normalized_coordinates
      return [] unless coordinates.present?

      if geojson.match(/"coordinates"\s*:\s*\[\s*\[\s*\[\s*\[/)
        coordinates.reduce([], :concat).reduce([], :concat)
      elsif geojson.match(/"coordinates"\s*:\s*\[\s*\[\s*\[/)
        coordinates.reduce([], :concat)
      else
        coordinates
      end
    end

    def coordinates
      geojson_data = JSON.parse(geojson) rescue nil
      return [] unless geojson_data.is_a?(Hash) && geojson_data["geometry"].is_a?(Hash)
      
      geojson_data["geometry"]["coordinates"] || []
    end
end
