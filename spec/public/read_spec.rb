require 'spec_helper'

# REQUEST FORMAT (SERVER-SIDE) TESTS =========================================

with_formats 'xml', 'json' do
  describe 'Reading multiple records' do
    before(:each) do
      get('books') { Book.all }
      Book.all.to_a # bang!
    end

    let(:uri) { uri_for('books') }

    it 'should send a GET request to the index action' do
      WebMock.should have_requested(:get, uri)
    end

    it 'should set a Content-Type header' do
      WebMock.should have_requested(:get, uri).with(:headers => {
        'Content-Type' => current_format.headers['Content-Type'] })
    end

    it 'should set an Accept header' do
      WebMock.should have_requested(:get, uri).with(:headers => {
        'Accept' => current_format.headers['Accept'] })
    end
  end

  describe 'Reading single records' do
    before(:each) do
      get('books/1') { Book.gen }
      Book.get(1) # bang!
    end

    let(:uri) { uri_for('books/1') }

    it 'should send a GET request to the show-resource action' do
      WebMock.should have_requested(:get, uri)
    end

    it 'should set a Content-Type header' do
      WebMock.should have_requested(:get, uri).with(:headers => {
        'Content-Type' => current_format.headers['Content-Type'] })
    end

    it 'should set an Accept header' do
      WebMock.should have_requested(:get, uri).with(:headers => {
        'Accept' => current_format.headers['Accept'] })
    end
  end

  # CLIENT-SIDE TESTS --------------------------------------------------------

  describe 'Reading with an unscoped query' do
    context 'which returns no records' do
      before(:each) do
        get('books') { Book.all }
      end

      it 'should return an empty collection' do
        Book.all.should be_empty
      end
    end # which returns no records

    context 'which returns a single record' do
      before(:each) do
        get('books') { @book = Book.gen ; Book.all }
      end

      it 'should return a collection with one Book' do
        Book.all.should have(1).element
      end

      it 'should set the attributes on the Book' do
        Book.all.first.attributes.should eql(@book.attributes)
      end
    end # which returns a single record

    context 'which returns > 1 record' do
      before(:each) do
        get('books') do
          @books = [ Book.gen, Book.gen, Book.gen ]
          Book.all
        end
      end

      it 'should return a collection with all the books' do
        Book.all.should have(3).elements
      end

      it 'should set the attributes on each book' do
        # TODO This relies on the books being returned in the same order as
        # they were created, which likely works only because of Ruby 1.9's
        # ordered hash. Test on 1.8!
        @found = Book.all

        @books.each_with_index do |book, index|
          @found[index].attributes.should eql(book.attributes)
        end
      end
    end # which returns > 1 record
  end # Reading with an unscoped query

  # --------------------------------------------------------------------------

  describe 'Reading with a query scoped by the key' do
    context 'when the resource exists' do
      before(:each) do
        get('books/1') { @book = Book.gen(:id => 1) ; @book }
      end

      it 'should return the record when using all' do
        pending('Adapter should determine that this means books/1') do
          Book.all(:id => 1).should have(1).element
        end
      end

      it 'should return the record when using first' do
        Book.first(:id => 1).should be_a(Book)
      end

      it 'should return when using get' do
        Book.get(1).should be_a(Book)
      end
    end

    context 'when the resource does not exist' do
      before(:each) do
        get('books/1', 404)
      end

      it 'should return an empty collection when using all' do
        # Querying the collection will return 200 OK and an empty collection.
        get('books', 200) { Book.all }
        Book.all(:id => 1).should have(:no).elements
      end

      it 'should return nil when using first' do
        Book.first(:id => 1).should be_nil
      end

      it 'should return nil when using get' do
        Book.get(1).should be_nil
      end

      it 'should raise an error when using get!' do
        expect { Book.get!(1) }.to \
          raise_error(DataMapper::ObjectNotFoundError)
      end
    end # when the resource does not exist
  end # Reading with a query scoped by the key

  # --------------------------------------------------------------------------

  describe 'Reading with a query scoped by a non-key' do
    context 'when the resource exists' do
      before(:all) do
        # In this test, an extra book is generated and returned, simulating a
        # web-service which didn't perform the requested filtering
        # server-side. This allows us to check that DataMapper performs the
        # expected filtering for us. The ?author=... in the URL tests that the
        # adapter sends the parameters to the server, allowing it to perform
        # the filter if it wants to.
        @body = lambda {
          Book.gen
          Book.gen(:author => 'Tobias Funke')
          Book.gen(:author => 'Tobias Funke')
          Book.gen
          Book.all
        }
      end

      it 'should return an array with a both matching records when using all' do
        get('books?author=Tobias+Funke') { @body.call }
        Book.all(:author => 'Tobias Funke').should have(2).elements
      end

      it 'should return a single book when using first' do
        get('books?author=Tobias+Funke&limit=1&offset=0') { @body.call }
        @book = Book.first(:author => 'Tobias Funke')

        @book.should be_a(Book)
        @book.author.should eql('Tobias Funke')
      end
    end # when the resource exists
  end # Reading with a query scoped by a non-key

  # --------------------------------------------------------------------------

  describe 'Reading with a non-standard model storage_name' do
    before(:each) do
      get('books') do
        @books = [ Book.gen, Book.gen, Book.gen ]
        Book.all
      end
    end

    it 'should return a collection with all the books' do
      DifficultBook.all.should have(3).elements
    end

    it 'should set the attributes on each book' do
      # TODO This relies on the books being returned in the same order as they
      # were created, which likely works only because of Ruby 1.9's ordered
      # hash. Test on 1.8!
      @found = DifficultBook.all

      @books.each_with_index do |book, index|
        @found[index].attributes.should eql(book.attributes)
      end
    end
  end # Reading with a non-standard model storage_name

end # with_formats
