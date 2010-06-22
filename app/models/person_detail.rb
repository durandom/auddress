class PersonDetail < ActiveRecord::Base
  belongs_to :person

  def self.details_except
    [:id, :person_id, :created_at, :updated_at]
  end

  # we can compare two persons with .same?
  acts_as_comparable :except => details_except
  
  def self.details
    column_names.collect { |n| n.to_sym } - details_except
  end

  def to_txt(with_keys = false)
    if with_keys
      ( self.class.details.collect {|d| "#{d}\t" + self.send(d).to_s}).join("\n")
    else
      ( self.class.details.collect {|d| self.send(d).to_s}).join("\n")
    end
  end

  def checksum
    Digest::MD5.hexdigest(self.to_txt)
  end

  @abstract_class = true
end
