def new_card?
  new_record? || !!@from_trash
end
alias_method :new?, :new_card?

def known?
  real? || virtual?
end

def real?
  !new_card?
end

def unknown?
  !known?
end

def pristine?
  # has not been edited directly by human users.  bleep blorp.
  new_card? or !actions.joins(:act).where('card_acts.actor_id != ?', Card::WagnBotID).exists?
end
