require 'libxml'
require 'json'

class Gradeupdate < ActiveRecord::Base
  belongs_to :membership
  attr_accessible :tries, :last_error

  # At some point, we should stop retrying failed updates so they don't clutter the db.
  # Allowing up to 11 retries is about 3 days since we try less frequently each time.
  @max_retries = 11

  def self.process_all
    ids = Gradeupdate.pluck(:id)
    ids.each do |id|
      update = Gradeupdate.find(id)
      next unless update.process?

      # Destroy before sending the update request
      update.destroy
      next unless update.membership.site.outcomes_url
      if(update.membership.site.is_canvas)
        response = update.canvas_process_update
        error = get_error_msg(response)
      else
        response = update.process_update
        error = get_error_msg(response)
      end
      next if error.nil? || update.tries > @max_retries
      # Add update back to database if it failed
      Gradeupdate.find_or_create_by_membership_id(update.membership.id, tries: update.tries + 1, last_error: error)
    end
  end

  def self.update_sections_with_recent_meetings
    meetings = Meeting.where('starttime < ? and future_meeting = true', Time.now)
    meetings.each do |m|
      if s = m.section.site.gradesettings
        register_section_change(m.section)
        update_max_points(s) if s.auto_max_points
      end
      m.future_meeting = false
      m.save
    end
  end

  def self.register_change(membership_id)
    u = Gradeupdate.find_or_create_by_membership_id(membership_id)
    u.tries = 0
    u.save
  end

  def self.register_section_change(section)
    section.memberships.each {|m| Gradeupdate.register_change(m.id) if m.record_attendance?} if section.site.outcomes_url
  end

  def self.register_site_change(site)
    site.memberships.map {|m| Gradeupdate.register_change(m.id) if m.record_attendance?}
  end

  def self.get_error_msg(response)
    begin
      document = LibXML::XML::Parser.string(response.body).parse
    rescue => exception
      return "Unable to parse response body, invalid xml."
    end

    document.root.namespaces.default_prefix = 'imsx'
    node = document.find('imsx:imsx_POXHeader/imsx:imsx_POXResponseHeaderInfo/imsx:imsx_statusInfo/imsx:imsx_codeMajor').first
    if !node || node.content.downcase != 'success'
      return "Missing imsx_codeMajor in response xml" if !node
      description = document.find('imsx:imsx_POXHeader/imsx:imsx_POXResponseHeaderInfo/imsx:imsx_statusInfo/imsx:imsx_description').first
      return "Missing imsx_description in response xml" if !description
      return description.content
    end
    return nil
  end

  # If update has already tried and failed (tries > 0), then try less frequently
  def process?
    self.tries == 0 || self.updated_at + (2 ** self.tries).minutes < Time.zone.now
  end

  def calculate_grade
    settings = Gradesettings.find_or_create_by_site_id(self.membership.site.id)

    # Calculate grade based only on attendances for meetings in the past
    # Use attendances from all sections to calculate grade.
    attendances = []
    self.membership.sections.each {|s| attendances += self.membership.recorded_attendances(s) if self.membership.site.sections.count == 1 || s.name != "Unassigned"}
    return 1.0 if attendances.empty? || settings.forgiven_absences >= attendances.count

    # User chooses to deduct x points per attendance after a certain number of absences
    if settings.deduction > 0
      total_absent = 0.0
      total_tardy = 0
      attendances.each do |a|
        total_absent += 1.0 if a.attendancetype.grade_as_absent?
        total_tardy += 1 if a.attendancetype.grade_as_tardy?
      end
      if settings.tardy_per_absence == 0
        total_absent += (1 - settings.tardy_value) * total_tardy
      else
        total_absent += total_tardy / settings.tardy_per_absence
      end
      total_absent = [total_absent - settings.forgiven_absences, 0].max
      return [1 - total_absent * settings.deduction, 0].max
    end

    total_present = 0.0
    total_tardy = 0
    attendances.each do |a|
      total_present += 1.0 if a.attendancetype.grade_as_present?
      total_tardy += 1 if a.attendancetype.grade_as_tardy?
    end
    if settings.tardy_per_absence == 0
      total_present += settings.tardy_value * total_tardy
    else
      total_present += total_tardy - total_tardy / settings.tardy_per_absence
    end

    [total_present / (attendances.count - settings.forgiven_absences), 1.0].min
  end

  def create_xml
    doc = LibXML::XML::Document.new
    doc.encoding = LibXML::XML::Encoding::UTF_8
    root = LibXML::XML::Node.new('imsx_POXEnvelopeRequest')
    root.namespaces.namespace = LibXML::XML::Namespace.new(root, nil, 'http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0')
      header = LibXML::XML::Node.new('imsx_POXHeader')
        header_info = LibXML::XML::Node.new('imsx_POXRequestHeaderInfo')
        header_info << LibXML::XML::Node.new('imsx_version', 'V1.0')
        header_info << LibXML::XML::Node.new('imsx_messageIdentifier', SecureRandom.uuid)
      header << header_info
    root << header
      body = LibXML::XML::Node.new('imsx_POXBody')
        replace_res = LibXML::XML::Node.new('replaceResultRequest')
          result_record = LibXML::XML::Node.new('resultRecord')
            sourced_guid = LibXML::XML::Node.new('sourcedGUID')
            sourced_guid << LibXML::XML::Node.new('sourcedId', self.membership.sourcedid)
          result_record << sourced_guid
            result = LibXML::XML::Node.new('result')
              result_score = LibXML::XML::Node.new('resultScore')
              result_score << LibXML::XML::Node.new('language', 'en')
              result_score << LibXML::XML::Node.new('textString', calculate_grade.to_s)
              result << result_score
          result_record << result
        replace_res << result_record
      body << replace_res
    root << body

    doc.root = root
    doc.to_s
  end

  def canvas_process_update
    site = self.membership.site
    url = "/v1/courses/#{site.lms_id}/assignments/#{site.assignment_id}/submissions/update_grades";
    # studentsGrades = {"grade_data[3855633][posted_grade]"=>"5.3",
    #          "grade_data[3202496][posted_grade]"=>"7.1",
    #          "grade_data[3812498][posted_grade]"=>"7.8"}
    # Canvas.post(url, studentsGrades)
    user =  self.membership.user
    studentGrade =
                {
                  "grade_data[#{user.lms_user_id}][posted_grade]" => calculate_grade
                }
    logger.info("Posted grade data is " + studentGrade.to_json)
    Canvas.post(url, studentGrade)
  end

  def process_update
    uri = URI(self.membership.site.outcomes_url)
    request_params = {
      'sourcedid' => self.membership.sourcedid,
      'lti_message_type' => 'basic-lis-replaceresult',
      'lti_version' => 'LTI-1p0',
      'oauth_callback' => 'about:blank'
    }

    uri.query = URI.encode_www_form(request_params)

    options = {
      :scheme => 'body',
      :timestamp => Time.now.utc.to_i,
      :nonce => SecureRandom.hex
    }

    host = uri.port == uri.default_port ? uri.host : "#{uri.host}:#{uri.port}"
    consumer = OAuth::Consumer.new(
      "notused",
      Attendance::Application.config.oauth_secret,
      {
        site: "#{uri.scheme}://#{host}",
        signature_method: "HMAC-SHA1"
      }
    )

    token = OAuth::AccessToken.new(consumer)
    token.post(uri.request_uri, create_xml, 'Content-Type' => 'application/xml')
  end

  def self.update_max_points(settings)
    return false if settings.site.points_url.nil?
    uri = URI(settings.site.points_url)

    max_points = settings.max_points
    max_points = settings.site.max_points_section.past_meetings.count - settings.forgiven_absences if settings.auto_max_points
    max_points = 1 if max_points < 1

    # Sakai requires a sourcedid for the lti service call, so pick a valid one from the section's members.
    # TODO: Look into modifying sakai code to not require a sourcedid for updating max points.
    m = settings.site.memberships.find {|m| m.sourcedid}
    return false if m.nil?

    request_params = {
      'id' => m.sourcedid,
      'lti_message_type' => 'basic-lti-setmaxpoints',
      'lti_version' => 'LTI-1p0',
      'max_points' => "#{max_points}",
      'oauth_callback' => 'about:blank'
    }

    options = {
      :scheme => 'body',
      :timestamp => Time.now.utc.to_i,
      :nonce => SecureRandom.hex
    }

    host = uri.port == uri.default_port ? uri.host : "#{uri.host}:#{uri.port}"
    consumer = OAuth::Consumer.new(
      "notused",
      Attendance::Application.config.oauth_secret,
      {
        site: "#{uri.scheme}://#{host}",
        signature_method: "HMAC-SHA1"
      }
    )
    consumer.http.read_timeout = 10

    response = consumer.request(:post, uri.path, nil, options, request_params)
    return response.code == "200"
  end
end
