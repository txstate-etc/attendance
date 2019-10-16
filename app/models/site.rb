class Site < ActiveRecord::Base
  attr_accessible :context_id, :context_label, :context_name, :siteroles_attributes, :outcomes_url, :points_url, :checkinsettings_attributes, :gradesettings_attributes

  has_many :memberships, :inverse_of => :site, :dependent => :destroy
  has_many :sections, :inverse_of => :site, :dependent => :destroy
  has_many :siteroles, :inverse_of => :site, :dependent => :destroy
  has_many :roles, :through => :siteroles
  has_many :users, :through => :memberships
  has_one :gradesettings, :inverse_of => :site, :dependent => :destroy
  has_one :checkinsettings, inverse_of: :site, dependent: :destroy

  accepts_nested_attributes_for :siteroles, :gradesettings, :checkinsettings

  before_create :roster_fetched_at_init

  def gradesettings
    super || Gradesettings.find_or_create_by_site_id(id)
  end

  def checkinsettings
    super || Checkinsettings.find_or_create_by_site_id(id)
  end

  def self.from_launch_params(params)
    site = Site.find_or_initialize_by_context_id(params['context_id'])
    site.is_canvas = !params['custom_canvas_course_id'].nil?
    if site.is_canvas
      site.lms_id = params['custom_canvas_course_id']
    else
      do_grade_update = site.outcomes_url.nil? && !params['lis_outcome_service_url'].nil?
      site.outcomes_url = params['lis_outcome_service_url']
    end
    site.assign_attributes(
      context_label: params['context_label'],
      context_name: params['context_title'],
      points_url: params['ext_ims_lti_set_max_points_url']
    )
    site.save
    Gradeupdate.register_site_change(site) if do_grade_update
    site
  end

  def safe_context_name
    context_name.gsub(/\W+/, '_')
  end

  def sections_for_user(auth_user)
    memberships.find_by_user_id(auth_user).recorded_sections
  end

  def default_section
    @default_section ||= sections.find_by_is_default(true)
    if @default_section.nil?
      @default_section = sections.build
      @default_section.name = 'Unassigned'
      @default_section.is_default = true
      @default_section.save
    end
    @default_section
  end

  def roster_fetched_at_init
    self.roster_fetched_at = 5.years.ago
  end

  def roster_fetched_at
    super || 5.years.ago
  end

  def non_empty_sections
    # A section is considered empty if there are no userattendances to display and no active recorded memberships in the section.
    @nonemptysections ||= sections.reject { |section| section.userattendances.empty? && !section.recorded_memberships.find {|m| m.active} }
  end

  def getSectionsFromString(sections)
    sections.split(/(?<!\/)\+|,/).map(&:strip).map { |sectionstring| self.sections.find_or_create_by_name(sectionstring.gsub('/+', '+')) }.uniq rescue []
  end

  # Auto max points can only be determined from 1 section. Sites with multiple sections (not including unassigned section) can't use
  # the auto max points feature.
  def max_points_section
    return sections.first if sections.length == 1
    assigned_sections = sections.reject{|s| s.name == "Unassigned"}
    return nil if assigned_sections.count > 1
    return assigned_sections.first
  end

  def assignment_id
    if @assignmentid.nil?
      assignments = Canvas.get("/v1/courses/#{self.lms_id}/assignments")
      assignments.each do |assignment|
        if !assignment[:external_tool_tag_attributes].nil? &&
           !assignment[:external_tool_tag_attributes][:url] &&
           assignment[:external_tool_tag_attributes][:url].include?(ENV["WEB_HOSTNAME"])
          @assignmentid = assignment[:id]
        end
      end
    end
    @assignmentid
  end
end
