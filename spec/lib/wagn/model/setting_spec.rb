require File.expand_path('../../../spec_helper', File.dirname(__FILE__))

describe Card do

  context 'when there is a general toc setting of 2' do
     
    before do
      (@c1 = Card['Onne Heading']).should be
      (@c2 = Card['Twwo Heading']).should be
      (@c3 = Card['Three Heading']).should be
      @c1.type_id.should == Card::BasicID
      (@rule_card = @c1.rule_card('*table of contents')).should be
    end

    describe ".rule" do
      it "should have a value of 2" do
        @rule_card.content.should == "2"
        @c1.rule(:table_of_contents).should == "2"
      end
    end

    describe "renders with/without toc" do
      it "should not render for 'Onne Heading'" do
        Wagn::Renderer.new(@c1).render.should_not match /Table of Contents/
      end
      it "should render for 'Twwo Heading'" do
        Wagn::Renderer.new(@c2).render.should match /Table of Contents/
      end
      it "should render for 'Three Heading'" do
        Wagn::Renderer.new(@c3).render.should match /Table of Contents/
      end
    end

    describe ".rule_card" do
      it "get the same card without the * and singular" do
        @c1.rule_card(:table_of_content).should == @rule_card
      end
    end

    describe ".related_sets" do
    end

    # class methods
    describe ".default_rule" do
      Card.default_rule(:table_of_content).should == '0'
    end

    describe ".default_rule_card" do
    end

    describe ".universal_setting_names_by_group" do
    end

    describe ".setting_attrib" do
    end

  end

  context "when I change the general toc setting to 1" do
     
    before do
      (@c1 = Card["Onne Heading"]).should be
      (@c2 = Card["Twwo Heading"]).should be
      @c1.type_id.should == Card::BasicID
      (@rule_card = @c1.rule_card("*table_of_contents")).should be
      @rule_card.content = "1"
    end

    describe ".rule" do
      it "should have a value of 1" do
        @rule_card.content.should == "1"
        @c1.rule(:table_of_contents).should == "1"
      end
    end

    describe "renders with/without toc" do
      it "should not render toc for 'Onne Heading'" do
        Wagn::Renderer.new(@c1).render.should match /Table of Contents/
      end
      it "should render toc for 'Twwo Heading'" do
        Wagn::Renderer.new(@c2).render.should match /Table of Contents/
      end
      it "should not render for 'Twwo Heading' when changed to 3" do
        @rule_card.content = "3"
        Wagn::Renderer.new(@c2).render.should_not match /Table of Contents/
      end
    end

  end

  context 'when I use CardtypeE cards' do
     
    before do
      @c1 = Card.create :name=>'toc1', :type=>"CardtypeE",
        :content=>Card['Onne Heading'].content
      @c2 = Card.create :name=>'toc2', :type=>"CardtypeE",
        :content=>Card['Twwo Heading'].content
      @c3 = Card.create :name=>'toc3', :type=>"CardtypeE",
        :content=>Card['Three Heading'].content
      @c1.typename.should == 'Cardtype E'
      @rule_card = @c1.rule_card('*table of contents')

      @c1.should be
      @c2.should be
      @c3.should be
      @rule_card.should be
    end

    describe ".rule" do
      it "should have a value of 0" do
        @c1.rule(:table_of_contents).should == "0"
        @rule_card.content.should == "0"
      end
    end

    describe "renders without toc" do
      it "should not render for 'Onne Heading'" do
        Wagn::Renderer.new(@c1).render.should_not match /Table of Contents/
      end
      it "should render for 'Twwo Heading'" do
        Wagn::Renderer.new(@c2).render.should_not match /Table of Contents/
      end
      it "should render for 'Three Heading'" do
        Wagn::Renderer.new(@c3).render.should_not match /Table of Contents/
      end
    end

    describe ".rule_card" do
      it "doesn't have a type rule" do
        @rule_card.should be
        @rule_card.name.should == "*all+*table of content"
      end

      it "get the same card without the * and singular" do
        @c1.rule_card(:table_of_content).should == @rule_card
      end
    end

    describe ".related_sets" do
    end

    # class methods
    describe ".default_rule" do
      Card.default_rule(:table_of_content).should == '0'
    end

    describe ".default_rule_card" do
    end

    describe ".universal_setting_names_by_group" do
    end

    describe ".setting_attrib" do
    end

    context "when I create a new rule" do
      before do
        Card.create :name=>'CardtypeE+*type+*table of content', :content=>'2'
      end
      it "should take on new setting value" do
        @c1.rule(:table_of_contents).should == "2"
      end

      describe "renders with/without toc" do
        Card.as :joe_admin do
          Card.create :name=>'CardtypeE+*type+*table of content', :content=>'2'
        end

        #@c1.rule_card(:table_of_content).should_not == @rule_card

        it "should not render for 'Onne Heading'" do
          Wagn::Renderer.new(@c1).render.should_not match /Table of Contents/
        end
        it "should render for 'Twwo Heading'" do
          Wagn::Renderer.new(@c2).render.should match /Table of Contents/
        end
        it "should render for 'Three Heading'" do
          Wagn::Renderer.new(@c3).render.should match /Table of Contents/
        end
      end
    end

  end

  context "when I change the general toc setting to 1" do
     
    before do
      (@c1 = Card["Onne Heading"]).should be
      (@c2 = Card["Twwo Heading"]).should be
      @c1.type_id.should == Card::BasicID
      (@rule_card = @c1.rule_card("*table_of_contents")).should be
      @rule_card.content = "1"
    end

    describe ".rule" do
      it "should have a value of 1" do
        @rule_card.content.should == "1"
        @c1.rule(:table_of_contents).should == "1"
      end
    end

    describe "renders with/without toc" do
      it "should not render toc for 'Onne Heading'" do
        Wagn::Renderer.new(@c1).render.should match /Table of Contents/
      end
      it "should render toc for 'Twwo Heading'" do
        Wagn::Renderer.new(@c2).render.should match /Table of Contents/
      end
      it "should not render for 'Twwo Heading' when changed to 3" do
        @rule_card.content = "3"
        Wagn::Renderer.new(@c2).render.should_not match /Table of Contents/
      end
    end

  end
end

