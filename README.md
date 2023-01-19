## vim
```sh
ln -s ~/dotfiles/.vim ~/.vim
ln -s ~/dotfiles/.vimrc ~/.vimrc
```
### local config
```
touch ~/.vimrc.local
```

## neovim
```sh
mkdir -p ~/.config/nvim
ln -s ~/dotfiles/.config/nvim/init.vim ~/.config/nvim/init.vim
```

## zsh
```sh
ln -s ~/dotfiles/.zshrc ~/.zshrc
chsh -s /usr/bin/zsh
```
### local config
```
touch ~/.zshrc.local
```