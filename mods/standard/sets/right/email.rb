#event :
include Card::Set::All::Permissions::Accounts

view :raw do |args|
  
  case
  when card.real?          ; card.content
  when card.left.account   ; card.left.account.email #this supports legacy behavior (should be moved to User+*email+*type plus right)
  else ''
  end
end

view :core, :raw

event :validate_email, :after=>:approve, :on=>:save do
  if content !~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
    errors.add :email, 'must be valid address'
  end
end

event :validate_unique_email, :after=>:validate_email, :on=>:save do
  Account.as_bot do
    wql = { :right_id=>Card::EmailID, :eq=>content }
    wql[:not] = { :id => id } if id
    if Card.search( wql ).first
      errors.add :email, 'must be unique'
    end
  end
end

event :downcase_email, :before=>:approve, :on=>:save do
  if content and content != content.downcase
    self.content = content.downcase
  end
end

def email_required?
  !built_in?
end

def ok_to_read
  if is_own_account? or Account.always_ok?
    true
  else
    deny_because "viewing email is restricted to administrators and account holders"
  end
end

def is_own_account?
  cardname.parts[0].to_name.key == Account.as_card.cardname.key
end