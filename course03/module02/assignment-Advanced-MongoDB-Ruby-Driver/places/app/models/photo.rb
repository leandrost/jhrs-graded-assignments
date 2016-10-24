class Photo
  include Mongoid::Document

  attr_accessor :id, :location
  attr_writer :contents

  def initialize(args={})
    args = args.with_indifferent_access
    @id = args[:_id].to_s
    if args[:metadata].present?
      @location = Point.new(args[:metadata][:location]) if has_location?(args)
      @place = args[:metadata][:place]
    end
  end

  def persisted?
    @id.present?
  end

  def save
    if persisted?
      update
    else
      create
    end
  end

  def self.all(offset=0, limit=nil)
    docs = mongo_client.database.fs.find.skip(offset)
    docs = docs.limit(limit) if !limit.nil?
    docs.map { |doc| new(doc) }
  end

  def self.find(id)
    doc = find_file(id).first
    return if doc.blank?
    new(doc)
  end

  def contents
    doc = self.class.fs.find_one(_id: bson_id)
    return if doc.blank?
    buffer = ""
    doc.chunks.reduce([]) do |x, chunk|
      buffer << chunk.data.data
    end
    buffer
  end

  def destroy
    self.class.find_file(id).delete_one
  end

  def find_nearest_place_id(max_distance)
    place = Place.near(@location, max_distance)
      .limit(1)
      .projection(:_id => 1)
      .first

    return place.nil? ? nil : place[:_id]
  end

  def place
    return if @place.blank?
    Place.find(@place.to_s)
  end

  def place=(place)
    if place.class == Place
      @place = BSON::ObjectId.from_string(place.id)
    elsif place.class == String
      @place = BSON::ObjectId.from_string(place)
    else
      @place = place
    end
  end

  def self.find_photos_for_place(place_id)
    place_id = BSON::ObjectId.from_string(place_id.to_s)
    mongo_client.database.fs.find(:'metadata.place' => place_id)
  end

  private

  def bson_id
    BSON::ObjectId(id)
  end

  def self.fs
    mongo_client.database.fs
  end

  def self.find_file(id)
    bson_id = BSON::ObjectId(id)
    fs.find(_id: bson_id)
  end

  def create
    return if @contents.blank?
    gps = EXIFR::JPEG.new(@contents).gps
    @location = Point.new(lng: gps.longitude, lat: gps.latitude)
    @contents.rewind
    grid_file = Mongo::Grid::File.new(@contents.read, description)
    id = self.class.fs.insert_one(grid_file)
    @id = id.to_s
  end

  def update
    self.class.find_file(id).update_one(
      "$set": {
        metadata: { location: @location.to_hash, place: @place }
      }
    )
  end

  def description
    {
      content_type: "image/jpeg",
      metadata: { location: location.to_hash, place: place }
    }
  end

  def has_location?(args)
    args[:metadata].has_key?(:location)
  end
end
