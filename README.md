### TeamViewer_ID_Reset
Tools to reset Teamviewer ID. I’ve released these tools (source code) as there are only a few other ID reset tools available online, and some of them are untrusted binaries with no source code.

These are a work in progress and are meant to help users who have been wrongly flagged for commercial use. When this happens, the normal routine is to contact TV support and request them to unblock your ID, but this can take up to a week, while resetting your ID only take a few minutes.

Keep in mind, if you are using TV in a way that breaks their EULA, then these tools are not meant for you.

### Windows:
I have confirmed this is working on a few Windows 10 machines, but it still needs more testing. This tool is written in go, so it will need compiled before running. Some antivirus programs will produce a false positive on this binary.

### Linux: (debian based)
The linux tool takes a deeper approach to changing the ID than is normally required. This is due to several machines I’ve run into refused to get a new ID by traditional methods, so this software was written to combat this. It has been 100% effective in my testing with resetting TV ID’s on debian based distro’s running a GUI (I haven’t thoroughly tested on headless versions, but the code will need modified to do so). This tool by default will setup / reset teamviewer-host. This can be easily changed by editing the url and/or filename in the code to install whichever version of TV you wish. Tool requires internet to download the official TV binaries from teamviewer.com. Once TV has reset your ID and installed the latest version, it will also reset your TV password to a random 16 char password. This feature was implemented due to the default 8 char password being too weak in my opinion. If you don’t like this feature, comment the code out or change the password to whatever you wish as this is open source software. :) This tool is written in shell and will run natively on debian based linux (debian, ubuntu, mint, etc). It will not work on Fedora / CentOS based distro's without editing the source code. Cleaning up the code is on the to-do list.

### Mac:
There are already several python TV ID reset tools, so I suggest searching for them.
