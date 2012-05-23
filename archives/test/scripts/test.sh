#! /bin/bash

archive_file "/root/test.txt" <<EOF
	src "test.txt"
EOF

archive_file "/root/test.tar.gz" <<EOF
	src "test.tar.gz"
EOF
