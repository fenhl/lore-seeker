class FormatECH < FormatStandard
  def format_pretty_name
    "Elder Cockatrice Highlander"
  end

  def include_custom_sets?
    true
  end

  def deck_issues(deck)
    issues = []
    deck.physical_cards.select {|card| card.is_a?(UnknownCard) }.each do |card|
      issues << "Unknown card name: #{card.name}"
    end
    return issues unless issues.empty?
    [
      *deck_size_issues(deck),
      *deck_card_issues(deck),
      *deck_commander_issues(deck),
      *deck_color_identity_issues(deck),
    ]
  end

  def deck_size_issues(deck)
    issues = []
    if deck.number_of_mainboard_cards == 99
      issues << "Mainboard must contain exactly 99 cards, has #{deck.number_of_mainboard_cards}"
    end
    if deck.number_of_sideboard_cards != 1 and deck.number_of_sideboard_cards != 11
      issues << "Deck's sideboard must be exactly 1 card or 11 cards including the commander, has #{deck.number_of_sideboard_cards}"
    end
    issues
  end

  def deck_card_issues(deck)
    issues = []
    deck.card_counts.each do |card, name, count|
      card_legality = legality(card)
      case card_legality
      when "legal", "restricted"
        if count > 1 and not card.allowed_in_any_number?
          issues << "Deck contains #{count} copies of #{name}, only up to 1 allowed"
        end
      when "banned"
        issues << "#{name} is banned"
      when nil
        issues << "#{name} is not in the format"
      when /^banned-/
        issues << "#{name} is not yet implemented in XMage"
      else
        issues << "Unknown legality #{card_legality} for #{name}"
      end
    end
    issues
  end

  def deck_commander_issues(deck)
    commanders = deck.sideboard.select{|card| card.last.commander? }.flat_map{|n,c| [c] * n}
    return ["Commander must be in the sideboard, but none of this deck's sideboard cards are legal commanders"] if commanders.size == 0
    return ["A deck can only have one commander, but this deck has #{commanders.size} (support for legendary creatures in the wishboard coming soon™)"] if commanders.size > 1

    issues = []
    commanders.each do |c|
      if legality(c) == "restricted"
        issues << "#{c.name} is banned as commander"
      end
    end
    issues
  end

  def deck_color_identity_issues(deck)
    commanders = deck.sideboard.select{|card| card.last.commander? }.flat_map{|n,c| [c] * n}
    color_identity = commanders.map{|c| c.color_identity}.inject{|c1, c2| (c1.chars | c2.chars).sort.join } #TODO fix Deck#color_identity and use that here
    return [] unless color_identity
    color_identity = color_identity.chars.to_set
    issues = []
    deck.card_counts.each do |card, name, count|
      card_color_identity = card.color_identity.chars.to_set
      unless card_color_identity <= color_identity
        issues << "Deck has a color identity of #{color_identity_name(color_identity)}, but #{name} has a color identity of #{color_identity_name(card_color_identity)}"
      end
    end
    issues
  end

  def rotation_schedule
    {
      "2018-01-12" => ["ayr", "dms", "ank", "ldo", "tsl", "vln", "jan", "net", "cc18"],
      "2018-01-16" => ["ayr", "dms", "ank", "ldo", "tsl", "vln", "jan", "net", "cc18", "ech"],
      "2018-01-21" => ["ayr", "dms", "ank", "ldo", "tsl", "vln", "jan", "net", "cc18", "ech", "hlw"],
      "2018-08-30" => ["ayr", "dms", "ank", "ldo", "tsl", "vln", "jan", "cc18", "hlw", "vst", "dhm", "rak"],
      "2018-10-25" => ["ayr", "dms", "ank", "ldo", "tsl", "vln", "jan", "cc18", "hlw", "vst", "dhm", "rak", "net"],
      "2019-02-08" => ["ayr", "dms", "ank", "ldo", "tsl", "vln", "jan", "cc18", "hlw", "vst", "dhm", "rak", "net", "eau"],
      "2019-05-29" => ["ayr", "dms", "ank", "ldo", "tsl", "vln", "jan", "cc18", "hlw", "vst", "dhm", "rak", "net", "eau", "sou"]
    }
  end
end
