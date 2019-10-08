class Section < ActiveRecord::Base
  attr_accessible :name, :site_id

  belongs_to :site, :inverse_of => :sections
  has_and_belongs_to_many :memberships
  has_many :meetings, :inverse_of => :section, :dependent => :destroy

  def userattendances
    Userattendance.joins(:meeting, {membership: :siteroles}).where(:meetings => { :deleted => false, :cancelled => false, :section_id => self.id }, :siteroles => { :record_attendance => true })
  end

  def past_attendances
    userattendances.where('meetings.starttime < ?', Time.zone.now)
  end

  def recorded_memberships
    memberships.joins(:siteroles).where(:siteroles => {:record_attendance => true})
  end

  def valid_meetings
    self.meetings.where(:cancelled => false, :deleted => false)
  end

  def valid_meeting_count
    @valid_meeting_count ||= self.valid_meetings.count
  end

  def past_meetings
    valid_meetings.where('starttime < ?', Time.zone.now)
  end

  def past_meeting_count
    @past_meeting_count ||= past_meetings.count
  end

  def safe_name
    name.gsub(/\W+/, '_')
  end

  def useful_name
    is_default ? site.context_name : display_name
  end

  # Temporary fix for replacing unreadable providerids with section name. Send a request to TRACS /direct API
  # to retrieve the section name.
  def self.get_section_from_cmprovider(directUrl, providerid)
    if @http.nil?
      @http = HTTPClient.new
      @http.connect_timeout = 5
      @http.receive_timeout = 5
      @http.send_timeout = 5
    end
    begin
      res = @http.get("#{directUrl}/cm-enrollment-set/#{providerid}.json")
    rescue
      return nil
    end
    # If we get 403 forbidden, refresh the session and try again
    if res.code == 403
      begin
        @http.post "#{directUrl}/session", "_username" => Attendance::Application.config.tracsuser, "_password" => Attendance::Application.config.tracspw
        res = @http.get("#{directUrl}/cm-enrollment-set/#{providerid}.json")
      rescue
        return nil
      end
    end
    if res.code == 200
      enrollmentSet = JSON.parse(res.content) rescue {}
      return enrollmentSet['title']
    end
    return nil
  end

  def login(directUrl, client)
    client.post "#{directUrl}/session", "_username" => Attendance::Application.config.tracsuser, "_password" => Attendance::Application.config.tracspw
  end

  def display_name
    return self[:display_name] unless self[:display_name].blank?
    return name if is_default || site.points_url.nil? || site.points_url.empty?
    return Rails.cache.read("cmprovider/#{name}") if Rails.cache.exist?("cmprovider/#{name}")
    uri = URI(site.points_url)
    host = uri.port == uri.default_port ? uri.host : "#{uri.host}:#{uri.port}"
    directUrl = "#{uri.scheme}://#{host}/direct"
    sectionName = self.class.get_section_from_cmprovider(directUrl, name)
    Rails.cache.write("cmprovider/#{name}", sectionName, expires_in: 1.hours) unless sectionName.nil?
    return sectionName || name
  end

  def member_row(opts, uas, totals)
    row = []
    uas.map do |ua|
      row.push(ua.attendancetype.name)
      row.push(ua.checkins.first.time) rescue row.push('') if opts[:checkins]
    end if opts[:sessions]
    row += Attendancetype.getall.map{|a| totals[a.id-1]} if opts[:totals]
    row
  end

  def export_to_csv(opts)
    require 'csv'
    meetings = self.meetings.includes(userattendances: [:checkins, {membership: [:user, :sections]}]).where(cancelled: false).order("starttime DESC").to_a
    uas_by_member = {}
    totals_by_member = {}
    memberships = meetings.flat_map(&:userattendances).map do |ua|
      uas_by_member[ua.membership] ||= []
      uas_by_member[ua.membership].push(ua)
      totals_by_member[ua.membership] ||= Array.new(Attendancetype.getall.length, 0)
      totals_by_member[ua.membership][ua.attendancetype.id-1] += 1
      ua.membership
    end.to_set.to_a
    memberships.sort_by! {|m| [m.user.lastname.downcase, m.user.firstname.downcase] }

    actives, inactives, moved = [],[],[]
    memberships.each do |m|
      unless m.sections.include?(self)
        moved.push(m)
        # Moved members won't have userattendances for meetings created after they moved
        uas_by_member[m].unshift(nil) while uas_by_member[m].length < meetings.length
        next
      end
      m.active ? actives.push(m) : inactives.push(m)
    end

    headers = []
    meetings.each do |m|
      headers.push(m.starttime.to_s)
      headers.push('Checkin Time') if opts[:checkins]
    end if opts[:sessions]
    Attendancetype.getall.each do |a|
      headers.push('Total ' + a.name)
    end if opts[:totals]

    CSV.generate do |csv|
      csv << ['Active'] + headers
      actives.each do |m|
        csv << [m.user.fullname] + member_row(opts, uas_by_member[m], totals_by_member[m])
      end
      if inactives.any?
        csv << ['']
        csv << ['Inactive'] + headers
        inactives.each do |m|
          csv << [m.user.fullname] + member_row(opts, uas_by_member[m], totals_by_member[m])
        end
      end
      if moved.any?
        csv << ['']
        csv << ['Moved'] + headers
        moved.each do |m|
          csv << [m.user.fullname] + member_row(opts, uas_by_member[m], totals_by_member[m])
        end
      end
    end
  end
end
