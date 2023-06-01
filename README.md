# PGP Paper

* Create PDFs from PGP keys and messages by printing a QR code, Base32 encoded
backup string and SHA-256 hash
* Restore PGP keys and messages by using the QR code or typing the Base32
encoded backup string

  <picture>
      <img height=600 src="https://raw.githubusercontent.com/jlehtoranta/pgp-paper/main/screenshot.png">
  </picture>

## Motivation

PGP master keys should be stored offline and accessed only when necessary.
The lifetime of a single master key can be tens of years and it should always
be reliably retrievable. There exists some digital mediums, which are suitable
for long-term storage (CD-R, DVD-R, tape), but even today many homes don't
have a drive for reading them anymore. This limits the choice of digital
mediums to flash drives/cards and solid-state/hard drives, which carry
a risk of data corruption or are otherwise unsuitable for long-term storage.

Paper is an excellent medium for long-term storage and prints can be easily
stored in multiple places. For this purpose there exists e.g.
[Paperkey](https://github.com/dmshaw/paperkey/), which allows you to print
a stripped down PGP key. However, the printed key isn't easily retrievable
from the paper and reconstruction requires using the same tool. Instead of
that the key should be easily retrievable and stored in a standard format.
This is why I felt the need to create this tool.

## Usage

      ./pgp_paper.sh -w -i private.key -i message.gpg -t "Secret Message"
      -n                  Full name
      -m                  Email address
      -w                  Write to PDF
      -r                  Read from a PNG or a Base32 encoded text file
      -i   [filename]     PGP private key/message filename (GPG [write] or PNG/Base32 [read])
      -t   [header]       Set a custom header for the PGP private key or message
      -o   [filename]     PDF filename

## Requirements

### Ubuntu/Debian

* `apt install gpg qrencode zbar-tools texlive-base`

## Known issues

* Tested only with ed25519 keys and small messages, which will fit into
a single QR code (version 40, ECC level M). ASCII armored keys and
messages exceeding 2331 bytes should be split into multiple QR codes,
which has not yet been implemented.

