package_install "vim-nox"
package_install "exuberant-ctags"

for user in "${vim_users[@]}"
do
	home=$(user_get_home "$user")

	archive_file "$home/.vimrc" <<-FILE
		src "vimrc"
		owner $user
	 	group $user 
	FILE

	archive_file "/tmp/vim.tar" <<-FILE
		src "vim.tar"
		owner $user
	 	group $user 
	FILE
	
	tar -xf /tmp/vim.tar -C $home && rm -f /tmp/vim.tar \
		|| fail "Error extracting vim files"
done
