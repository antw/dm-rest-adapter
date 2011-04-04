require 'spec_helper'

# ----------------------------------------------------------------------------

describe 'Updating a resource which is valid' do
  before(:each) do
    # Inital creation of the resource.
    post('books.xml', 201) { (@book = Book.gen).to_xml }

    # Subequent update.
    put("books/#{@book.id}.xml", 200) { '' }
  end

  let(:book) { Book.gen.tap { |b| b.title = 'New title' } }

  it 'should update the resource' do
    expect { book.save }.to change { book.dirty? }.to(false)
    book.title.should eql('New title')
  end
end # Creating a new, valid resource

# ----------------------------------------------------------------------------

describe 'Updating a resource which is not valid' do
  before(:each) do
    # Inital creation of the resource.
    post('books.xml', 201) { (@book = Book.gen).to_xml }

    # Subequent update.
    put("books/#{@book.id}.xml", 422) do
      Book.new.errors.tap do |errors|
        errors.add(:title,  'Title must not blank')
        errors.add(:author, 'Author must not be blank')
        errors.add(:author, 'Author must not be blue')
      end.to_xml
    end
  end

  let(:book) { Book.gen.tap { |b| b.title = 'New title' } }

  it 'should not raise an error' do
    pending("Don't raise an exception when validation fails") do
      expect { book.save }.to_not raise_error
    end
  end

  it 'should not persist the resource' do
    pending("Don't raise an exception when validation fails") do
      book.save.should_not be_saved
    end
  end

  it 'should set single errors' do
    pending("Don't raise an exception when validation fails") do
      title_errors = book.save.errors[:title]

      title_errors.should_not be_empty
      title_errors.first.should eql('Title may not be blank')
    end
  end

  it 'should set multiple errors' do
    pending("Don't raise an exception when validation fails") do
      author_errors = book.save(:author => 'Tobias Funke').errors[:author]

      author_errors.should_not be_empty
      author_errors.should include('Author must not be blank')
      author_errors.should include('Author must not be blue')
    end
  end
end # Creating a new resource, when the server returns 422
