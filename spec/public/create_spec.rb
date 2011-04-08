require 'spec_helper'

with_formats 'xml', 'json' do

  # --------------------------------------------------------------------------

  describe 'Creating a new, valid resource' do
    before(:each) do
      post('books', 201) { @book = Book.gen }
    end

    it 'should persist the resource' do
      Book.create.should be_saved
    end

    it 'should set the key' do
      book = Book.new

      expect { book.save }.should change { book.key }
      book.key.should eql(@book.key)
    end
  end # Creating a new, valid resource

  # --------------------------------------------------------------------------

  describe 'Creating a new resource, when the server returns 422' do
    before(:each) do
      post('books', 422) do
        Book.new.errors.tap do |errors|
          errors.add(:title,  'Title must not be blank')
          errors.add(:author, 'Author must not be blank')
          errors.add(:author, 'Author must not be blue')
        end
      end
    end

    it 'should not raise an error' do
      expect { Book.create }.to_not raise_error
    end

    it 'should not persist the resource' do
      pending("Can't find a way to tell dm-core that the save failed...") do
        Book.create.should_not be_saved
      end
    end

    it 'should not mark the resource as clean' do
      pending("Can't find a way to tell dm-core that the save failed...") do
        Book.create.should be_dirty
      end
    end

    it 'should set single errors' do
      title_errors = Book.create.errors[:title]

      title_errors.should_not be_empty
      title_errors.first.should == 'Title must not be blank'
    end

    it 'should set multiple errors' do
      author_errors = Book.create(:author => 'Tobias Funke').errors[:author]

      author_errors.should_not be_empty
      author_errors.should include('Author must not be blank')
      author_errors.should include('Author must not be blue')
    end
  end # Creating a new resource, when the server returns 422

  # --------------------------------------------------------------------------

end # with_formats 'xml', 'json'
