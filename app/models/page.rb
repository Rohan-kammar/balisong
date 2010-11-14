# This is the model class that represents all pages, including blog posts.
# It is not an ActiveRecord model, it stores it's data in files.
class Page 
  include GitModel::Persistable

  attribute :title
  attribute :categories, :default => []
  attribute :allow_comments, :default => true
  attribute :include_in_site_menu, :default => false
  attribute :include_in_feed, :default => true

  def date
    if id =~ /(\d{4}-\d{2}-\d{2})-.+/
      return Date.parse($1)
    else
      return nil
    end
  end

  # Determine the name of the main part
  def main_part
    # TODO iterate over blobs here instead of using filesystem
    maybes = blobs.keys.keep_if{|k| k =~ /^main/}

    return maybes.any? ? File.basename(maybes.first) : nil
  end

  # return all Page objects that have the given category in the categories array
  def self.in_category(category)
    results = []
    find_all.each do |o|
      results << o if o.categories.include?(category)
    end
    return results
  end

  # return all Page objects that have a date that matches the given date range.
  # A date range is a string that matches 'YYYY/MM/DD' or 'YYYY/MM' or just
  # 'YYYY'
  def self.in_date_range(date_range)
    year, month, day = date_range.split('/').map{|el| el.to_i}

    results = []
    find_all.each do |o|
      if o.date && year == o.date.year && (month.nil? || month == o.date.month) && (day.nil? || day == o.date.day)
        results << o
      end
    end
    return results
  end

  def self.all_categories
    categories = []
    find_all.each {|page| categories += page.categories}
    return categories.uniq.sort
  end

  # convert an id to the format with slashes that's used in url's
  def self.urlify(id)
    if id =~ /(\d{4})-(\d{2})-(\d{2})-(.+)/
      return "#{$1}/#{$2}/#{$3}/#{$4}"
    else
      return id
    end
  end

  # convert an id from the format with slashes that's used in url's
  def self.de_urlify(id)
    if id =~ /(\d{4})\/(\d{2})\/(\d{2})\/(.+)/
      return "#{$1}-#{$2}-#{$3}-#{$4}"
    else
      return id
    end
  end

  # Determine the type of a part based on the name, returning a normalized
  # canonical type name in lower case. 
  # Examples:
  #   "foo.md" -> "markdown"
  #   "bar.htm -> "html"
  #   "baz.HTML -> "html"
  def self.type(name)
    return nil unless name && File.extname(name) =~ /\.(.*)/
    
    type = $1.downcase

    # return the canonical type name if it's an abbreviation:
    case type
    when "md"
      type = "markdown"
    when "htm"
      type = "html"
    when "rb"
      type = "ruby"
    end

    return type
  end

end
