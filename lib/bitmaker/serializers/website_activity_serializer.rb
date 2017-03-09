module Bitmaker
  class InquirySerializer < BaseSerializer
    attributes  :inquiry_type,
                :questions,
                :bitmaker_reason,
                :course_reason,
                :current_occupation,
                :course_name,
                :unbounce_campaign,
                :utm,
                :basecrm_resource_id,
                :basecrm_resource_type

    has_one :lead, include_data: true, include_links: false
  end
end
