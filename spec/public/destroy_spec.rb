require 'spec_helper'

with_formats 'xml', 'json' do

  # --------------------------------------------------------------------------

  describe 'Deleting a resource with no errors' do
    before(:each) do
      # Inital creation of the resource.
      post('books', 201) { @book = Book.gen }

      # Subsequent delete.
      delete("books/#{@book.id}", 200) { '' }
    end

    let(:book) { Book.gen }

    it 'should destroy the resource' do
      expect { book.destroy }.to change { book.saved? }.from(true).to(false)
    end

    it 'should have no errors' do
      book.destroy
      book.errors.should be_empty
    end
  end # Deleting a resource with no errors

  # --------------------------------------------------------------------------

  describe 'Deleting a resource which is not valid' do
    # A resource may perform validation prior to deleting the resource, so we
    # need to handle those in the same way as handing failing updates.
    before(:each) do
      # Inital creation of the resource.
      post('books', 201) { @book = Book.gen }

      # Subsequent delete.
      delete("books/#{@book.id}", 422) do
        Book.new.errors.tap do |errors|
          errors.add(:title,  'Title must not blank')
          errors.add(:author, 'Author must not be blank')
          errors.add(:author, 'Author must not be blue')
        end
      end
    end

    let(:book) { Book.gen }

    it 'should not raise an error' do
      pending("Don't raise an exception when validation fails") do
        expect { book.destroy }.to_not raise_error
      end
    end

    it 'should not destroy the resource' do
      pending("Don't raise an exception when validation fails") do
        expect { book.destroy }.to_not change { book.saved? }
      end
    end

    it 'should set single errors' do
      pending("Don't raise an exception when validation fails") do
        book.destroy

        title_errors = book.errors[:title]

        title_errors.should_not be_empty
        title_errors.first.should eql('Title may not be blank')
      end
    end

    it 'should set multiple errors' do
      pending("Don't raise an exception when validation fails") do
        book.destroy
        author_errors = book.errors[:author]

        author_errors.should_not be_empty
        author_errors.should include('Author must not be blank')
        author_errors.should include('Author must not be blue')
      end
    end
  end # Deleting a resource which is not valid

  # --------------------------------------------------------------------------

end # with_formats 'xml', 'json'
