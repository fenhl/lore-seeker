require "damerau-levenshtein"

class SpellingSuggestions
  def initialize
    @words = Set[]
  end

  def <<(text)
    normalize_text(text).scan(/\w+/).each do |word|
      @words << normalize_text(word) if word.size >= 2
    end
  end

  def suggest(query)
    # If "Rancor" is already in DB, do not suggest "Ranger" no matter what
    return [] if @words.include?(query)
    query = normalize_text(query)
    return [] if @words.include?(query)

    if query.size <= 2
      max_distance = 0
    elsif query.size <= 4
      max_distance = 1
    else
      max_distance = 2
    end

    results_multipart = []
    # Try only words at least 2 characters
    # There are silly things like en-Dal
    (2..query.size-2).each do |i|
      a, b = query[0...i], query[i..-1]
      if @words.include?(a) and @words.include?(b)
        results_multipart << "#{a} #{b}"
      end
    end

    return results_multipart.sort unless results_multipart.empty?

    results_typo = (0...max_distance).map{ [] }
    @words.each do |word|
      d = DamerauLevenshtein.distance(word, query)
      results_typo[d-1] << word if d <= max_distance
    end

    results_typo.each do |r|
      return r.sort unless r.empty?
    end

    []
  end

  private

  def normalize_text(text)
    text.downcase.gsub(/[Ææ]/, "ae").tr("Äàáâäèéêíõöúûü’\u2212", "Aaaaaeeeioouuu'-").gsub(/'s\b/, "").strip
  end
end
