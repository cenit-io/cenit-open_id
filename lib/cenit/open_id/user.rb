module Cenit
  module OpenId

    document_type :User do

      field :email, type: String
      field :name, type: String
      field :given_name, type: String
      field :family_name, type: String
      field :middle_name, type: String
      field :picture_url, type: String

      validates_uniqueness_of :email

    end
  end
end