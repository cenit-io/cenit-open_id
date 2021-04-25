module Cenit
  module OpenId

    document_type :Code do

      field :value, type: String
      field :span, type: Integer, default: 3600
      field :metadata, type: Hash, default: {}

      validates_numericality_of :span, greater_than_or_equal_to: 1

      before_save :generate_code_token

      def generate_code_token
        self.value = id.to_s + '-' + Devise.friendly_token if value.blank?
      end

      def active?
        (created_at + span) > Time.now
      end
    end
  end
end