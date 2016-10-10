class Place
  include Mongoid::Document

  attr_accessor :id, :location, :formatted_address, :address_components

  def initialize(params)
    @id = params[:_id].to_s
    @formatted_address = params[:formatted_address]
    @location = Point.new(params[:geometry][:location])
    @address_components = parse_address(params[:address_components])
  end

  def self.load_all(file)
    content = file.read.gsub("\n","")
    json = JSON.parse(content)
    collection.insert_many(json)
  end

  def self.find_by_short_name(query)
    collection.find("address_components.short_name" => query)
  end

  def self.to_places(docs)
    docs.map do |doc|
      Place.new(doc)
    end
  end

  def self.find(id)
    doc = find_docs(id).first
    return nil if doc.blank?
    self.new(doc)
  rescue
    nil
  end

  def self.all(offset=0, limit=nil)
    docs = collection.find.skip(offset)
    docs = docs.limit(limit) if limit.present?
    to_places(docs)
  end

  def destroy
    self.class.find_docs(id).delete_one
  end

  def selfget_address_components(sort={}, offset=0, limit=nil)
    collectionn.find.aggregate([
      :$project => { address_components: 1, formatted_address: 1, "geometry.geolocation" => 1 },
    ])
  end

  private

  def self.find_docs(id)
    bson_id = BSON::ObjectId.from_string(id)
    collection.find(_id: bson_id)
  end

  def parse_address(addresses)
    addresses.map do |address|
      AddressComponent.new(address)
    end
  end
end
