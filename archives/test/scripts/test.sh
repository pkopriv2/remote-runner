#! /bin/bash


archive_file "/home/pkopriv2/test.txt" <<EOF
	src "test.txt"
EOF

archive_file "/home/pkopriv2/test.tar.gz" <<EOF
	src "test.tar.gz"
EOF
