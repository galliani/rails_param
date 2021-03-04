require 'fixtures/controllers'
require 'rspec/rails'

describe FakeController, type: :controller do
  # Needed to run tests against Rails 4 AND 5
  def prepare_params(params)
    return params if Rails.version[0].to_i <= 4
    { params: params }
  end

  describe "type coercion" do
    it "coerces to integer" do
      get :index, prepare_params(exclusive_1: 100, page: "666")

      expect(controller.params[:page]).to eql(666)
    end

    it "raises InvalidParameterError if supplied an array instead of other type (prevent TypeError)" do
      expect { get :index, prepare_params(exclusive_1: 100, page: ["a", "b", "c"]) }.to raise_error(
        RailsParam::Param::InvalidParameterError, %q('["a", "b", "c"]' is not a valid Integer))
    end

    it "raises InvalidParameterError if supplied an hash instead of other type (prevent TypeError)" do
      expect { get :index, prepare_params(exclusive_1: 100, page: {"a" => "b", "c" => "d"}) }.to raise_error(
        RailsParam::Param::InvalidParameterError, %q('{"a"=>"b", "c"=>"d"}' is not a valid Integer))
    end

    it "raises InvalidParameterError if supplied an hash instead of an array (prevent NoMethodError)" do
      expect { get :index, prepare_params(exclusive_1: 100, tags: {"a" => "b", "c" => "d"}) }.to raise_error(
        RailsParam::Param::InvalidParameterError, %q('{"a"=>"b", "c"=>"d"}' is not a valid Array))
    end
  end

  describe '#any_of!' do
    context 'if supplied multiple of specified params' do
      it 'raises InvalidParameterError' do
        expect { get :index, prepare_params(exclusive_1: 100, exclusive_2: 200) }.to raise_error(
          RailsParam::Param::InvalidParameterError, 'Parameters exclusive_1, exclusive_2 are mutually exclusive')
      end
    end

    context 'if supplied NONE of specified params' do
      it 'raises InvalidParameterError' do
        expect { get :index, prepare_params({}) }.to raise_error(
          RailsParam::Param::InvalidParameterError, 'At least one of these parameters need to be present: exclusive_1, exclusive_2')
      end
    end

    context 'if supplied with exactly ONE of specified params' do
      it 'SHOULD NOT raise InvalidParameterError' do
        expect { get :index, prepare_params(exclusive_1: 100) }.to_not raise_error(RailsParam::Param::InvalidParameterError)
      end
    end
  end

  describe "nested_hash" do
    it "validates nested properties" do
      params = {
        'book' => {
          'title' => 'One Hundred Years of Solitude',
          'author' => {
            'first_name' => 'Garbriel Garcia',
            'last_name' => 'Marquez',
            'age' => '70'
          },
          'price' => '$1,000.00'
        }}
      get :edit, prepare_params(params)
      expect(controller.params[:book][:author][:age]).to eql 70
      expect(controller.params[:book][:author][:age]).to be_kind_of Integer
      expect(controller.params[:book][:price]).to eql 1000.0
      expect(controller.params[:book][:price]).to be_instance_of BigDecimal
    end

    it "raises error when required nested attribute missing" do
      params = {
        'book' => {
          'title' => 'One Hundred Years of Solitude',
          'author' => {
            'last_name' => 'Marquez',
            'age' => '70'
          },
          'price' => '$1,000.00'
        }}
      expect { get :edit, prepare_params(params) }.to raise_error { |error|
        expect(error).to be_a(RailsParam::Param::InvalidParameterError)
        expect(error.param).to eql("first_name")
        expect(error.options).to eql({:required => true})
      }
    end

    it "passes when hash that's not required but has required attributes is missing" do
      params = {
        'book' => {
          'title' => 'One Hundred Years of Solitude',
          'price' => '$1,000.00'
        }}
      get :edit, prepare_params(params)
      expect(controller.params[:book][:price]).to eql 1000.0
      expect(controller.params[:book][:price]).to be_instance_of BigDecimal
    end
  end

  describe "InvalidParameterError" do
    it "raises an exception with params attributes" do
      expect { get :index, prepare_params(exclusive_1: 100, sort: "foo") }.to raise_error { |error|
        expect(error).to be_a(RailsParam::Param::InvalidParameterError)
        expect(error.param).to eql("sort")
        expect(error.options).to eql({:in => ["asc", "desc"], :default => "asc", :transform => :downcase})
      }
    end
  end

  describe ":transform parameter" do
    it "applies transformations" do
      get :index, prepare_params(exclusive_1: 100, sort: "ASC")

      expect(controller.params[:sort]).to eql("asc")
    end
  end

  describe "default values" do
    it "applies default values" do
      get :index, prepare_params(exclusive_1: 100, sort: "ASC")

      expect(controller.params[:page]).to eql(1)
      expect(controller.params[:sort]).to eql("asc")
    end
  end
end
