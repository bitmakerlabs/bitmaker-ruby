module Bitmaker
  class Inquiry < Model
    attr_reader :lead

    ATTRIBUTES = [:inquiry_type,
                  :questions,
                  :bitmaker_reason,
                  :course_reason,
                  :current_occupation,
                  :course_name,
                  :course_code,
                  :cohort_start_date,
                  :unbounce_campaign,
                  :utm,
                  :basecrm_resource_id,
                  :basecrm_resource_type]

    def initialize(attributes)
      super(attributes)
      @lead = Lead.new(attributes)
    end

    def resource_path
      'activities/inquiries'
    end

    def serialize(included_models: [])
      super(included_models: (included_models << 'lead').uniq)
    end
  end
end
