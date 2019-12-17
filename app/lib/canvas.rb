class Canvas
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
  def self.get(path)
    if @http.nil?
      @http = HTTPClient.new
      @http.connect_timeout = 5
      @http.receive_timeout = 5
      @http.send_timeout = 5
    end

    self.logger.info('fetching from canvas ' + Attendance::Application.config.canvas_api_base + path)
    res = @http.get(Attendance::Application.config.canvas_api_base + path, nil, { 'Authorization' => 'Bearer ' + Attendance::Application.config.canvas_api_token })
    return JSON.parse(res.content, :symbolize_names => true) rescue {}
  end

  def self.getall(path)
    if @http.nil?
      @http = HTTPClient.new
      @http.connect_timeout = 5
      @http.receive_timeout = 5
      @http.send_timeout = 5
    end

    next_path = Attendance::Application.config.canvas_api_base + path + (path.include?('?') ? '&per_page=100' : '?per_page=100')
    ret = []
    while (!next_path.blank?)
      self.logger.info('fetching from canvas ' + next_path)
      res = @http.get(next_path, nil, { 'Authorization' => 'Bearer ' + Attendance::Application.config.canvas_api_token })
      ret += (JSON.parse(res.content, :symbolize_names => true) rescue [])
      links = self.parse_link_header(res.header['link'][0])
      next_path = links[:next]
    end

    return ret
  end

  def self.parse_link_header(header)
    links = header.split(',').reduce(Hash.new) do |links, part|
      section = part.split(';')
      url = section[0].match(/<(.*)>/)[1]
      name = section[1].match(/rel="(.*)"/)[1].to_sym
      links[name] = url
      links
    end
  end

  def self.post(path, data)
    if @http.nil?
      @http = HTTPClient.new
      @http.connect_timeout = 5
      @http.receive_timeout = 5
      @http.send_timeout = 5
    end

    self.logger.info('Updating grade to canvas ' + Attendance::Application.config.canvas_api_base + path)
    res = @http.post(Attendance::Application.config.canvas_api_base + path, data, { 'Authorization' => 'Bearer ' + Attendance::Application.config.canvas_api_token })
    return res
  end

end
