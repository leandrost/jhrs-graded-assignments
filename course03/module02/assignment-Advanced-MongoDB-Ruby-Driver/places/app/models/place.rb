class Place
  include ActiveModel::Model
  include Mongoid::Document

  attr_accessor :id, :location, :formatted_address, :address_components

  def initialize(params={})
    @id = params[:_id].to_s
    @formatted_address = params[:formatted_address]
    @location = Point.new(params[:geometry][:geolocation])
    @address_components = parse_address(params[:address_components])
  end

  def destroy
    self.class.find_docs(id).delete_one
  end

  def near(max_meters=nil)
    docs = self.class.near(location, max_meters)
    self.class.to_places(docs)
  end

  def photos(offset=0, limit=nil)
    result = []
    photos = Photo.find_photos_for_place(@id).skip(offset)
    photos = photos.limit(limit) if limit.present?
    photos.map do |photo|
      result << Photo.new(photo)
    end
    return result
  end

  def persisted?
    !@id.nil?
  end

  class << self
    def load_all(file)
      content = file.read.gsub("\n","")
      json = JSON.parse(content)
      collection.insert_many(json)
    end

    def find_by_short_name(query)
      collection.find("address_components.short_name" => query)
    end

    def to_places(docs)
      docs.map do |doc|
        Place.new(doc)
      end
    end

    def find(id)
      doc = find_docs(id).first
      return nil if doc.blank?
      new(doc)
    rescue
      nil
    end

    def all(offset=0, limit=nil)
      docs = collection.find.skip(offset)
      docs = docs.limit(limit) if limit.present?
      to_places(docs)
    end

    def get_address_components(sort=nil, offset=nil, limit=nil)
      filters = [
        {
          :$project => {
            address_components: 1,
            formatted_address: 1,
            "geometry.geolocation" => 1
          }
        },
        { :$unwind => "$address_components" },
      ]
      filters << { :$sort => sort } if sort.present?
      filters << { :$skip => offset } if limit.present?
      filters << { :$limit => limit } if limit.present?
      collection.find.aggregate(filters)
    end

    def get_country_names
      filters = [
        {
          :$project => {
            _id: 0,
            "address_components.long_name": 1,
            "address_components.types": 1
          }
        },
        { :$unwind => "$address_components" },
        { :$match => { "address_components.types": "country" } },
        { :$group => { _id: "$address_components.long_name" } }
      ]
      collection.find.aggregate(filters).to_a.map { |doc| doc[:_id] }
    end

    def find_ids_by_country_code(country_code)
      filters = [
        {
          :$match => {
            "address_components.types": "country",
            "address_components.short_name": country_code,
          },
        },
        { :$project => { _id: 1 } },
      ]
      collection.find.aggregate(filters).to_a.map { |doc| doc[:_id].to_s }
    end

    def create_indexes
      collection.indexes.create_one(
        "geometry.geolocation": Mongo::Index::GEO2DSPHERE
      )
    end

    def remove_indexes
      collection.indexes.drop_all
    end

    def near(point, max_meters=nil)
      collection.find("geometry.geolocation": {
        "$near": {
          "$geometry": point.to_hash,
          "$maxDistance": max_meters,
        }
      })
    end

    def find_docs(id)
      bson_id = BSON::ObjectId.from_string(id)
      collection.find(_id: bson_id)
    end
  end

  private

  def parse_address(addresses)
    return if addresses.blank?
    addresses.map do |address|
      AddressComponent.new(address)
    end
  end
end
