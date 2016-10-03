class Racer
  include Mongoid::Document
  include ActiveModel::Model
  include Mongoid::Attributes::Dynamic

  field :number, type: Integer
  field :first_name, type: String
  field :last_name, type: String
  field :gender, type: String
  field :group, type: String
  field :secs, type: Integer

  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs

  def initialize(params={})
    @id=params[:_id].nil? ? params[:id] : params[:_id].to_s
    @first_name=params[:first_name]
    @number=params[:number].to_i
    @first_name=params[:first_name]
    @last_name=params[:last_name]
    @gender=params[:gender]
    @group=params[:group]
    @secs=params[:secs].to_i
    super(params)
  end

  def self.all(prototype={}, sort={}, skip=0, limit=nil)
    docs = collection.find(prototype)
    docs = docs.sort(sort) if sort.present?
    docs = docs.skip(skip) if skip.present?
    docs = docs.limit(limit) if limit.present?
    docs
  end

  def self.find(id)
    bson_id = BSON::ObjectId.from_string(id)
    result = collection.find(_id: bson_id).first
    return nil if result.blank?
    self.new(result)
  rescue
    nil
  end

  def save
    attrs = {
      number: number,
      first_name: first_name,
      last_name: last_name,
      gender: gender,
      group: group,
      secs: secs,
    }
    result = collection.insert_one(attrs)
    @id = result.inserted_id
  end

  def update(attrs)
    attrs = {
      number: attrs[:number],
      first_name: attrs[:first_name],
      last_name: attrs[:last_name],
      gender: attrs[:gender],
      group: attrs[:group],
      secs: attrs[:secs],
    }
    assign_attributes(attrs)
    collection.find(_id: _id).update_one(attrs)
  end

  def destroy
    collection.find(_id: _id).delete_one
  end

  def persisted?
    @id.present?
  end

  def created_at
    nil
  end

  def updated_at
    nil
  end

  def self.paginate(params)
    page=(params[:page] || 1).to_i
    limit=(params[:per_page] || 30).to_i
    skip = (page-1) * limit
    racers=[]
    all({}, {}, skip, limit).each do |doc|
      racers << Racer.new(doc)
    end
    total=all({}, {}, 0, 1).count
    WillPaginate::Collection.create(page, limit, total) do |pager|
      pager.replace(racers)
    end
  end
end
