#! /bin/bash


archive_file "~/test.txt" <<EOF
	src "test.txt"
EOF

archive_file "~/test.tar.gz" <<EOF
	src "test.tar.gz"
EOF
