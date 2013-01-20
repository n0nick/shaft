# Shaft - right on.

<pre>
 $$$$$$\  $$\   $$\  $$$$$$\  $$$$$$$$\ $$$$$$$$\
$$  __$$\ $$ |  $$ |$$  __$$\ $$  _____|\__$$  __|
$$ /  \__|$$ |  $$ |$$ /  $$ |$$ |         $$ |
\$$$$$$\  $$$$$$$$ |$$$$$$$$ |$$$$$\       $$ |
 \____$$\ $$  __$$ |$$  __$$ |$$  __|      $$ |
$$\   $$ |$$ |  $$ |$$ |  $$ |$$ |         $$ |
\$$$$$$  |$$ |  $$ |$$ |  $$ |$$ |         $$ |
 \______/ \__|  \__|\__|  \__|\__|         \__|
</pre>

An SSH tunnel assistant for the command line.


## Installation

As easy as:

    $ gem install shaft

## Usage

Your tunnel configurations need to be stored as records in
a [YAML](http://www.yaml.org) formatted `~/.shaft` file.

See 'Configuration' for instructions on how to format these
files.

* Use `shaft all` to get a list of all available tunnels.
* Use `shaft active` to see which tunnels are currently active.
  - You could use the `--short` option to get only the names
    of those lines (this could be useful to insert into your
    shell prompt. Just saying).
* `shaft start [NAME]` would start the tunnel of the same name.
* `shaft stop [NAME]` would stop the tunnel of the given name.

## Configuration

The SSH tunnels configuration Shaft will use are all stored in
a single YAML file under `~/.shaft`.

Each tunnel is represented by a key defining its name, followed
by an object describing all of the required parameters.

An example configuration would be:

    foobar:
        port: 22
        username: user
        host: remote-host
        bind:
          client-port: 9999
          host: host
          host-port: 8888

Calling Shaft with `$ shaft start foobar` would be equivalent
to running:

      $ ssh -N -p 22 user@remote-host -L 9999:host:8888

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
