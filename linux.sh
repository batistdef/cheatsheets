##########
## Kube ##
##########
# To be able to use kubectl from current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Download kubectl without all the kubernetes components
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

##########
## VIM  ##
##########
# Disable tabs and replace by 2 spaces:
echo ":set tabstop=2 shiftwidth=2 expandtab" >> ~/.vimrc
# On old systems like centos/7:
echo ":set tabstop=2 shiftwidth=2 expandtab" | sudo tee -a /etc/virc


#############
## ALIASES ##
#############
alias ll='ls -lah --color=auto'
alias svim='sudo vim'
if ! command -v vim &> /dev/null; then alias vim='vi'; alias svim='sudo vi'; fi
