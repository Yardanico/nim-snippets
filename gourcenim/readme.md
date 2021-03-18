# Scripts/settings for visualizing Nim git repo with Gource



```
# For Arch
sudo pacman -Sy gource
git clone https://github.com/nim-lang/nim
```

https://github.com/acaudwell/Gource/wiki/Gravatar-Example - Getting the list of all contributors with their emails

```
# Reverse order so the last entry is the newest ones
# so that we can use the last email for a user
git -C nim log --pretty=format:"%ae:%an" | tac > users.txt
```