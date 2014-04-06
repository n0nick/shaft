module Shaft
  class Tunnel
    attr_reader :host, :binds, :status

    def initialize(host, bind)
      @host = Tunnel::Host.new(host)

      @binds = [bind].compact.flatten(1).map do |b|
        Tunnel::Bind.new(b)
      end

      @status = :inactive
    end

    def bind
      raise Tunnel::MultipleBindingsError.new if self.binds.length != 1

      self.binds.first
    end

    def start
      raise Tunnel::AlreadyActiveError.new if status == :active

      binds.each do |bind|
        pid = Process.spawn("ssh -N -p #{host} #{bind}")
        Process.detach pid
        pids << pid
      end

      @status = :active
    end

    def stop
      raise Tunnel::AlreadyInactiveError.new if status == :inactive

      pids.each do |pid|
        Process.kill "INT", pid
      end

      @status = :inactive
    end

    def restart
      begin
        stop
      rescue Tunnel::AlreadyInactiveError
      end
      start
    end

    def pids
      @pids ||= []
    end

  end

  class Tunnel::Host
    attr_accessor :name, :port, :user

    def initialize(options)
      self.name = options[:name]
      self.port = options[:port]
      self.user = options[:user]

      raise ArgumentError.new if self.name.nil?
    end

    def to_s
      st = ""

      unless port.nil?
        st << "#{port} "
      end

      unless user.nil?
        st << "#{user}@"
      end

      st << name
    end
  end

  class Tunnel::Bind
    attr_accessor :client_port, :host_port, :hostname, :reverse

    def initialize(options)
      self.client_port = options[:client_port]
      self.host_port   = options[:host_port]
      self.hostname    = options[:hostname]
      self.reverse     = !!options[:reverse]

      if client_port.nil? || host_port.nil? || hostname.nil?
        raise ArgumentError.new
      end
    end

    def to_s
      flag = reverse ? "-R" : "-L"
      flag + ' ' + [client_port, hostname, host_port].join(':')
    end
  end

  class Tunnel::MultipleBindingsError < StandardError; end
  class Tunnel::AlreadyActiveError    < StandardError; end
  class Tunnel::AlreadyInactiveError  < StandardError; end
end
