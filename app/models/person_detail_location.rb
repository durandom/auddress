module PersonDetailLocation
  def location=(loc)
    loc.downcase! if loc
    loc = locations.include?(loc) ? loc : default_location
    write_attribute(:location, loc)
  end

  def default_location
    'home'
  end

  def locations
    ['work', 'home']
  end
end
