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
end
