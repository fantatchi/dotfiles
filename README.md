## vim
ln -s ~/dotfiles/.vim ~/.vim
ln -s ~/dotfiles/.vimrc ~/.vimrc

## neovim
mkdir -p ~/.config/invim
ln -s ~/dotfiles/.config/nvim/init.vim ~/.config/nvim/init.vim

## zsh
ln -s ~/dotfiles/.zshrc ~/.zshrc
chsh -s /usr/bin/zsh
