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
  end # Deleting a resource with no errors

  # --------------------------------------------------------------------------

  describe 'Deleting a resource when the server returns 422' do
    before(:each) do
      # Inital creation of the resource.
      post('books', 201) { @book = Book.gen }

      # Subsequent delete.
      delete("books/#{@book.id}", 422) { '' }
    end

    let(:book) { Book.gen }

    it 'should not destroy the resource' do
      pending("Can't find a way to tell dm-core that the destroy failed...") do
        expect { book.destroy }.to_not change { book.saved? }
      end
    end
  end # Deleting a resource when the server returns 422

  # --------------------------------------------------------------------------

end # with_formats 'xml', 'json'
