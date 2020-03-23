# Dehydrated Hook for Gandi LiveDNS

Bash wrapper to create and renew Let's Encrypt SSL certificates using the
[dehydrated](https://github.com/lukas2511/dehydrated) ACME client, the DNS-01 challenge, and Gandi's LiveDNS API.

Forked from [tchabaud/lets-encrypt-gandi](https://github.com/tchabaud/lets-encrypt-gandi).

This adaptation does not use the `--cron` option of dehydrated, and instead manually generates certificate requests
&mdash; for the benefit of my obsession with elliptical curve keys.

This script has only been tested on Arch Linux, though it should work on any environment that contains the binaries
listed in [dependencies](#dependencies)

## Dependencies

* [bash](https://www.gnu.org/software/bash)
* [coreutils](https://www.gnu.org/software/coreutils)
* [curl](https://curl.haxx.se)
* [openssl](https://www.openssl.org)

These can be found as `pacman` packages in the official Arch Linux repositories.

* A [Gandi LiveDNS API key](https://doc.livedns.gandi.net/#step-1-get-your-api-key).

## License

    Copyright 2018 Thomas Chabaud, GPL v3.0
    Copyright 2020 Elias Yuan <a@jthv.ai>, GPL v3.0+

Refer to [LICENSE](./LICENSE) for the full text. You may also acquire a copy from
[here](https://gitlab.com/jthvai/licenses/raw/master/GPL-3.0.txt).
