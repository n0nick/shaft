require 'spec_helper'

describe Shaft::Tunnel do
  valid_host = { name: 'some' }
  valid_bind = { hostname: 'other', client_port: 30, host_port: 50 }
  valid_multi_binds = [
    { client_port: 55, host_port: 81, hostname: 'other_host1' },
    { client_port: 44, host_port: 91, hostname: 'other_host2' }]

  before :each do
    Process.stub(:spawn) { 13 }
    Process.stub(:detach)
    Process.stub(:kill)
  end

  describe '#initialize' do

    it 'configures a host' do
      tunnel = Shaft::Tunnel.new({ name: 'hostname', port: 23, user: 'yuzer' },
                                 valid_bind)
      tunnel.host.name.should eq 'hostname'
      tunnel.host.port.should eq 23
      tunnel.host.user.should eq 'yuzer'
    end

    it 'configures a binding' do
      tunnel = Shaft::Tunnel.new(valid_host,
                                 client_port: 55, host_port: 80, hostname: 'othername')
      tunnel.bind.client_port.should eq 55
      tunnel.bind.host_port.should eq 80
      tunnel.bind.hostname.should eq 'othername'
    end

    it 'can configure multiple bindings' do
      tunnel = Shaft::Tunnel.new(valid_host, valid_multi_binds)

      tunnel.binds.length.should eq 2
      tunnel.binds[0].hostname.should eq 'other_host1'
      tunnel.binds[1].hostname.should eq 'other_host2'
    end

    it 'starts tunnel as "inactive"' do
      tunnel = Shaft::Tunnel.new(valid_host, valid_bind)
      tunnel.should_not be_active
    end
  end

  describe '#bind' do
    describe 'when 1 binding is defined' do
      it 'returns it' do
        tunnel = Shaft::Tunnel.new(valid_host, valid_bind)
        bind = nil
        expect {
          bind = tunnel.bind
        }.to_not raise_error
        bind.hostname.should eq 'other'
      end
    end

    describe 'when more than 1 binding is defined' do
      it 'raises an error' do
        tunnel = Shaft::Tunnel.new(valid_host, valid_multi_binds)
        expect { tunnel.bind }.to raise_error Shaft::Tunnel::MultipleBindingsError
      end
    end
  end

  describe '#active?' do
    before :each do
      @tunnel = Shaft::Tunnel.new(valid_host, valid_bind)
    end

    it 'defaults to false' do
      @tunnel.should_not be_active
    end

    it 'is true if all pids are currently active' do
      @tunnel.start
      Process.stub(:kill).with(0, 13) { 1 }
      @tunnel.should be_active
    end

    it 'is false if no pids are currently active' do
      @tunnel.start
      Process.stub(:kill).with(0, 13) { 1 }
      @tunnel.stop
      Process.stub(:kill).with(0, 13) { raise Errno::ESRCH }
      @tunnel.should_not be_active
    end
  end

  describe 'when configured with single binding' do

    describe '#start' do
      before :each do
        @tunnel = Shaft::Tunnel.new(valid_host, valid_bind)
      end

      it 'starts the SSH tunnel' do
        Process.should_receive(:spawn)
          .with("ssh -N -p some -L 30:other:50") { 13 }
        Process.should_receive(:detach).with(13)
        @tunnel.start
      end

      it 'fails if tunnel was active' do
        @tunnel.stub(:active?) { true }
        expect { @tunnel.start }.to raise_error Shaft::Tunnel::AlreadyActiveError
      end

      it 'fails upon SSH error' do
        Process.should_receive(:spawn) { raise Error }
        expect { @tunnel.start }.to raise_error
      end
    end

    describe '#stop' do
      before :each do
        @tunnel = Shaft::Tunnel.new(valid_host, valid_bind)
        @tunnel.stub(:pids) { [13] }
        @tunnel.stub(:active?) { true }
      end

      it 'kills the SSH tunnel' do
        Process.should_receive(:kill).with("INT", 13)
        @tunnel.stop
      end

      it 'fails if tunnel wasn\'t active' do
        @tunnel.stub(:active?) { false }
        expect { @tunnel.stop }.to raise_error Shaft::Tunnel::AlreadyInactiveError
      end

      it 'fails upon kill error' do
        Process.stub(:kill) { raise Errno::ESRCH }
        expect { @tunnel.stop }.to raise_error
        @tunnel.should be_active
      end
    end

    describe '#restart' do
      before :each do
        @tunnel = Shaft::Tunnel.new(valid_host, valid_bind)
        @tunnel.start
        @tunnel.stub(:active?) { true }
        @tunnel.stub(:stop) {
          @tunnel.stub(:active?) { false }
        }
      end

      it 'stops the previous tunnel process' do
        @tunnel.should_receive(:stop).once
        @tunnel.restart
      end

      it 'starts a new tunnel process' do
        Process.should_receive(:spawn) { 14 }
        @tunnel.restart
      end

      it 'doesn\'t fail if tunnel wasn\'t active' do
        @tunnel.stub(:active?) { false }
        expect {
          @tunnel.restart
        }.to_not raise_error
      end

      it 'fails upon start errors' do
        @tunnel.stub(:start) { raise Error }
        expect {
          @tunnel.restart
        }.to raise_error
      end
    end

  end

  describe 'when configured with multiple bindings' do
    before :each do
      Process.stub(:spawn).and_return(20, 21)
    end

    before :each do
      @tunnel = Shaft::Tunnel.new(valid_host, valid_multi_binds)
    end

    describe '#start' do
      it 'should start a process for each binding' do
        Process.should_receive(:spawn).twice.and_return(20, 21)
        @tunnel.start
      end

      it 'should store all process PIDs' do
        @tunnel.start
        @tunnel.pids.should eq [20, 21]
      end

    end

    describe '#stop' do
      before :each do
        @tunnel.stub(:pids) { [20,21] }
        @tunnel.stub(:active?) { true }
      end

      it 'should stop all started processes' do
        Process.should_receive(:kill).once.ordered.with("INT", 20)
        Process.should_receive(:kill).once.ordered.with("INT", 21)
        @tunnel.stop
      end
    end

    describe '#restart' do
      before :each do
        @tunnel.stub(:pids) { [20,21] }
        @tunnel.stub(:active?) { true }
        @tunnel.stub(:stop) {
          @tunnel.stub(:active?) { false }
        }
      end

      it 'should stop all started processes' do
        @tunnel.should_receive(:stop).once
        @tunnel.restart
      end

      it 'should fire up new processes' do
        @tunnel.should_receive(:start).once
        @tunnel.restart
      end
    end
  end
end

describe Shaft::Tunnel::Host do
  describe '#initialize' do
    it 'raises error if no name defined' do
      expect {
        Shaft::Tunnel::Host.new(port: 33)
      }.to raise_error
    end
  end

  describe '#to_s' do
    it 'includes only hostname when no port or user defined' do
      host = Shaft::Tunnel::Host.new(name: 'name1')
      host.to_s.should eq 'name1'
    end
    it 'includes username when defined' do
      host = Shaft::Tunnel::Host.new(name: 'name1', user: 'yuzer')
      host.to_s.should eq 'yuzer@name1'
    end
    it 'includes port when defined' do
      host = Shaft::Tunnel::Host.new(name: 'name1', port: 33)
      host.to_s.should eq '33 name1'
    end
    it 'includes both port and username when defined' do
      host = Shaft::Tunnel::Host.new(name: 'name1', port: 33, user: 'yuzer')
      host.to_s.should eq '33 yuzer@name1'
    end
  end
end

describe Shaft::Tunnel::Bind do
  describe '#initialize' do
    it 'raises error if arguments are missing' do
      expect {
        Shaft::Tunnel::Bind.new(
          client_port: 33,
          host_port: 55
        )
      }.to raise_error

      expect {
        Shaft::Tunnel::Bind.new(
          hostname: 'foo1'
        )
      }.to raise_error
    end

    it 'defaults as reverse=false' do
      bind = Shaft::Tunnel::Bind.new(
        client_port: 33,
        host_port: 55,
        hostname: 'foo1'
      )
      bind.reverse.should eq false
    end
  end

  describe '#to_s' do
    it 'includes hostname, client and host ports' do
      bind = Shaft::Tunnel::Bind.new(
        hostname: 'host1',
        client_port: 33,
        host_port: 55
      )
      bind.to_s.should eq "-L 33:host1:55"
    end

    it 'reflects "reverse" when specified' do
      bind = Shaft::Tunnel::Bind.new(
        hostname: 'host1',
        client_port: 33,
        host_port: 55,
        reverse: true
      )
      bind.to_s.should eq "-R 33:host1:55"
    end
  end
end

