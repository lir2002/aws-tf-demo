resource "aws_placement_group" "web_placement" {
  name     = "web_placement"
  strategy = "spread"
}
resource "aws_autoscaling_group" "web_asg" {
  min_size             = 2
  max_size             = 6
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_az2.id]
  launch_configuration = aws_launch_configuration.web-server-conf.name
  placement_group      = aws_placement_group.web_placement.id

  target_group_arns    = [aws_lb_target_group.web_tg.arn]

  tag {
    key                 = "Name"
    value               = "web-server-instance"
    propagate_at_launch = true
  }
}


resource "aws_launch_configuration" "web-server-conf" {
  name_prefix     = "web-server-"
  image_id        = data.aws_ami.ubuntu2204.id
  instance_type   = "t2.micro"
  security_groups =  [aws_security_group.tg_sg.id]
  enable_monitoring = false

  user_data = <<-EOF
              #cloud-config
              package_update: true
              package_upgrade: true
              packages:
                - nginx
                - curl
                - mysql-client-core-8.0
                - php
                - php-mysql
                - php-fpm
              runcmd:
                - |+
                  cat > /var/www/html/index.php <<-'EOF2'
                  <?php
                  // Database connection settings
                  $host = '${aws_db_instance.mysql.address}';
                  $dbname = '${aws_db_instance.mysql.db_name}';
                  $username = '${aws_db_instance.mysql.username}';
                  $password = '${aws_db_instance.mysql.password}';
                  try {
                      // Get the AWS instance ID from the metadata URL
                      $instance_id = file_get_contents('http://169.254.169.254/latest/meta-data/instance-id');
                      echo "<h1>Instance ID: $instance_id</h1>";
                      // Connect to the MySQL database
                      $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
                      $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
                      // Get the user's IP address
                      $user_ip = $_SERVER['REMOTE_ADDR'];
                      // Prepare and execute the insert statement
                      $stmt = $pdo->prepare("INSERT INTO user_ips (ip_from) VALUES (:ip_from)");
                      $stmt->bindParam(':ip_from', $user_ip);
                      $stmt->execute();
                      // Get the ID of the inserted row
                      $last_id = $pdo->lastInsertId();
                      // Query to get the total count of records in the table
                      $countStmt = $pdo->query("SELECT COUNT(*) FROM user_ips");
                      $record_count = $countStmt->fetchColumn();
                      // Return the last inserted ID and the total record count
                      echo "New record ID:" . $last_id . "<br>";
                      echo "Total number of records:" . $record_count;
                  } catch (PDOException $e) {
                      // Handle any errors that may occur
                      echo "Error:" . $e->getMessage();
                  }
                  ?>
                  EOF2
                - echo "Instance ID $(curl http://169.254.169.254/latest/meta-data/instance-id)" > /var/www/html/index.html
                - echo "<html><body><h1>404 Not Found</h1> <p><nav><a href=\"/\">Home</a></nav></body></html>" > /var/www/html/cust_404.html
                - sed -i '/^server/a \
                          error_page 404 /cust_404.html;\
                          location ~ \.php$ {\
                            include snippets/fastcgi-php.conf;\
                            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;\
                          }\
                          location = /cust_404.html {\
                            internal;\
                          } ' /etc/nginx/sites-available/default
                - sed -i '/^[[:blank:]]*index / s/\(index.html\)/index.php \1/' /etc/nginx/sites-available/default
                - systemctl restart nginx
                - mysql -h ${aws_db_instance.mysql.address} -u ${aws_db_instance.mysql.username} -p'${aws_db_instance.mysql.password}' -e "USE wanted; CREATE TABLE IF NOT EXISTS user_ips(id INT PRIMARY KEY AUTO_INCREMENT, ip_from VARCHAR(45),created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
              users:
                - name: ubuntu
                  shell: /bin/bash
                  sudo: ALL=(ALL) NOPASSWD:ALL
                  groups: sudo
                  ssh_authorized_keys:
                    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDcyh5O164/ZNszt+Ic2zQEVKDrW9QF95rwjI3N+ck4wZR3TqqYt0G9g1qVsZyai5MMcP/ZzNcqkDPGuZBonu/KgaPWhtrdT+UQqs+QO2wbcMrjXhuZfXCbMDhUTX/LeoSQBv5Y0PTyXeqC1WwxElIqO1EwLYsGjg+WSJKqQCGpWtHUs2FIgEWIUzvrpSHcHQ3+CtHcXbRCfHNxnNB7Q8R43PiRRHzBQL48o57PWzUxqPjQ60xcCtSFqkRPDuqz8VP5tdGOYP7o/vIrd5vCg7L9xsPYitgwyXyc/LIyKPOPuMjUaT4VCsUoAmBNF1k4gj+5waNQYX7snUukSC8okLPDA0yx5UEpYNWWMRpHOx4SyHGA/YukLAFWoG/I9XdjvesCnamvhMVuoUpuCNc4Eu/Tip/oWDdhr0Vb8OI+dEbXY/EuKhm5HoYAT/hd/oALEYo5IPt5wGEsW4R4gpksoEJIS57nyzM8Jx0s+CkIv6ktGtiFtKq5WCzq0zEXfkeozCM= lir@YoucThinkPad
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "ubuntu2204" {
 most_recent = true
 owners      = ["aws-marketplace"]

  filter {
    name    = "name"
    values = ["*ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

}