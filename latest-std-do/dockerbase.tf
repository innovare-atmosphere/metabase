variable "database_password" {
    default = ""
}

variable "domain" {
    default = ""
}


resource "digitalocean_droplet" "www-metabase" {
  image = "ubuntu-20-04-x64"
  name = "www-1"
  region = "nyc3"
  size = "s-1vcpu-1gb"
  ssh_keys = [
    digitalocean_ssh_key.terraform.id
  ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = var.pvt_key != "" ? file(var.pvt_key) : tls_private_key.pk.private_key_pem
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # install nginx
      "sudo apt update",
      "sudo apt install -y nginx",
      "sudo apt install -y docker",
      "sudo apt install -y docker-compose",
      "sudo apt install -y python3-certbot-nginx",
      # create odoo installation directory
      "mkdir /root/metabase"
    ]
  }

  provisioner "file" {
    content      = templatefile("docker-compose.yml.tpl", {
    })
    destination = "/root/metabase/docker-compose.yml"
  }

  provisioner "file" {
    content      = templatefile("atmosphere-nginx.conf.tpl", {
      server_name = var.domain != "" ? var.domain : "0.0.0.0"
    })
    destination = "/etc/nginx/conf.d/atmosphere-nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # run compose
      "cd /root/metabase",
      "docker-compose up -d",
      "rm /etc/nginx/sites-enabled/default",
      "systemctl restart nginx",
    ]
  }
}