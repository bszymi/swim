if Rails.env.test?
  Rails.application.config.action_dispatch.hosts_response_app = proc { |env| [ 200, {}, [ "OK" ] ] }
  Rails.application.config.hosts.clear
end
