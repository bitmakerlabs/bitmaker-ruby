module Bitmaker
  class InquirySerializer < BaseSerializer
    attributes *Bitmaker::Inquiry::ATTRIBUTES

    has_one :lead, include_data: true, include_links: false
  end
end
