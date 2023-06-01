#!/bin/bash

# (c) Jarkko Lehtoranta <jarkko@bytecap.fi>
# 
# Writes a PGP private key and/or a message into a PDF file
# Reads a PGP private key and/or a message from a PNG or text file

name="Donald Duck"
email="donald@duck.org"
w=0
r=0
message_fns=()
pdf_hdrs=()
key_hdr="PGP Private Key"
message_hdr="PGP Message"
pdf_fn="pgp_print"

# Writer

# Create a QR Code image file
write_qrcode() {
    plate=""
    if is_pgp_key "$1"; then
        plate="s/ARMORED FILE--/PRIVATE KEY BLOCK--/g"
    else
        plate="s/ARMORED FILE--/MESSAGE--/g"
    fi
    gpg --enarmor < "$1" | sed -e "$plate" -e "/^Comment:/d" > "$1.asc"
    qrencode -t PNG -8 -l M -v 40 -s 12 -d 600 -r "$1.asc" -o "$1.asc.png"
}

# Write a Base32 encoded text file
write_base32() {
    sha256sum "$1" | sed -r "s/^([0-9a-f]+).*$/\1/" > "$1.sha256"
    basenc --base32 -w 72 "$1" | sed -r "s/(\w{4})/\1 /g" > "$1.base32"
}

generate_pdf() {
    tex_fn="$pdf_fn.tex"
    cat pgp_paper_begin.tex | sed -e "s/%full_name/${name}/g" -e "s/%email_address/${email}/g" > "$tex_fn"
    for ((i=0; i < ${#message_fns[@]}; i++)); do
        fn="${message_fns[$i]}"
        hdr="${pdf_hdrs[$i]}"
        if [[ -r "$fn.base32" && -r "$fn.sha256" && -r "$fn.asc.png" ]]; then
            cat pgp_paper_message.tex | sed -e "s/%pgp_filename/${fn}/g" -e "s/%pgp_header/${hdr}/g" >> "$tex_fn"
        fi
    done
    cat pgp_paper_end.tex >> "$tex_fn"

    lualatex "$tex_fn"
}

# Reader
read_qrcode() {
    # Read a QR Code from an image
    zbarimg --raw --oneshot --nodbus "$1" > "$1.gpg.asc"
}

read_base32() {
    # Read a Base32 encoded text file
    basenc --base32 -d -i "$1" > "$1.gpg"
    sha256sum "$1.gpg"
}

is_pgp_key() {
    if [[ $(gpg --import --import-options show-only "$1") =~ ^(sec|ssb) ]]; then
        return 0
    fi
    return 1
}

usage() {
    echo ""
    echo "PGP Paper"
    echo ""
    echo "* Write binary PGP keys and messages on a paper"
    echo "* Read PGP keys and messages from a paper"
    echo ""
    echo "Usage:"
    echo "  ./pgp_paper.sh -w -i private.key -i message.gpg -t \"Secret Message\""
    echo "  -n                  Full name"
    echo "  -m                  Email address"
    echo "  -w                  Write to PDF"
    echo "  -r                  Read from a PNG or a Base32 encoded text file"
    echo "  -i   [filename]     PGP private key/message filename (GPG [write] or PNG/Base32 [read])"
    echo "  -t   [header]       Set a custom header for the PGP private key or message"
    echo "  -o   [filename]     PDF filename"
}

while getopts "n:m:wri:t:o:" opt; do
    case $opt in
        n)
            name="$OPTARG"
            ;;
        m)
            email="$OPTARG"
            ;;
        w)
            w=1
            ;;
        r)
            r=1
            ;;
        i)
            message_fns+=("$OPTARG")
            if [[ ${#pdf_hdrs[@]} < ${#message_fns[@]} ]]; then
                pdf_hdrs+=("")
            fi
            ;;
        t)
            if [[ ${#pdf_hdrs[@]} < 1 ]]; then
                pdf_hdrs+=("$OPTARG")
            else
                pdf_hdrs[-1]="$OPTARG"
            fi
            ;;
        o)
            pdf_fn="$OPTARG"
            ;;
        \?)
            usage
            exit 1
            ;;
        :)
            usage
            exit 1
            ;;
    esac
done

for ((i=0; i < ${#message_fns[@]}; i++)); do
    fn=${message_fns[$i]}
    if [[ $w == 1 ]]; then
        if [[ -r "$fn" ]]; then
            if is_pgp_key "$fn" && [[ ${pdf_hdrs[$i]} == "" ]]; then
                pdf_hdrs[$i]="$key_hdr"
            elif [[ ${pdf_hdrs[$i]} == "" ]]; then
                pdf_hdrs[$i]="$message_hdr"
            fi
            write_base32 "$fn"
            write_qrcode "$fn"
        else
            echo "File not found: $fn"
            exit 1
        fi
    elif [[ $r == 1 ]]; then
        if [[ -r "$fn" && ("$fn" == *".PNG" || "$fn" == *".png") ]]; then
            read_qrcode "$fn"
        elif [[ -r "$fn" ]]; then
            read_base32 "$fn"
        else
            echo "File not found: $fn"
            exit 1
        fi
    else
        usage
        exit 1
    fi
done

if [[ $w == 1 ]]; then
    generate_pdf
fi

exit 0

