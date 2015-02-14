# dpkg-pacman

ubuntu's package management command's output is very ugly,especially compared to 
Arch's `pacman` and Gentoo's `emerge`.So I want to write a little script to beautify its
output,like this:

![](https://raw.github.com/hangyan/dpkg-pacman/master/images/compare.png)


currently, I only finished a few commands,there is still a lot work to do. Any
suggest and feedback will be welcome. Email :
[yanhangyhy@gmail.com](mailto:yanhangyhy@gmail.com).

# install

just download the script :

    wget https://raw.githubusercontent.com/hangyan/dpkg-pacman/master/pacman.sh

and put somewhere you think appropriate and `chmod a+x pacman.sh`.


# usage

## search

Search packages,You can see the effect on the previous picture.

TODO:

1. support search multi packages at one Search
2. package version fix
3. ...


## files

Show installed packages's files.

![](https://raw.github.com/hangyan/dpkg-pacman/master/images/files.png)

The output is not clear as `tree`,but is better than the origin


## deps

show package's dependencies and reverse depends.

origin output of `apt-cache showpkg htop` :

![](https://raw.github.com/hangyan/dpkg-pacman/master/images/origin-deps.png)

the new one of `pacman.sh deps htop` :

![](https://raw.github.com/hangyan/dpkg-pacman/master/images/deps.png)



## info

show package's infomation (`apt-cache show pkgname`) :

![](https://raw.github.com/hangyan/dpkg-pacman/master/images/info.png)


