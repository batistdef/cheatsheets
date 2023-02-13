# UPDATE /etc/hosts
echo -e "192.168.60.10 prometheus prometheus.gk.local\n192.168.60.20 node1 node1.gk.local\n192.168.60.30 node2 node2.gk.local" | sudo tee -a /etc/hosts

######################################################################################
## PROMETHEUS
######################################################################################
# INSTALL PROMETHEUS

## CREATE USER
sudo useradd --no-create-home --shell /bin/false prometheus

sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

## DOWNLOAD
cd ~
curl -LO https://github.com/prometheus/prometheus/releases/download/v2.37.0/prometheus-2.37.0.linux-amd64.tar.gz

tar xvf prometheus-2.37.0.linux-amd64.tar.gz
sudo cp prometheus-2.37.0.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.37.0.linux-amd64/promtool /usr/local/bin/

sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

sudo cp -r prometheus-2.37.0.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.37.0.linux-amd64/console_libraries /etc/prometheus

sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries

rm -rf prometheus-2.37.0.linux-amd64.tar.gz prometheus-2.37.0.linux-amd64

## CONFIG
sudo vi /etc/prometheus/prometheus.yml
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

## EXEC ##

sudo -u prometheus /usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /var/lib/prometheus/ --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc/prometheus/console_libraries

## CREATE SERVICE
sudo vi /etc/systemd/system/prometheus.service

#--
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /var/lib/prometheus/ --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
#--

sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

sudo systemctl status prometheus

## SECURITE + HOSTING
sudo yum install -y httpd-tools epel-release
sudo yum install -y nginx

# MDP
sudo htpasswd -c /etc/nginx/.htpasswd sammy

sudo mkdir /etc/nginx/sites-enabled
sudo vi /etc/nginx/sites-enabled/prometheus

#--
server {
	listen 80;
	listen [::]:80;
	server_name prometheus prometheus.gk.local 192.168.60.10;

	location / {
		auth_basic "Prometheus server authentication";
		auth_basic_user_file /etc/nginx/.htpasswd;
		proxy_pass http://localhost:9090;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection 'upgrade';
		proxy_set_header Host $host;
		proxy_cache_bypass $http_upgrade;
	}

	error_log /var/log/nginx/prom.err info;
}
#

sudo vi /etc/nginx/nginx.conf

#-- In http block:
include /etc/nginx/sites-enabled/*;
#--

# To prevent "permission denied error"
sudo setsebool -P httpd_can_network_connect 1
sudo nginx -t && sudo systemctl reload nginx && sudo systemctl status nginx


######################################################################################
## NODE_EXPORTER
######################################################################################
# INSTALL NODE_EXPORTER
## create user
sudo useradd --no-create-home --shell /bin/false node_exporter

## Download binary
cd ~
curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz

tar xvf node_exporter-1.3.1.linux-amd64.tar.gz
sudo cp node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

rm -rf node_exporter-1.3.1.linux-amd64.tar.gz node_exporter-1.3.1.linux-amd64

## CREATE SERVICE
sudo vi /etc/systemd/system/node_exporter.service

#--
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
#--

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
sudo systemctl status node_exporter

## EDIT PROMETHEUS CONFIG
sudo vi /etc/prometheus/prometheus.yml

#--
- job_name: 'node_exporter'
  scrape_interval: 5s
  static_configs:
  - targets: ['localhost:9100']
#--

sudo systemctl restart prometheus
sudo systemctl status prometheus


