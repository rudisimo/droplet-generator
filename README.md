# DigitalOcean VPS Generator

A Vagrant + Puppet configuration environment to create and deploy [DigitalOcean][3] droplets.

## Dependencies

* Mac OS X 10.8+
* [Vagrant][1]
* [VirtualBox][2]

## Usage

Begin by installing the ruby dependencies:

    sudo gem install bundler && bundle install

Once the depedencies have been met, create the environment configuration and follow the
onscreen instructions:

    rake init

Deploy the DigitalOcean droplet:

    vagrant up --provider digital_ocean

## Used third-party libraries

* PuPHPet: [https://github.com/puphpet/puphpet][4]

## License

This package is licensed under the [MIT License][5] - see the LICENSE.txt file for more
details.

[1]: http://docs.vagrantup.com/v2 "Vagrant Documentation"
[2]: http://docs.puppetlabs.com/ "Puppet Documentation"
[3]: https://www.digitalocean.com/?refcode=599f6048b45e "DigitalOcean Referral URL"
[4]: https://github.com/puphpet/puphpet "GitHub Repository"
[5]: http://opensource.org/licenses/mit-license.php "MIT License"
