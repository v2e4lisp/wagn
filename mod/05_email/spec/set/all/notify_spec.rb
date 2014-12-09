# -*- encoding : utf-8 -*-

shared_examples_for 'notifications' do
  describe '#list_of_changes' do
    name = 'subedit notice'
    content = 'new content'
    
    before do
      @card = Card.create!(:name=>name, :content=>content)
    end
    subject { @card.format(:format=>format).render_list_of_changes }
    
    context 'for a new card' do
      it { is_expected.to include "content: #{content}" }
      it { is_expected.to include 'cardtype: Basic' }
    end
    context 'for a updated card' do
      before { @card.update_attributes!(:name=>'bnn card', :type=>:pointer, :content=>'changed content') }
      it { is_expected.to include 'new content: [[changed content]]' }
      it { is_expected.to include 'new cardtype: Pointer' }
      it { is_expected.to include 'new name: bnn card' }
    end
    context 'for a deleted card' do
      before { @card.delete }
      it { is_expected.to be_empty }
    end
    
    context 'for a given action' do
      subject do
        action = @card.last_action
        @card.update_attributes!(:name=>'bnn card', :type=>:pointer, :content=>'changed content')
        @card.format(:format=>format).render_list_of_changes(:action=>action)
      end
      it { is_expected.to include "content: #{content}" }
    end
    context 'for a given action id' do
      subject do
        action_id = @card.last_action.id
        @card.update_attributes!(:name=>'bnn card', :type=>:pointer, :content=>'changed content')
        @card.format(:format=>format).render_list_of_changes(:action_id=>action_id)
      end
      it { is_expected.to include "content: #{content}" }
    end
  end
  
  describe 'subedit_notice' do
    def list_of_changes_for card
      card.db_content
    end
    name = 'subedit notice card'
    content = 'new content'
    before do
      @card = Card.create!(:name=>name, :content=>content)
    end
    subject { @card.format(:format=>format).render_subedit_notice }
    
    context 'for a new card' do
      it { is_expected.to include name }
      it { is_expected.to include 'created' }
      it { is_expected.to include list_of_changes_for @card }
    end
    
    context 'for a updated card' do
      changed_name = 'changed subedit notice'
      changed_content = 'changed content'
      before { @card.update_attributes!(:name=>changed_name, :content=>changed_content) }
      it { is_expected.to include changed_name }
      it { is_expected.to include 'updated' }
      it { is_expected.to include list_of_changes_for @card }
    end
    
    context 'for a deleted card' do
      before { @card.delete } 
      it { is_expected.to include name }
      it { is_expected.to include 'deleted' }
    end
  end
end


describe Card::Set::All::Notify do
  
  describe 'content of notification email' do
    context 'for new card with subcards' do
      name = "another card with subcards"
      content = "main content {{+s1}}  {{+s2}}"
      sub1_content = 'new content of subcard 1'
      sub2_content = 'new content of subcard 2'
      before do
        Card::Auth.as_bot do
          @card = Card.create!(:name=>name, :content=>content,
                               :subcards=>{ '+s1'=>{:content=>sub1_content},
                                            '+s2'=>{:content=>sub2_content} })
        end
      end
      subject { 
        Card[:follower_notification_email].format.render_mail(
          :context   => @card,
          :to        => Card['Joe User'].email,
          :follower  => Card['Joe User'].name, 
          :followed  => @card.name,
        ).text_part.body.raw_source
      }
       
      it { is_expected.to include content }
      it { is_expected.to include sub1_content }
      it { is_expected.to include sub2_content }

      context 'and missing permissions' do
        subject { 
          result = ''
          Card::Auth.current_id = Card['joe user'].id
          Card::Auth.as(:joe_user) do
            result = Card[:follower_notification_email].format.render_mail(
              :context   => @card,
              :to        => Card['Joe User'].email,
              :follower  => Card['Joe User'].name, 
              :followed  => @card.name,
            ).text_part.body.raw_source
          end
          result
        }
        context 'for subcard' do
          before do
            Card.create_or_update! "#{name}+s1+*self+*read",:type=>'Pointer',:content=>'[[Administrator]]'
          end
          it "excludes subcard content" do
            Card::Auth.as(:joe_user) do
              result = Card[:follower_notification_email].format.render_mail(
                :context   => @card,
                :to        => Card['Joe User'].email,
                :follower  => Card['Joe User'].name, 
                :followed  => @card.name,
              ).text_part.body.raw_source
              #is_expected.not_to 
              expect(result).not_to include sub1_content
              is_expected.to include sub2_content
            end
          end
        end
        context 'for main card' do
          before do
            Card.create_or_update! "#{name}+*self+*read",:type=>'Pointer',:content=>'[[Administrator]]'
            Card.create_or_update! "#{name}+s1+*self+*read",:type=>'Pointer',:content=>'[[Anyone]]'
          end
          it 'includes subcard content' do
            Card::Auth.as(:joe_user) do
              is_expected.to include sub1_content
           end
         end
          it "excludes maincard content" do
            Card::Auth.as(:joe_user) do
              is_expected.not_to include content
              is_expected.not_to be_empty
            end
          end
        end
        context 'for all parts' do
          before do
            #Card.create_or_update! "#{name}+s1+*self+*read",:type=>'Pointer',:content=>'[[Administrator]]'
            #Card.create_or_update! "#{name}+s2+*self+*read",:type=>'Pointer',:content=>'[[Administrator]]'
            Card.create_or_update! "s1+*self+*read",:type=>'Pointer',:content=>'[[Administrator]]'
            Card.create_or_update! "s2+*self+*read",:type=>'Pointer',:content=>'[[Administrator]]'
            Card.create_or_update! "#{name}+*self+*read",:type=>'Pointer',:content=>'[[Administrator]]'
          end
          it { is_expected.to be_empty }
        end
      end
    end
  end
  
  
  describe 'html format' do
    include_examples 'notifications' do
      let(:format) { 'email_html' }
    end
  end

  describe 'text format' do
    include_examples 'notifications' do
      let(:format) { 'email_text' }
    end

    it 'creates well formatted text message' do
      name = "another card with subcards"
      content = "main content {{+s1}}  {{+s2}}"
      sub1_content = 'new content of subcard 1'
      sub2_content = 'new content of subcard 2'
      Card::Auth.as_bot do
        @card = Card.create!(:name=>name, :content=>content,
                             :subcards=>{ '+s1'=>{:content=>sub1_content},
                                          '+s2'=>{:content=>sub2_content} })
      end
      result =  Card[:follower_notification_email].format.render_mail(
        :context   => @card,
        :to        => Card['Joe User'].email,
        :follower  => Card['Joe User'].name, 
        :followed  => @card.name,
      ).text_part.body.raw_source
      expect(result).to eq(%{"another card with subcards" was just created by Joe User.

   cardtype: Basic
   content: main content {{+s1}}  {{+s2}}



This update included the following changes:

another card with subcards+s1 created
   cardtype: Basic
   content: new content of subcard 1


another card with subcards+s2 created
   cardtype: Basic
   content: new content of subcard 2




See the card: /another_card_with_subcards

You received this email because you're following "another card with subcards".

Use this link to unfollow /update/Joe_User+*following?drop_item=another_card_with_subcards
})
    end
  end
  

  describe "#notify_followers" do
    def expect_user user_name
      expect(Card.fetch(user_name).account)
    end

    def be_notified
      receive(:send_change_notice)
    end
    
    def be_notified_of card_name
      receive(:send_change_notice).with(kind_of(Card::Act), card_name)
    end
  
    def update card_name, new_content='updated content'
      Card[card_name].update_attributes! :content=>new_content
    end
    
    

    it "sends notifications of edits" do
      expect_user("Big Brother").to be_notified_of "All Eyes On Me+*self"
      update "All Eyes On Me"
    end

    it "does not send notification to author of change" do
      Card::Auth.current_id = Card['Big Brother'].id
      expect_user("Big Brother").not_to be_notified
      update "Google glass"
    end
    
    it "sends only one notification per user"  do
      expect_user("Big Brother").to receive(:send_change_notice).exactly(1)
      update "Google glass"
    end

    it "does not send notification of not-followed cards" do
      expect_user("Big Brother").not_to be_notified
      update "No One Sees Me"
    end
    
    
    
    context "when following *type sets" do
      before do
        Card::Auth.current_id = Card['joe admin'].id
      end
      
      it "sends notifications of new card" do
        new_card = Card.new :name => "Microscope", :type => "Optic"
        expect_user("Optic fan").to be_notified_of "Optic+*type"
        new_card.save!
      end

      it "sends notification of update" do
        expect_user("Optic fan").to be_notified_of "Optic+*type"
        update "Sunglasses"
      end
    end
  
    context 'when following *right sets' do
      it "sends notifications of new card" do
        new_card = Card.new :name=>"Telescope+lens"
        expect_user("Big Brother").to be_notified_of "lens+*right"
        new_card.save!
      end
    
      it "sends notifications of update" do
        expect_user("Big Brother").to be_notified_of "lens+*right"
        update "Magnifier+lens"
      end
    end

    context 'when following "content I created"' do
      it 'sends notifications of update' do
        expect_user('Narcissist').to be_notified_of 'content I created'
        update 'Sunglasses'
      end
    end
    
    context 'when following "content I edited"' do
      it 'sends notifications of update' do
        expect_user('Narcissist').to be_notified_of 'content I edited'
        update 'Magnifier+lens'
      end
    end

    describe "notifications of fields" do
      context "when following ascendant" do
        it "doesn't sends notification of arbitrary subcards" do
          expect_user('Sunglasses fan').not_to be_notified
          Card.create :name=>'Sunglasses+about'
        end
        
        context 'and follow fields rule contains subcards' do
          it 'sends notification of new subcard' do
            new_card = Card.new :name=>'Sunglasses+producer'
            expect_user('Sunglasses fan').to be_notified_of 'Sunglasses'
            new_card.save!
          end
        
          it 'sends notification of updated subcard' do
            expect_user('Sunglasses fan').to be_notified_of 'Sunglasses'
            update 'Sunglasses+price'
          end
        end
    
        context "and follow fields rule contains *include" do
          it "sends notification of new included card" do
            new_card =  Card.new :name=>'Sunglasses+lens'
            expect_user("Sunglasses fan").to be_notified_of "Sunglasses"
            new_card.save!
          end
        
          it "sends notification of updated included card" do
            expect_user("Sunglasses fan").to be_notified_of "Sunglasses+*self"
            update 'Sunglasses+tint'
          end
        
          it "doesn't send notification of not included card" do
            new_card = Card.new :name=>'Sunglasses+lens'
            expect_user("Sunglasses fan").not_to be_notified
            new_card.save!
          end      
        end
    
        context "and follow fields rule doesn't contain *include" do
          it "doesn't send notification of included card" do
            expect_user('Big Brother').not_to be_notified
            update 'Google glass+tint'
          end 
        end
      end
      context 'when following a set' do
        it 'sends notification of included card' do
          expect_user('Optic fan').to be_notified_of 'Sunglasses+*self'
          update 'Sunglasses+tint'
        end
        
        it 'sends notification of subcard mentioned in follow fields rule' do
          expect_user('Optic fan').to be_notified_of 'Optic+*type' 
          update 'Sunglasses+price'
        end
      end
    end
  end
end
