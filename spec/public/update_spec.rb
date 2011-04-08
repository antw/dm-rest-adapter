require 'spec_helper'

with_formats 'xml', 'json' do

  # --------------------------------------------------------------------------

  describe 'Updating a resource which is valid' do
    before(:each) do
      # Inital creation of the resource.
      post('books', 201) { @book = Book.gen }

      # Subsequent update.
      put("books/#{@book.id}", 200) { '' }
    end

    let(:book) { Book.gen.tap { |b| b.title = 'New title' } }

    it 'should update the resource' do
      expect { book.save }.to change { book.dirty? }.to(false)
      book.title.should eql('New title')
    end
  end # Creating a new, valid resource

  # --------------------------------------------------------------------------

  describe 'Updating a resource which is not valid' do
    before(:each) do
      # Inital creation of the resource.
      post('books', 201) { @book = Book.gen }

      # Subsequent update.
      put("books/#{@book.id}", 422) do
        Book.new.errors.tap do |errors|
          errors.add(:title,  'Title must not be blank')
          errors.add(:author, 'Author must not be blank')
          errors.add(:author, 'Author must not be blue')
        end
      end
    end

    let(:book) { Book.gen.tap { |b| b.author = 'Tobias Funke' } }

    it 'should not raise an error' do
      expect { book.save }.to_not raise_error
    end

    it 'should not mark the resource as clean' do
      pending("Don't raise an exception when validation fails") do
        book.save.should be_dirty
      end
    end

    it 'should set single errors' do
      book.save
      title_errors = book.errors[:title]

      title_errors.should_not be_empty
      title_errors.first.should eql('Title must not be blank')
    end

    it 'should set multiple errors' do
      book.save
      author_errors = book.errors[:author]

      author_errors.should_not be_empty
      author_errors.should include('Author must not be blank')
      author_errors.should include('Author must not be blue')
    end
  end # Creating a new resource, when the server returns 422

  # --------------------------------------------------------------------------

end # with_formats 'xml', 'json'
