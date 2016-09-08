class Profile < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :first_name, if: "last_name.blank?"
  validates_presence_of :last_name, if: "first_name.blank?"

  validates_inclusion_of :gender, in: ["male", "female"]
  validates_exclusion_of :first_name, in: ["Sue"]

  def self.get_all_profiles(starts, ends)
    where(birth_year: starts..ends).order(:birth_year)
  end
end
